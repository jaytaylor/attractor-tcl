namespace eval ::coding_agent_loop::prompts {
    variable package_dir [file dirname [info script]]
    variable codex_prompts_loaded 0
    variable codex_prompts {}
    variable claude_constants_loaded 0
    variable claude_constants {}
}

proc ::coding_agent_loop::prompts::__resource_dir {} {
    variable package_dir
    return [file join $package_dir resources]
}

proc ::coding_agent_loop::prompts::__read_file {path} {
    if {![file exists $path]} {
        return ""
    }
    set fh [open $path r]
    set data [read $fh]
    close $fh
    return $data
}

proc ::coding_agent_loop::prompts::__join_sections {sections} {
    set filtered {}
    foreach section $sections {
        if {[string trim $section] ne ""} {
            lappend filtered $section
        }
    }
    return [join $filtered "\n\n"]
}

proc ::coding_agent_loop::prompts::__effective_model {state} {
    set model ""
    if {[dict exists $state profile model]} {
        set model [string trim [dict get $state profile model]]
    }
    if {[dict exists $state config model] && [string trim [dict get $state config model]] ne ""} {
        set model [string trim [dict get $state config model]]
    }
    return $model
}

proc ::coding_agent_loop::prompts::__platform_name {} {
    switch -- $::tcl_platform(platform) {
        unix {
            if {[string match -nocase *darwin* $::tcl_platform(os)]} {
                return darwin
            }
            return linux
        }
        windows {
            return windows
        }
        default {
            return unknown
        }
    }
}

proc ::coding_agent_loop::prompts::__git_context {} {
    set out [dict create is_repo 0 branch "" has_uncommitted_changes 0 recent_commits ""]

    if {[catch {exec git rev-parse --is-inside-work-tree} isRepo] != 0 || [string trim $isRepo] ne "true"} {
        return $out
    }

    dict set out is_repo 1

    if {[catch {exec git rev-parse --abbrev-ref HEAD} branch] == 0} {
        dict set out branch [string trim $branch]
    }

    if {[catch {exec git status --porcelain} statusOut] == 0} {
        dict set out has_uncommitted_changes [expr {[string trim $statusOut] ne ""}]
    }

    if {[catch {exec git log -n 3 --oneline} commits] == 0} {
        dict set out recent_commits [string trim $commits]
    }

    return $out
}

proc ::coding_agent_loop::prompts::__project_doc_candidates {profileName} {
    switch -- $profileName {
        openai {
            return [list AGENTS.md README.md]
        }
        anthropic {
            return [list CLAUDE.md AGENTS.md README.md]
        }
        gemini {
            return [list GEMINI.md AGENTS.md README.md]
        }
        default {
            return [list AGENTS.md CLAUDE.md GEMINI.md README.md]
        }
    }
}

proc ::coding_agent_loop::prompts::__collect_project_docs {profileName} {
    set sections {}
    foreach path [::coding_agent_loop::prompts::__project_doc_candidates $profileName] {
        if {![file exists $path]} {
            continue
        }
        set content [string trim [::coding_agent_loop::prompts::__read_file $path]]
        if {$content eq ""} {
            continue
        }
        lappend sections "## $path\n$content"
    }
    return [::coding_agent_loop::prompts::__join_sections $sections]
}

proc ::coding_agent_loop::prompts::__user_instructions {state} {
    if {[dict exists $state config user_instructions] && [string trim [dict get $state config user_instructions]] ne ""} {
        return [string trim [dict get $state config user_instructions]]
    }
    return ""
}

proc ::coding_agent_loop::prompts::__load_codex_prompts {} {
    variable codex_prompts_loaded
    variable codex_prompts

    if {$codex_prompts_loaded} {
        return
    }

    set dir [file join [::coding_agent_loop::prompts::__resource_dir] CodexPrompts]
    set codex_prompts [dict create \
        base_prompt [::coding_agent_loop::prompts::__read_file [file join $dir prompt.md]] \
        codex_model_prompt [::coding_agent_loop::prompts::__read_file [file join $dir gpt_5_codex_prompt.md]] \
        gpt52_prompt [::coding_agent_loop::prompts::__read_file [file join $dir gpt_5_2_prompt.md]] \
        gpt51_prompt [::coding_agent_loop::prompts::__read_file [file join $dir gpt_5_1_prompt.md]] \
        gpt51_codex_max_prompt [::coding_agent_loop::prompts::__read_file [file join $dir gpt-5.1-codex-max_prompt.md]] \
        apply_patch_instructions [::coding_agent_loop::prompts::__read_file [file join $dir apply_patch_tool_instructions.md]]]

    dict set codex_prompts full_prompt "[dict get $codex_prompts base_prompt][dict get $codex_prompts apply_patch_instructions]"
    set codex_prompts_loaded 1
}

