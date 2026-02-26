namespace eval ::coding_agent_loop::tools {
    variable agents {}
    variable agent_seq 0
}

package require Tcl 8.5
package require attractor_core

proc ::coding_agent_loop::tools::default_tool_schemas {} {
    return [dict create \
        read_file [dict create type object required {path} properties [dict create path [dict create type string]]] \
        write_file [dict create type object required {path content} properties [dict create path [dict create type string] content [dict create type string]]] \
        edit_file [dict create type object required {path old_string new_string} properties [dict create path [dict create type string] old_string [dict create type string] new_string [dict create type string]]] \
        apply_patch [dict create type object required {patch} properties [dict create patch [dict create type string]]] \
        shell [dict create type object required {command} properties [dict create command [dict create type string]]] \
        grep [dict create type object required {pattern} properties [dict create pattern [dict create type string] path [dict create type string]]] \
        glob [dict create type object required {pattern} properties [dict create pattern [dict create type string] root [dict create type string]]] \
        spawn_agent [dict create type object required {profile} properties [dict create profile [dict create type string]]] \
        send_input [dict create type object required {agent_id input} properties [dict create agent_id [dict create type string] input [dict create type string]]] \
        wait [dict create type object required {agent_id} properties [dict create agent_id [dict create type string]]] \
        close_agent [dict create type object required {agent_id} properties [dict create agent_id [dict create type string]]]]
}

proc ::coding_agent_loop::tools::truncate_output {fullText charLimit lineLimit} {
    set display $fullText
    set removedChars 0
    set removedLines 0

    if {$charLimit > 0 && [string length $display] > $charLimit} {
        set removedChars [expr {[string length $display] - $charLimit}]
        set display [string range $display 0 [expr {$charLimit - 1}]]
        append display "\n\[TRUNCATED_CHARS removed=$removedChars\]"
    }

    if {$lineLimit > 0} {
        set lines [split $display "\n"]
        if {[llength $lines] > $lineLimit} {
            set removedLines [expr {[llength $lines] - $lineLimit}]
            set kept [lrange $lines 0 [expr {$lineLimit - 1}]]
            set display "[join $kept \n]\n\[TRUNCATED_LINES removed=$removedLines\]"
        }
    }

    return [dict create \
        full $fullText \
        display $display \
        removed_chars $removedChars \
        removed_lines $removedLines]
}

proc ::coding_agent_loop::tools::parse_args {rawArgs} {
    if {$rawArgs eq ""} {
        return {}
    }

    if {[catch {dict size $rawArgs}]} {
        if {[catch {::attractor_core::json_decode $rawArgs} decoded]} {
            return -code error "tool arguments are neither dict nor JSON"
        }
        return $decoded
    }

    return $rawArgs
}

proc ::coding_agent_loop::tools::validate_args {toolName schema rawArgs} {
    set args [::coding_agent_loop::tools::parse_args $rawArgs]
    set errors [::attractor_core::schema_validate $schema $args]
    if {[llength $errors] > 0} {
        return -code error [dict create type schema_error tool $toolName errors $errors]
    }
    return $args
}

proc ::coding_agent_loop::tools::read_file {args _toolCall} {
    set path [dict get $args path]
    if {![file exists $path]} {
        return -code error "file does not exist: $path"
    }
    set fh [open $path r]
    set data [read $fh]
    close $fh
    return $data
}

proc ::coding_agent_loop::tools::write_file {args _toolCall} {
    set path [dict get $args path]
    set content [dict get $args content]
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts -nonewline $fh $content
    close $fh
    return "wrote $path"
}

proc ::coding_agent_loop::tools::edit_file {args _toolCall} {
    set path [dict get $args path]
    set old [dict get $args old_string]
    set new [dict get $args new_string]

    if {![file exists $path]} {
        return -code error "file does not exist: $path"
    }

    set fh [open $path r]
    set content [read $fh]
    close $fh

    set matches [regexp -all -inline -- [regexp -quote $old] $content]
    if {[llength $matches] == 0} {
        return -code error "old_string not found"
    }
    if {[llength $matches] > 1} {
        return -code error "old_string not unique"
    }

    set updated [string map [list $old $new] $content]
    set out [open $path w]
    puts -nonewline $out $updated
    close $out
    return "edited $path"
}

