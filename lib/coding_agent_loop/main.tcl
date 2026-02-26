namespace eval ::coding_agent_loop {
    variable version 0.1.0
    variable session_seq 0
    variable sessions {}
}

package require Tcl 8.5
package require unified_llm
package require attractor_core

source [file join [file dirname [info script]] tools core.tcl]
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
        -config {}
    }
    array set opts $args

    set profile [::coding_agent_loop::resolve_profile $opts(-profile)]
    set registry [::coding_agent_loop::tools::default_registry]

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
        config $opts(-config) \
        history {} \
        events {} \
        subscribers {} \
        turns 0 \
        max_turns 64 \
        max_tool_rounds_per_input 8 \
        tools $allowedTools \
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

    ::coding_agent_loop::__emit $sessionId [dict create type TOOL_CALL_START id $callId name $toolName arguments $rawArgs]

    if {[catch {::coding_agent_loop::tools::validate_args $toolName $schema $rawArgs} validArgs]} {
        set fullOutput [dict create error $validArgs]
        set trunc [::coding_agent_loop::tools::truncate_output [format %s $fullOutput] $charLimit $lineLimit]
        ::coding_agent_loop::__emit $sessionId [dict create type TOOL_CALL_END id $callId name $toolName output [dict get $trunc display] full_output [dict get $trunc full] is_error 1]
        return [dict create id $callId name $toolName is_error 1 output $fullOutput]
    }

    if {[catch {{*}$command $validArgs $toolCall} rawOutput]} {
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

    set turns [dict get $sessions $id turns]
    set maxTurns [dict get $sessions $id max_turns]
    if {$turns >= $maxTurns} {
        ::coding_agent_loop::__emit $id [dict create type TURN_LIMIT turns $turns max_turns $maxTurns]
        return -code error "turn limit reached"
    }

    if {$turns == 0} {
        ::coding_agent_loop::__emit $id [dict create type SESSION_START session_id $id]
    }

    set history [dict get $sessions $id history]
    if {[llength $history] >= 2} {
        set a [lindex $history end]
        set b [lindex $history end-1]
        if {[dict get $a text] eq $text && [dict get $b text] eq $text} {
            ::coding_agent_loop::__emit $id [dict create type LOOP_DETECTION input $text]
        }
    }

    ::coding_agent_loop::__emit $id [dict create type USER_INPUT text $text]

    set toolDefs {}
    foreach toolName [dict keys [dict get $sessions $id tools]] {
        dict set toolDefs $toolName [list ::coding_agent_loop::__tool_wrapper $id $toolName]
    }

    set profileName [dict get [dict get $sessions $id profile] name]
    set maxToolRounds [dict get $sessions $id max_tool_rounds_per_input]

    set response [::unified_llm::generate \
        -prompt $text \
        -provider $profileName \
        -tools $toolDefs \
        -max_tool_rounds $maxToolRounds]

    set state [dict get $sessions $id]
    set history [dict get $state history]
    lappend history [dict create role user text $text]
    lappend history [dict create role assistant text [dict get $response text]]
    dict set state history $history
    dict set sessions $id $state

    ::coding_agent_loop::__emit $id [dict create type ASSISTANT_TEXT_END text [dict get $response text]]

    set turns [dict get $sessions $id turns]
    dict set sessions $id turns [expr {$turns + 1}]
    return $response
}

proc ::coding_agent_loop::__session_steer {id text} {
    ::coding_agent_loop::__emit $id [dict create type STEERING_INJECTED text $text]
    return [dict create status ok]
}

proc ::coding_agent_loop::__session_follow_up {id text} {
    return [::coding_agent_loop::__session_submit $id $text]
}

package provide coding_agent_loop $::coding_agent_loop::version