proc ::coding_agent_loop::prompts::__codex_prompt_for_model {modelId} {
    variable codex_prompts
    ::coding_agent_loop::prompts::__load_codex_prompts

    set id [string tolower [string trim $modelId]]
    if {$id eq ""} {
        return [dict get $codex_prompts full_prompt]
    }

    if {[string first "gpt-5.1-codex-max" $id] >= 0 || [string first "gpt5.1-codex-max" $id] >= 0} {
        return "[dict get $codex_prompts gpt51_codex_max_prompt][dict get $codex_prompts apply_patch_instructions]"
    }

    if {[string first "codex" $id] >= 0} {
        return "[dict get $codex_prompts codex_model_prompt][dict get $codex_prompts apply_patch_instructions]"
    }

    if {[string first "gpt-5.2" $id] >= 0 || [string first "gpt5.2" $id] >= 0} {
        return "[dict get $codex_prompts gpt52_prompt][dict get $codex_prompts apply_patch_instructions]"
    }

    if {[string first "gpt-5.1" $id] >= 0 || [string first "gpt5.1" $id] >= 0} {
        return "[dict get $codex_prompts gpt51_prompt][dict get $codex_prompts apply_patch_instructions]"
    }

    return [dict get $codex_prompts full_prompt]
}

proc ::coding_agent_loop::prompts::__build_openai_prompt {state} {
    set model [::coding_agent_loop::prompts::__effective_model $state]
    set basePrompt [::coding_agent_loop::prompts::__codex_prompt_for_model $model]

    set workingDir [pwd]
    set envContext "\n\n# Environment Context\n\n- Working directory: $workingDir\n- When using shell tools, use \".\" or \"$workingDir\" for the workdir parameter, not \"/workspace\"\n- Platform: $::tcl_platform(os) $::tcl_platform(osVersion)"

    set profileName [dict get $state profile name]
    set projectDocs [::coding_agent_loop::prompts::__collect_project_docs $profileName]
    set userInstructions [::coding_agent_loop::prompts::__user_instructions $state]

    set sections [list "${basePrompt}${envContext}"]
    if {[string trim $projectDocs] ne ""} {
        lappend sections "# Project Documentation\n$projectDocs"
    }
    if {[string trim $userInstructions] ne ""} {
        lappend sections "# User Instructions\n$userInstructions"
    }

    return [::coding_agent_loop::prompts::__join_sections $sections]
}

proc ::coding_agent_loop::prompts::__regex_escape {text} {
    set escaped $text
    regsub -all {([][(){}.^$*+?|\\])} $escaped {\\\1} escaped
    return $escaped
}

proc ::coding_agent_loop::prompts::__dedent {text} {
    set lines [split $text "\n"]
    set minIndent -1
    foreach line $lines {
        if {[string trim $line] eq ""} {
            continue
        }
        regexp {^([ \t]*)} $line -> indent
        set width [string length $indent]
        if {$minIndent < 0 || $width < $minIndent} {
            set minIndent $width
        }
    }
    if {$minIndent < 0} {
        return [string trimright $text "\n"]
    }
    set out {}
    foreach line $lines {
        if {[string trim $line] eq ""} {
            lappend out ""
            continue
        }
        lappend out [string range $line $minIndent end]
    }
    return [string trimright [join $out "\n"] "\n"]
}