proc ::coding_agent_loop::tools::apply_patch {args _toolCall} {
    set patch [dict get $args patch]

    set lines [split $patch "\n"]
    if {[llength $lines] < 2 || [lindex $lines 0] ne "*** Begin Patch"} {
        return -code error "invalid patch header"
    }

    set idx 1
    while {$idx < [llength $lines]} {
        set line [lindex $lines $idx]
        if {$line eq "*** End Patch"} {
            break
        }

        if {[string match "*** Add File: *" $line]} {
            set path [string range $line 14 end]
            incr idx
            set content {}
            while {$idx < [llength $lines]} {
                set entry [lindex $lines $idx]
                if {[string match "*** *" $entry]} {
                    break
                }
                if {[string index $entry 0] eq "+"} {
                    lappend content [string range $entry 1 end]
                }
                incr idx
            }
            file mkdir [file dirname $path]
            set fh [open $path w]
            puts -nonewline $fh [join $content "\n"]
            close $fh
            continue
        }

        if {[string match "*** Delete File: *" $line]} {
            set path [string range $line 17 end]
            if {[file exists $path]} {
                file delete $path
            }
            incr idx
            continue
        }

        if {[string match "*** Update File: *" $line]} {
            set path [string range $line 17 end]
            if {![file exists $path]} {
                return -code error "cannot update missing file: $path"
            }

            set fh [open $path r]
            set content [read $fh]
            close $fh

            incr idx
            set removeLines {}
            set addLines {}
            while {$idx < [llength $lines]} {
                set entry [lindex $lines $idx]
                if {[string match "*** *" $entry]} {
                    break
                }
                if {[string index $entry 0] eq "-"} {
                    lappend removeLines [string range $entry 1 end]
                } elseif {[string index $entry 0] eq "+"} {
                    lappend addLines [string range $entry 1 end]
                }
                incr idx
            }

            if {[llength $removeLines] > 0} {
                set removeBlock [join $removeLines "\n"]
                set addBlock [join $addLines "\n"]
                if {[string first $removeBlock $content] < 0} {
                    return -code error "update hunk did not match target content"
                }
                set content [string map [list $removeBlock $addBlock] $content]
            }

            set out [open $path w]
            puts -nonewline $out $content
            close $out
            continue
        }

        incr idx
    }

    return "patch applied"
}

proc ::coding_agent_loop::tools::shell {args _toolCall} {
    set command [dict get $args command]
    set maxMs 60000
    if {[dict exists $args max_ms]} {
        set maxMs [dict get $args max_ms]
    }
    set result [::attractor_core::exec_with_control -command [list sh -lc $command] -max_ms $maxMs]
    if {[dict get $result timed_out]} {
        return "[dict get $result stdout]\n\[CANCELLED max_ms=$maxMs\]"
    }
    return [dict get $result stdout]
}

proc ::coding_agent_loop::tools::grep {args _toolCall} {
    set pattern [dict get $args pattern]
    set path "."
    if {[dict exists $args path]} {
        set path [dict get $args path]
    }

    if {[auto_execok rg] ne ""} {
        set result [::attractor_core::exec_with_control -command [list rg --line-number --color never $pattern $path] -max_ms 60000]
    } else {
        set result [::attractor_core::exec_with_control -command [list grep -R -n $pattern $path] -max_ms 60000]
    }
    return [dict get $result stdout]
}

proc ::coding_agent_loop::tools::glob_paths {args _toolCall} {
    set pattern [dict get $args pattern]
    set root "."
    if {[dict exists $args root]} {
        set root [dict get $args root]
    }
    set hits [glob -nocomplain -directory $root -types {f} $pattern]
    return [join $hits "\n"]
}

proc ::coding_agent_loop::tools::spawn_agent {args _toolCall} {
    variable agents
    variable agent_seq

    set profile [dict get $args profile]
    incr agent_seq
    set agentId "agent-$agent_seq"
    set session [::coding_agent_loop::session new -profile $profile -env ::coding_agent_loop::default_env]
    dict set agents $agentId $session
    return [dict create agent_id $agentId]
}

proc ::coding_agent_loop::tools::send_input {args _toolCall} {
    variable agents
    set agentId [dict get $args agent_id]
    set input [dict get $args input]
    if {![dict exists $agents $agentId]} {
        return -code error "unknown agent id: $agentId"
    }
    set session [dict get $agents $agentId]
    return [$session submit $input]
}

proc ::coding_agent_loop::tools::wait {args _toolCall} {
    variable agents
    set agentId [dict get $args agent_id]
    if {![dict exists $agents $agentId]} {
        return -code error "unknown agent id: $agentId"
    }
    return [dict create agent_id $agentId state complete]
}

proc ::coding_agent_loop::tools::close_agent {args _toolCall} {
    variable agents
    set agentId [dict get $args agent_id]
    if {![dict exists $agents $agentId]} {
        return -code error "unknown agent id: $agentId"
    }
    set session [dict get $agents $agentId]
    $session close
    dict unset agents $agentId
    return [dict create agent_id $agentId state closed]
}

proc ::coding_agent_loop::tools::default_registry {} {
    set schemas [::coding_agent_loop::tools::default_tool_schemas]
    set registry {}

    foreach {name command} {
        read_file ::coding_agent_loop::tools::read_file
        write_file ::coding_agent_loop::tools::write_file
        edit_file ::coding_agent_loop::tools::edit_file
        apply_patch ::coding_agent_loop::tools::apply_patch
        shell ::coding_agent_loop::tools::shell
        grep ::coding_agent_loop::tools::grep
        glob ::coding_agent_loop::tools::glob_paths
        spawn_agent ::coding_agent_loop::tools::spawn_agent
        send_input ::coding_agent_loop::tools::send_input
        wait ::coding_agent_loop::tools::wait
        close_agent ::coding_agent_loop::tools::close_agent
    } {
        dict set registry $name [dict create \
            name $name \
            command $command \
            schema [dict get $schemas $name] \
            char_limit 6000 \
            line_limit 200]
    }

    return $registry
}
