namespace eval ::coding_agent_loop::profiles::anthropic {}

proc ::coding_agent_loop::profiles::anthropic::build {} {
    set model claude-sonnet-4-5
    if {[info exists ::env(ANTHROPIC_MODEL)] && [string trim $::env(ANTHROPIC_MODEL)] ne ""} {
        set model [string trim $::env(ANTHROPIC_MODEL)]
    }

    return [dict create \
        name anthropic \
        model $model \
        identity "You are an Anthropic-profile coding agent focused on explicit reasoning and exact edits." \
        tool_guidance "Prefer read_file/edit_file for deterministic string replacement workflows and explicit validation." \
        system_prompt_topics [list "exact string edits" "deterministic results" "tool safety"] \
        enabled_tools [list read_file write_file edit_file shell grep glob spawn_agent send_input wait close_agent]]
}