proc ::coding_agent_loop::prompts::__swift_extract_constant {source name} {
    set markers [list "public static let $name = \"\"\"\n" "private static let $name = \"\"\"\n"]
    set start -1
    set markerLen 0
    foreach marker $markers {
        set idx [string first $marker $source]
        if {$idx >= 0} {
            set start [expr {$idx + [string length $marker]}]
            set markerLen [string length $marker]
            break
        }
    }
    if {$start < 0 || $markerLen == 0} {
        return ""
    }

    set end [string first "\n    \"\"\"" $source $start]
    if {$end < 0} {
        return ""
    }

    set body [string range $source $start [expr {$end - 1}]]
    return [::coding_agent_loop::prompts::__dedent $body]
}

proc ::coding_agent_loop::prompts::__swift_extract_claude_preamble {source} {
    set pattern {(?s)sections\.append\("""\n(.*?)\n\s*"""\)}
    if {![regexp -- $pattern $source -> body]} {
        return ""
    }
    return [::coding_agent_loop::prompts::__dedent $body]
}

proc ::coding_agent_loop::prompts::__claude_constants {} {
    variable claude_constants_loaded
    variable claude_constants

    if {$claude_constants_loaded} {
        return $claude_constants
    }

    set sourcePath [file join [::coding_agent_loop::prompts::__resource_dir] OmniKitPromptSources ClaudeSystemPrompt.swift]
    set source [::coding_agent_loop::prompts::__read_file $sourcePath]

    set names [list \
        toolDescriptionTask \
        toolDescriptionBash \
        toolDescriptionGlob \
        toolDescriptionGrep \
        toolDescriptionRead \
        toolDescriptionEdit \
        toolDescriptionWrite \
        toolDescriptionNotebookEdit \
        toolDescriptionWebFetch \
        toolDescriptionWebSearch \
        toolDescriptionTodoWrite \
        toolDescriptionAskUserQuestion \
        toolDescriptionExitPlanMode \
        toolDescriptionEnterPlanMode \
        toolDescriptionTaskStop \
        toolDescriptionTaskOutput \
        toolDescriptionSkill \
        toolDescriptionSendMessage \
        toolDescriptionTaskCreate \
        toolDescriptionTaskGet \
        toolDescriptionTaskList \
        toolDescriptionTaskUpdate \
        toolDescriptionTeamCreate \
        toolDescriptionTeamDelete \
        toolDescriptionToolSearch \
        basePrompt \
        taskManagementSection \
        askingQuestionsSection \
        doingTasksSection \
        toolUsagePolicy \
        gitCommitSection \
        prSection]

    set constants [dict create]
    dict set constants buildToolDescriptionsPreamble [::coding_agent_loop::prompts::__swift_extract_claude_preamble $source]

    foreach name $names {
        dict set constants $name [::coding_agent_loop::prompts::__swift_extract_constant $source $name]
    }

    set claude_constants $constants
    set claude_constants_loaded 1
    return $claude_constants
}

proc ::coding_agent_loop::prompts::__claude_map_local_tools {toolNames} {
    set mapping [dict create \
        read_file Read \
        write_file Write \
        edit_file Edit \
        shell Bash \
        grep Grep \
        glob Glob \
        spawn_agent Task \
        send_input SendMessage \
        wait TaskOutput \
        close_agent TaskStop]

    set mapped {}
    foreach name $toolNames {
        if {[dict exists $mapping $name]} {
            set mappedName [dict get $mapping $name]
            if {[lsearch -exact $mapped $mappedName] < 0} {
                lappend mapped $mappedName
            }
        }
    }
    return $mapped
}

