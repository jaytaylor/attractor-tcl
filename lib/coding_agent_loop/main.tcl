namespace eval ::coding_agent_loop {
    variable version 0.1.0
    variable session_seq 0
    variable sessions {}
}

package require Tcl 8.5-
package require unified_llm
package require attractor_core

source [file join [file dirname [info script]] tools core.tcl]
source [file join [file dirname [info script]] prompts.tcl]
source [file join [file dirname [info script]] profiles openai.tcl]
source [file join [file dirname [info script]] profiles anthropic.tcl]
source [file join [file dirname [info script]] profiles gemini.tcl]

proc ::coding_agent_loop::default_env {} {
    set allowed {}
    foreach {k v} [array get ::env] {
        if {[regexp {(_API_KEY|_SECRET|_TOKEN|_PASSWORD|_CREDENTIAL)$} $k]} {
            continue
        }
        dict set allowed $k $v
    }
    return $allowed
}

proc ::coding_agent_loop::resolve_profile {profile} {
    switch -- $profile {
        openai {
            return [::coding_agent_loop::profiles::openai::build]
        }
        anthropic {
            return [::coding_agent_loop::profiles::anthropic::build]
        }
        gemini {
            return [::coding_agent_loop::profiles::gemini::build]
        }
        default {
            return -code error "unknown profile: $profile"
        }
    }
}

proc ::coding_agent_loop::__collect_project_docs {} {
    set docs {}
    foreach path {AGENTS.md CLAUDE.md README.md} {
        if {[file exists $path]} {
            lappend docs $path
        }
    }
    return $docs
}

proc ::coding_agent_loop::__build_system_prompt {state} {
    return [::coding_agent_loop::prompts::build $state]
}

proc ::coding_agent_loop::session {subcommand args} {
    switch -- $subcommand {
        new {
            return [::coding_agent_loop::session_new {*}$args]
        }
        default {
            return -code error "unknown session subcommand: $subcommand"
        }
    }
}

proc ::coding_agent_loop::session_new {args} {
    variable session_seq
    variable sessions

    array set opts {
        -profile openai
        -env ::coding_agent_loop::default_env
        -execution_env ""
        -config {}
    }
    array set opts $args

    set profile [::coding_agent_loop::resolve_profile $opts(-profile)]

    set defaultCharLimit 6000
    set defaultLineLimit 200
    set shellMaxMs 60000
    set subagentDepth 0
    set maxSubagentDepth 2

    if {[dict exists $opts(-config) default_tool_char_limit]} {
        set defaultCharLimit [dict get $opts(-config) default_tool_char_limit]
    }
    if {[dict exists $opts(-config) default_tool_line_limit]} {
        set defaultLineLimit [dict get $opts(-config) default_tool_line_limit]
    }
    if {[dict exists $opts(-config) shell_max_ms]} {
        set shellMaxMs [dict get $opts(-config) shell_max_ms]
    }
    if {[dict exists $opts(-config) subagent_depth]} {
        set subagentDepth [dict get $opts(-config) subagent_depth]
    }
    if {[dict exists $opts(-config) max_subagent_depth]} {
        set maxSubagentDepth [dict get $opts(-config) max_subagent_depth]
    }

    set executionEnv $opts(-execution_env)
    if {$executionEnv eq ""} {
        set executionEnv [::coding_agent_loop::tools::execution_environment_new -type local -shell_max_ms $shellMaxMs]
    }

    set registry [::coding_agent_loop::tools::default_registry \
        -execution_env $executionEnv \
        -char_limit $defaultCharLimit \
        -line_limit $defaultLineLimit \
        -shell_max_ms $shellMaxMs]

    set allowedTools {}
    foreach name [dict get $profile enabled_tools] {
        if {[dict exists $registry $name]} {
            dict set allowedTools $name [dict get $registry $name]
        }
    }

    incr session_seq
    set id $session_seq
    set cmd ::coding_agent_loop::session::$id

    set state [dict create \
        id $id \
        profile $profile \
        env_cmd $opts(-env) \
        execution_env $executionEnv \
        config $opts(-config) \
        history {} \
        events {} \
        subscribers {} \
        turns 0 \
        max_turns 64 \
        max_tool_rounds_per_input 8 \
        tools $allowedTools \
        steering_queue {} \
        current_tool_signature {} \
        recent_tool_signatures {} \
        aborted 0 \
        subagent_depth $subagentDepth \
        max_subagent_depth $maxSubagentDepth \
        closed 0]

    if {[dict exists $opts(-config) max_turns]} {
        dict set state max_turns [dict get $opts(-config) max_turns]
    }
    if {[dict exists $opts(-config) max_tool_rounds_per_input]} {
        dict set state max_tool_rounds_per_input [dict get $opts(-config) max_tool_rounds_per_input]
    }

    dict set sessions $id $state
    interp alias {} $cmd {} ::coding_agent_loop::__session_dispatch $id
    return $cmd
}

