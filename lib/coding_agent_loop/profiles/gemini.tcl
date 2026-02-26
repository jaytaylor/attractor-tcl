namespace eval ::coding_agent_loop::profiles::gemini {}

proc ::coding_agent_loop::profiles::gemini::build {} {
    return [dict create \
        name gemini \
        system_prompt_topics [list "filesystem operations" "command execution" "tool-first operation"] \
        enabled_tools [list read_file write_file edit_file shell grep glob spawn_agent send_input wait close_agent]]
}