proc ::coding_agent_loop::prompts::__claude_tool_descriptions {allowedTools} {
    set constants [::coding_agent_loop::prompts::__claude_constants]
    set sections [list [dict get $constants buildToolDescriptionsPreamble]]

    set toolToConstant [list \
        Task toolDescriptionTask \
        Bash toolDescriptionBash \
        Glob toolDescriptionGlob \
        Grep toolDescriptionGrep \
        Read toolDescriptionRead \
        Edit toolDescriptionEdit \
        Write toolDescriptionWrite \
        NotebookEdit toolDescriptionNotebookEdit \
        WebFetch toolDescriptionWebFetch \
        WebSearch toolDescriptionWebSearch \
        TodoWrite toolDescriptionTodoWrite \
        AskUserQuestion toolDescriptionAskUserQuestion \
        ExitPlanMode toolDescriptionExitPlanMode \
        EnterPlanMode toolDescriptionEnterPlanMode \
        TaskStop toolDescriptionTaskStop \
        TaskOutput toolDescriptionTaskOutput \
        Skill toolDescriptionSkill \
        SendMessage toolDescriptionSendMessage \
        TaskCreate toolDescriptionTaskCreate \
        TaskGet toolDescriptionTaskGet \
        TaskList toolDescriptionTaskList \
        TaskUpdate toolDescriptionTaskUpdate \
        TeamCreate toolDescriptionTeamCreate \
        TeamDelete toolDescriptionTeamDelete \
        ToolSearch toolDescriptionToolSearch]

    foreach {toolName constantName} $toolToConstant {
        set include [expr {[lsearch -exact $allowedTools $toolName] >= 0}]
        if {!$include && $toolName eq "TaskStop"} {
            set include [expr {[lsearch -exact $allowedTools KillShell] >= 0}]
        }
        if {$include} {
            lappend sections [dict get $constants $constantName]
        }
    }

    return [::coding_agent_loop::prompts::__join_sections $sections]
}

proc ::coding_agent_loop::prompts::__claude_model_display_name {modelId} {
    set id [string tolower $modelId]
    if {[string first opus $id] >= 0} {
        return "Claude Opus 4.6"
    }
    if {[string first sonnet-4-6 $id] >= 0} {
        return "Claude Sonnet 4.6"
    }
    if {[string first sonnet $id] >= 0} {
        return "Claude Sonnet 4.5"
    }
    if {[string first haiku $id] >= 0} {
        return "Claude Haiku 4.5"
    }
    return "Claude"
}

proc ::coding_agent_loop::prompts::__claude_load_skills {} {
    set commandsDir [file join [pwd] .claude commands]
    if {![file exists $commandsDir]} {
        return {}
    }

    set skills {}
    foreach path [glob -nocomplain -directory $commandsDir *.md] {
        set content [::coding_agent_loop::prompts::__read_file $path]
        set name [file rootname [file tail $path]]
        set description "No description"
        set body $content

        if {[string first "---" $content] == 0} {
            set remainder [string range $content 3 end]
            set splitAt [string first "\n---" $remainder]
            if {$splitAt >= 0} {
                set yaml [string range $remainder 0 [expr {$splitAt - 1}]]
                set body [string trim [string range $remainder [expr {$splitAt + 4}] end] "\n"]
                foreach line [split $yaml "\n"] {
                    set trimmed [string trim $line]
                    if {[string first "description:" $trimmed] == 0} {
                        set description [string trim [string range $trimmed [string length "description:"] end]]
                        break
                    }
                }
            }
        }

        lappend skills [dict create name $name description $description content [string trim $body]]
    }

    return $skills
}

proc ::coding_agent_loop::prompts::__claude_skills_section {skills} {
    if {[llength $skills] == 0} {
        return ""
    }

    set sorted [lsort -dictionary -command {apply {{a b} {string compare [dict get $a name] [dict get $b name]}}} $skills]
    set lines [list \
        "# Available Skills" \
        "" \
        "The following skills are available in this project. Use the Skill tool to invoke them:" \
        ""]

    foreach skill $sorted {
        lappend lines "- /[dict get $skill name]: [dict get $skill description]"
    }

    lappend lines ""
    lappend lines "To invoke a skill, use: Skill(skill: \"<skill-name>\")"
    return [join $lines "\n"]
}

proc ::coding_agent_loop::prompts::__claude_environment_section {gitContext modelName modelId} {
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    set osVersion "$::tcl_platform(os) $::tcl_platform(osVersion)"
    set isGitRepo [expr {[dict get $gitContext is_repo] ? "Yes" : "No"}]
    set platform [::coding_agent_loop::prompts::__platform_name]
    set workingDir [pwd]

    return "Here is useful information about the environment you are running in:\n<env>\nWorking directory: $workingDir\nIs directory a git repo: $isGitRepo\nPlatform: $platform\nOS Version: $osVersion\nToday's date: $today\n</env>\nYou are powered by the model named $modelName. The exact model ID is $modelId.\n\nAssistant knowledge cutoff is May 2025."
}