proc ::coding_agent_loop::__session_dispatch {id method args} {
    variable sessions
    if {![dict exists $sessions $id]} {
        return -code error "unknown session id: $id"
    }

    switch -- $method {
        submit {
            if {[llength $args] < 1} {
                return -code error "usage: \$session submit text"
            }
            return [::coding_agent_loop::__session_submit $id [lindex $args 0]]
        }
        steer {
            if {[llength $args] != 1} {
                return -code error "usage: \$session steer text"
            }
            return [::coding_agent_loop::__session_steer $id [lindex $args 0]]
        }
        follow_up {
            if {[llength $args] != 1} {
                return -code error "usage: \$session follow_up text"
            }
            return [::coding_agent_loop::__session_follow_up $id [lindex $args 0]]
        }
        abort {
            return [::coding_agent_loop::__session_abort $id]
        }
        events {
            return [::coding_agent_loop::__session_events $id {*}$args]
        }
        close {
            rename ::coding_agent_loop::session::$id {}
            dict unset sessions $id
            return {}
        }
        config {
            return [dict get $sessions $id]
        }
        default {
            return -code error "unknown session method: $method"
        }
    }
}

proc ::coding_agent_loop::__emit {id event} {
    variable sessions
    set state [dict get $sessions $id]
    set events [dict get $state events]
    lappend events $event
    dict set state events $events
    dict set sessions $id $state

    foreach subscriber [dict get $state subscribers] {
        catch {{*}$subscriber $event}
    }
}

proc ::coding_agent_loop::__session_events {id args} {
    variable sessions

    if {[llength $args] == 0} {
        return [dict get $sessions $id events]
    }

    array set opts {
        -on_event ""
    }
    array set opts $args
    if {$opts(-on_event) eq ""} {
        return -code error "-on_event is required"
    }
    set state [dict get $sessions $id]
    set subscribers [dict get $state subscribers]
    lappend subscribers $opts(-on_event)
    dict set state subscribers $subscribers
    dict set sessions $id $state
    return {}
}

proc ::coding_agent_loop::__tool_wrapper {sessionId toolName rawArgs toolCall} {
    variable sessions
    set tool [dict get $sessions $sessionId tools $toolName]
    set schema [dict get $tool schema]
    set command [dict get $tool command]
    set charLimit [dict get $tool char_limit]
    set lineLimit [dict get $tool line_limit]

    set callId [dict get $toolCall id]

    set augmentedToolCall $toolCall
    dict set augmentedToolCall session_id $sessionId
    dict set augmentedToolCall execution_env_cmd [dict get $sessions $sessionId execution_env]

    ::coding_agent_loop::__emit $sessionId [dict create type TOOL_CALL_START id $callId name $toolName arguments $rawArgs]

    if {[catch {::coding_agent_loop::tools::validate_args $toolName $schema $rawArgs} validArgs]} {
        set fullOutput [dict create type schema_error error $validArgs]
        set trunc [::coding_agent_loop::tools::truncate_output [format %s $fullOutput] $charLimit $lineLimit]
        ::coding_agent_loop::__emit $sessionId [dict create type TOOL_CALL_END id $callId name $toolName output [dict get $trunc display] full_output [dict get $trunc full] is_error 1]
        return [dict create id $callId name $toolName is_error 1 output $fullOutput]
    }

    if {$toolName eq "shell" && ![dict exists $validArgs max_ms] && [dict exists $tool default_shell_max_ms]} {
        dict set validArgs max_ms [dict get $tool default_shell_max_ms]
    }

    dict lappend sessions $sessionId current_tool_signature [dict create name $toolName args $validArgs]

    if {[catch {{*}$command $validArgs $augmentedToolCall} rawOutput]} {
        set fullOutput $rawOutput
        set trunc [::coding_agent_loop::tools::truncate_output [format %s $fullOutput] $charLimit $lineLimit]
        ::coding_agent_loop::__emit $sessionId [dict create type TOOL_CALL_END id $callId name $toolName output [dict get $trunc display] full_output [dict get $trunc full] is_error 1]
        return [dict create id $callId name $toolName is_error 1 output $fullOutput]
    }

    set fullOutput [format %s $rawOutput]
    set trunc [::coding_agent_loop::tools::truncate_output $fullOutput $charLimit $lineLimit]
    ::coding_agent_loop::__emit $sessionId [dict create type TOOL_CALL_END id $callId name $toolName output [dict get $trunc display] full_output [dict get $trunc full] is_error 0]

    return [dict create id $callId name $toolName is_error 0 output $fullOutput]
}

