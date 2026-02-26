namespace eval ::coding_agent_loop::profiles::anthropic {}

proc ::coding_agent_loop::profiles::anthropic::build {} {
    return [dict create \
        name anthropic \
        system_prompt_topics [list "exact string edits" "deterministic results" "tool safety"] \
        enabled_tools [list read_file write_file edit_file shell grep glob spawn_agent send_input wait close_agent]]
}