proc ::coding_agent_loop::prompts::__claude_git_section {gitContext} {
    set parts [list "gitStatus: This is the git status at the start of the conversation. Note that this status is a snapshot in time, and will not update during the conversation."]

    if {[string trim [dict get $gitContext branch]] ne ""} {
        lappend parts "Current branch: [dict get $gitContext branch]"
    }

    lappend parts "Main branch (you will usually use this for PRs): main"

    if {[dict get $gitContext has_uncommitted_changes]} {
        lappend parts "Status: Has uncommitted changes"
    }

    if {[string trim [dict get $gitContext recent_commits]] ne ""} {
        lappend parts "Recent commits:\n[dict get $gitContext recent_commits]"
    }

    return [join $parts "\n"]
}

proc ::coding_agent_loop::prompts::__build_anthropic_prompt {state} {
    set constants [::coding_agent_loop::prompts::__claude_constants]
    set model [::coding_agent_loop::prompts::__effective_model $state]
    set modelDisplayName [::coding_agent_loop::prompts::__claude_model_display_name $model]

    set allowedTools [::coding_agent_loop::prompts::__claude_map_local_tools [dict keys [dict get $state tools]]]
    set toolDescriptions [::coding_agent_loop::prompts::__claude_tool_descriptions $allowedTools]
    set todosEnabled [expr {[lsearch -exact $allowedTools TodoWrite] >= 0}]

    set skills [::coding_agent_loop::prompts::__claude_load_skills]
    set skillsSection [::coding_agent_loop::prompts::__claude_skills_section $skills]

    set gitContext [::coding_agent_loop::prompts::__git_context]
    set envSection [::coding_agent_loop::prompts::__claude_environment_section $gitContext $modelDisplayName $model]
    set gitSection ""
    if {[dict get $gitContext is_repo]} {
        set gitSection [::coding_agent_loop::prompts::__claude_git_section $gitContext]
    }

    set sections [list $toolDescriptions [dict get $constants basePrompt]]
    if {$todosEnabled} {
        lappend sections [dict get $constants taskManagementSection]
    }
    lappend sections \
        [dict get $constants askingQuestionsSection] \
        [dict get $constants doingTasksSection] \
        [dict get $constants toolUsagePolicy] \
        $skillsSection \
        [dict get $constants gitCommitSection] \
        [dict get $constants prSection] \
        $envSection \
        $gitSection

    set profileName [dict get $state profile name]
    set projectDocs [::coding_agent_loop::prompts::__collect_project_docs $profileName]
    set userInstructions [::coding_agent_loop::prompts::__user_instructions $state]

    if {[string trim $projectDocs] ne ""} {
        lappend sections "# Project Documentation\n$projectDocs"
    }
    if {[string trim $userInstructions] ne ""} {
        lappend sections "# User Instructions\n$userInstructions"
    }

    return [::coding_agent_loop::prompts::__join_sections $sections]
}

proc ::coding_agent_loop::prompts::__gemini_preamble {interactive} {
    if {$interactive} {
        return "You are Gemini CLI, an interactive CLI agent specializing in software engineering tasks. Your primary goal is to help users safely and effectively."
    }
    return "You are Gemini CLI, an autonomous CLI agent specializing in software engineering tasks. Your primary goal is to help users safely and effectively."
}