proc ::coding_agent_loop::__session_submit {id text} {
    variable sessions

    set state [dict get $sessions $id]
    if {[dict get $state aborted]} {
        return -code error "session aborted"
    }

    set turns [dict get $state turns]
    set maxTurns [dict get $state max_turns]
    if {$turns >= $maxTurns} {
        ::coding_agent_loop::__emit $id [dict create type TURN_LIMIT turns $turns max_turns $maxTurns]
        return -code error "turn limit reached"
    }

    if {$turns == 0} {
        ::coding_agent_loop::__emit $id [dict create type SESSION_START session_id $id]
    }

    ::coding_agent_loop::__emit $id [dict create type USER_INPUT text $text]

    set state [dict get $sessions $id]
    set steeringQueue [dict get $state steering_queue]
    set userInput $text
    if {[llength $steeringQueue] > 0} {
        set userInput "Steering directives:\n[join $steeringQueue \n]\n\nUser input:\n$text"
        dict set state steering_queue {}
        dict set sessions $id $state
        ::coding_agent_loop::__emit $id [dict create type STEERING_APPLIED directives $steeringQueue]
    }

    set state [dict get $sessions $id]
    set systemPrompt [::coding_agent_loop::__build_system_prompt $state]
    set messages [list \
        [::unified_llm::message system $systemPrompt] \
        [::unified_llm::message user $userInput]]

    set toolDefs {}
    foreach toolName [dict keys [dict get $state tools]] {
        dict set toolDefs $toolName [list ::coding_agent_loop::__tool_wrapper $id $toolName]
    }

    dict set state current_tool_signature {}
    dict set sessions $id $state

    set profileName [dict get [dict get $state profile] name]
    set maxToolRounds [dict get $state max_tool_rounds_per_input]
    set model ""
    if {[dict exists $state profile model]} {
        set model [dict get $state profile model]
    }
    if {[dict exists $state config model] && [string trim [dict get $state config model]] ne ""} {
        set model [string trim [dict get $state config model]]
    }

    ::coding_agent_loop::__emit $id [dict create type MODEL_REQUEST_START provider $profileName]
    set generateArgs [list \
        -messages $messages \
        -provider $profileName \
        -tools $toolDefs \
        -max_tool_rounds $maxToolRounds]
    if {$model ne ""} {
        lappend generateArgs -model $model
    }
    set response [::unified_llm::generate {*}$generateArgs]
    ::coding_agent_loop::__emit $id [dict create type MODEL_REQUEST_END provider $profileName usage [dict get $response usage]]

    set state [dict get $sessions $id]
    set history [dict get $state history]
    lappend history [dict create role user text $text]
    lappend history [dict create role assistant text [dict get $response text]]
    dict set state history $history

    set signature [dict get $state current_tool_signature]
    set loopDetected 0
    if {[llength $signature] > 0} {
        set recent [dict get $state recent_tool_signatures]
        lappend recent $signature
        if {[llength $recent] > 3} {
            set recent [lrange $recent end-2 end]
        }
        dict set state recent_tool_signatures $recent

        if {[llength $recent] == 3 && [lindex $recent 0] eq [lindex $recent 1] && [lindex $recent 1] eq [lindex $recent 2]} {
            set loopDetected 1
        }
    }

    dict set sessions $id $state
    if {$loopDetected} {
        ::coding_agent_loop::__emit $id [dict create type LOOP_DETECTION signature $signature]
        ::coding_agent_loop::__emit $id [dict create type STEERING_INJECTED text "Repeated identical tool pattern detected; choose a different strategy."]
    }

    ::coding_agent_loop::__emit $id [dict create type ASSISTANT_TEXT_END text [dict get $response text]]
    ::coding_agent_loop::__emit $id [dict create type TURN_END status natural_completion turn_index $turns]

    set turns [dict get $sessions $id turns]
    dict set sessions $id turns [expr {$turns + 1}]
    return $response
}

proc ::coding_agent_loop::__session_steer {id text} {
    variable sessions
    dict lappend sessions $id steering_queue $text
    ::coding_agent_loop::__emit $id [dict create type STEERING_INJECTED text $text]
    return [dict create status ok queued 1]
}

proc ::coding_agent_loop::__session_follow_up {id text} {
    return [::coding_agent_loop::__session_submit $id $text]
}

proc ::coding_agent_loop::__session_abort {id} {
    variable sessions
    dict set sessions $id aborted 1
    ::coding_agent_loop::__emit $id [dict create type SESSION_ABORTED session_id $id]
    return [dict create status aborted]
}

package provide coding_agent_loop $::coding_agent_loop::version
