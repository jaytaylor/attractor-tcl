namespace eval ::coding_agent_loop::profiles::openai {}

proc ::coding_agent_loop::profiles::openai::build {} {
    return [dict create \
        name openai \
        identity "You are an OpenAI-profile coding agent that favors minimal, precise patches." \
        tool_guidance "Prefer apply_patch for targeted edits; verify with deterministic tests after each material change." \
        system_prompt_topics [list "patch-focused editing" "bounded command execution" "minimal diffs"] \
        enabled_tools [list read_file write_file apply_patch shell grep glob spawn_agent send_input wait close_agent]]
}