proc ::coding_agent_loop::prompts::__gemini_core_mandates {interactive} {
    if {$interactive} {
        set confirmLine {- **Confirm Ambiguity/Expansion:** Do not take significant actions beyond the clear scope of the request without confirming with the user. If the user implies a change (e.g., reports a bug) without explicitly asking for a fix, ask for confirmation first. If asked how to do something, explain first, don't just do it.}
    } else {
        set confirmLine {- **Handle Ambiguity/Expansion:** Do not take significant actions beyond the clear scope of the request.}
    }

    return "# Core Mandates\n\n## Security & System Integrity\n- **Credential Protection:** Never log, print, or commit secrets, API keys, or sensitive credentials. Rigorously protect `.env` files, `.git`, and system configuration folders.\n- **Source Control:** Do not stage or commit changes unless specifically requested by the user.\n\n## Engineering Standards\n- **Contextual Precedence:** Instructions found in `GEMINI.md` files are foundational mandates. They take absolute precedence over the general workflows and tool defaults described in this system prompt.\n- **Conventions & Style:** Rigorously adhere to existing workspace conventions, architectural patterns, and style (naming, formatting, typing, commenting). Analyze surrounding files, tests, and configuration to ensure your changes are seamless and idiomatic.\n- **Libraries/Frameworks:** NEVER assume a library/framework is available. Verify established usage within the project before employing it.\n- **Technical Integrity:** You are responsible for the entire lifecycle: implementation, testing, and validation. For bug fixes, reproduce the failure before applying a fix whenever feasible.\n- **Testing:** ALWAYS search for and update related tests after making a code change. Add a new test case to an existing test file (or create one) to verify changes.\n$confirmLine\n- **Explaining Changes:** After completing a code modification or file operation do not provide summaries unless asked.\n- **Do Not revert changes:** Do not revert changes to the codebase unless asked by the user.\n- **Explain Before Acting:** Never call tools in silence. Provide a concise, one-sentence explanation immediately before executing tool calls (except repetitive low-level discovery loops where narration would be noisy)."
}

proc ::coding_agent_loop::prompts::__gemini_primary_workflows {interactive hasTodos hasPlanTools} {
    set planModeText ""
    if {$hasPlanTools} {
        set planModeText {- For substantial, multi-file or architecturally ambiguous changes, use `enter_plan_mode` to establish and align a plan before implementing.}
    }

    set todosText ""
    if {$hasTodos} {
        set todosText {- Use `write_todos` for complex multi-step work to keep progress visible and current.}
    }

    if {$interactive} {
        set standardsLine {- After code changes, run project-specific build/lint/type-check commands. If unsure which commands apply, ask the user before running broad checks.}
    } else {
        set standardsLine {- After code changes, run project-specific build/lint/type-check commands.}
    }

    return "# Primary Workflows\n\n## Development Lifecycle\nOperate using a **Research -> Strategy -> Execution** lifecycle.\n\n1. **Research:** Map the codebase and validate assumptions using `grep_search`, `glob`, `list_directory`, and `read_file`.\n2. **Strategy:** Formulate a grounded plan based on research and state it concisely.\n3. **Execution:** Apply targeted, surgical changes with `replace`, `write_file`, and `run_shell_command` as needed.\n4. **Validate:** Run tests and check for regressions.\n$standardsLine\n$planModeText\n$todosText\n\n## New Applications\n\n- Deliver a visually appealing, substantially complete, and functional prototype.\n- Implement iteratively, verify behavior and styling, then provide clear run instructions."
}

proc ::coding_agent_loop::prompts::__gemini_operational_guidelines {interactive} {
    if {$interactive} {
        set interactiveShellLine {- **Interactive Commands:** Prefer non-interactive flags and one-shot modes to avoid hanging sessions.}
    } else {
        set interactiveShellLine {- **Interactive Commands:** Execute only non-interactive commands.}
    }

    return "# Operational Guidelines\n\n## Tone and Style\n- **Role:** A senior software engineer and collaborative peer programmer.\n- **Concise & Direct:** Use a professional, direct, concise CLI style.\n- **No Chitchat:** Avoid filler and unnecessary preambles/postambles.\n- **Formatting:** Use GitHub-flavored Markdown.\n\n## Security and Safety Rules\n- **Explain Critical Commands:** Before running filesystem/system-modifying commands with `run_shell_command`, briefly explain purpose and impact.\n- **Security First:** Never introduce code that exposes or logs secrets.\n\n## Tool Usage\n- **Parallelism:** Execute independent tool calls in parallel when feasible.\n- **Command Execution:** Use `run_shell_command` for command execution.\n- **Background Processes:** For long-running commands, use `is_background=true`.\n$interactiveShellLine\n- **Memory Tool:** Use `save_memory` only for global user preferences/facts, never workspace-local context.\n- **Confirmation Protocol:** If a tool call is cancelled/declined, do not immediately retry it unless user explicitly asks.\n\n## Interaction Details\n- The user can use `/help` for help and `/bug` for feedback."
}

proc ::coding_agent_loop::prompts::__gemini_sandbox_section {sandbox} {
    switch -- $sandbox {
        macos_seatbelt {
            return "# macOS Seatbelt\nYou are running under macOS seatbelt with limited access outside the project directory and temp directory. If a command fails with permission errors, explain that sandboxing may be the cause and how the user may need to adjust their sandbox profile."
        }
        generic {
            return "# Sandbox\nYou are running in a sandbox container with limited access outside the project directory and temp directory. If a command fails with permission errors, explain that sandboxing may be the cause and how the user may need to adjust their sandbox configuration."
        }
        outside {
            return "# Outside of Sandbox\nYou are running directly on the user's system. For critical commands likely to modify system state outside the project, remind the user to consider enabling sandboxing."
        }
        default {
            return ""
        }
    }
}

proc ::coding_agent_loop::prompts::__gemini_git_section {interactive} {
    if {$interactive} {
        set confirmLine {- Keep the user informed and ask for clarification where needed.}
    } else {
        set confirmLine ""
    }

    return "# Git Repository\n- The working directory is managed by git.\n- NEVER stage or commit changes unless explicitly instructed by the user.\n- When asked to commit, start with: `git status && git diff HEAD && git log -n 3`.\n- Propose a draft commit message focused on why.\n$confirmLine\n- Confirm commit success with `git status`.\n- Never push to remote unless explicitly requested."
}

proc ::coding_agent_loop::prompts::__gemini_final_reminder {} {
    return "# Final Reminder\nBalance conciseness with clarity and safety. Always prioritize user control and project conventions. Never assume file contents; use `read_file` to verify. Continue until the user's query is fully resolved."
}

proc ::coding_agent_loop::prompts::__build_gemini_prompt {state} {
    set interactiveMode 1
    set hasTodos 0
    set hasPlanTools 0

    set gitContext [::coding_agent_loop::prompts::__git_context]
    set isGitRepo [dict get $gitContext is_repo]
    set sandbox outside

    set sections [list \
        [::coding_agent_loop::prompts::__gemini_preamble $interactiveMode] \
        [::coding_agent_loop::prompts::__gemini_core_mandates $interactiveMode] \
        [::coding_agent_loop::prompts::__gemini_primary_workflows $interactiveMode $hasTodos $hasPlanTools] \
        [::coding_agent_loop::prompts::__gemini_operational_guidelines $interactiveMode] \
        [::coding_agent_loop::prompts::__gemini_sandbox_section $sandbox]]

    if {$isGitRepo} {
        lappend sections [::coding_agent_loop::prompts::__gemini_git_section $interactiveMode]
    }

    lappend sections [::coding_agent_loop::prompts::__gemini_final_reminder]

    set model [::coding_agent_loop::prompts::__effective_model $state]
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    lappend sections "<env>\nWorking directory: [pwd]\nPlatform: [::coding_agent_loop::prompts::__platform_name]\nOS Version: $::tcl_platform(os) $::tcl_platform(osVersion)\nToday's date: $today\nModel: $model\n</env>"

    set profileName [dict get $state profile name]
    set projectDocs [::coding_agent_loop::prompts::__collect_project_docs $profileName]
    set userInstructions [::coding_agent_loop::prompts::__user_instructions $state]

    if {[string trim $projectDocs] ne ""} {
        lappend sections "# Project Documentation\n$projectDocs"
    }
    if {[string trim $userInstructions] ne ""} {
        lappend sections "# User Instructions\n$userInstructions"
    }

    return [::coding_agent_loop::prompts::__join_sections $sections]
}

proc ::coding_agent_loop::prompts::build {state} {
    if {[dict exists $state config system_prompt] && [string trim [dict get $state config system_prompt]] ne ""} {
        return [dict get $state config system_prompt]
    }

    set profileName [dict get $state profile name]
    switch -- $profileName {
        openai {
            return [::coding_agent_loop::prompts::__build_openai_prompt $state]
        }
        anthropic {
            return [::coding_agent_loop::prompts::__build_anthropic_prompt $state]
        }
        gemini {
            return [::coding_agent_loop::prompts::__build_gemini_prompt $state]
        }
        default {
            return "You are a coding agent.\n\nUse tools carefully and deterministically."
        }
    }
}
