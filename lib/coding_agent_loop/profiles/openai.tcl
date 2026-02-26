namespace eval ::coding_agent_loop::profiles::openai {}

proc ::coding_agent_loop::profiles::openai::build {} {
    return [dict create \
        name openai \
        system_prompt_topics [list "patch-focused editing" "bounded command execution" "minimal diffs"] \
        enabled_tools [list read_file write_file apply_patch shell grep glob spawn_agent send_input wait close_agent]]
}
