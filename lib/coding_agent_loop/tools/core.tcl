namespace eval ::coding_agent_loop::tools {
    variable agents {}
    variable agent_seq 0
    variable env_seq 0
    variable envs {}
    variable default_env_cmd ""
}

package require Tcl 8.5
package require attractor_core

proc ::coding_agent_loop::tools::execution_environment_new {args} {
    variable env_seq
    variable envs

    array set opts {
        -type local
        -root ""
        -shell_max_ms 60000
    }
    array set opts $args

    if {$opts(-type) ne "local"} {
        return -code error "unsupported execution environment type: $opts(-type)"
    }

    incr env_seq
    set id $env_seq
    set cmd ::coding_agent_loop::tools::env::$id

    dict set envs $id [dict create type local root $opts(-root) shell_max_ms $opts(-shell_max_ms)]
    interp alias {} $cmd {} ::coding_agent_loop::tools::__env_dispatch $id
    return $cmd
}

proc ::coding_agent_loop::tools::__resolve_path {root path} {
    if {[file pathtype $path] eq "absolute"} {
        return $path
    }
    if {$root eq ""} {
        return $path
    }
    return [file join $root $path]
}

proc ::coding_agent_loop::tools::__patch_add_file {root lines idxVar} {
    upvar 1 $idxVar idx
    set header [lindex $lines $idx]
    set path [string range $header 14 end]
    set resolved [::coding_agent_loop::tools::__resolve_path $root $path]

    incr idx
    set content {}
    while {$idx < [llength $lines]} {
        set entry [lindex $lines $idx]
        if {[string match "*** *" $entry]} {
            break
        }
        if {$entry ne "" && [string index $entry 0] eq "+"} {
            lappend content [string range $entry 1 end]
        }
        incr idx
    }

    file mkdir [file dirname $resolved]
    set fh [open $resolved w]
    puts -nonewline $fh [join $content "\n"]
    close $fh
}

proc ::coding_agent_loop::tools::__patch_delete_file {root line} {
    set path [string range $line 17 end]
    set resolved [::coding_agent_loop::tools::__resolve_path $root $path]
    if {[file exists $resolved]} {
        file delete $resolved
    }
}

proc ::coding_agent_loop::tools::__patch_update_file {root lines idxVar} {
    upvar 1 $idxVar idx
    set header [lindex $lines $idx]
    set path [string range $header 17 end]
    set resolved [::coding_agent_loop::tools::__resolve_path $root $path]

    if {![file exists $resolved]} {
        return -code error "cannot update missing file: $resolved"
    }

    set fh [open $resolved r]
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
        if {$entry ne "" && [string index $entry 0] eq "-"} {
            lappend removeLines [string range $entry 1 end]
        } elseif {$entry ne "" && [string index $entry 0] eq "+"} {
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

    set out [open $resolved w]
    puts -nonewline $out $content
    close $out
}

proc ::coding_agent_loop::tools::__apply_patch_impl {root patch} {
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
            ::coding_agent_loop::tools::__patch_add_file $root $lines idx
            continue
        }

        if {[string match "*** Delete File: *" $line]} {
            ::coding_agent_loop::tools::__patch_delete_file $root $line
            incr idx
            continue
        }

        if {[string match "*** Update File: *" $line]} {
            ::coding_agent_loop::tools::__patch_update_file $root $lines idx
            continue
        }

        incr idx
    }

    return "patch applied"
}

proc ::coding_agent_loop::tools::__env_dispatch {id method args} {
    variable envs

    if {![dict exists $envs $id]} {
        return -code error "unknown execution environment id: $id"
    }

    set state [dict get $envs $id]
    set root [dict get $state root]

    switch -- $method {
        read_file {
            if {[llength $args] != 1} {
                return -code error "usage: \$env read_file path"
            }
            set path [::coding_agent_loop::tools::__resolve_path $root [lindex $args 0]]
            if {![file exists $path]} {
                return -code error "file does not exist: $path"
            }
            set fh [open $path r]
            set data [read $fh]
            close $fh
            return $data
        }
        write_file {
            if {[llength $args] != 2} {
                return -code error "usage: \$env write_file path content"
            }
            set path [::coding_agent_loop::tools::__resolve_path $root [lindex $args 0]]
            file mkdir [file dirname $path]
            set fh [open $path w]
            puts -nonewline $fh [lindex $args 1]
            close $fh
            return "wrote $path"
        }
        edit_file {
            if {[llength $args] != 3} {
                return -code error "usage: \$env edit_file path old_string new_string"
            }
            set path [::coding_agent_loop::tools::__resolve_path $root [lindex $args 0]]
            set old [lindex $args 1]
            set new [lindex $args 2]

            if {![file exists $path]} {
                return -code error "file does not exist: $path"
            }

            set fh [open $path r]
            set content [read $fh]
            close $fh

            set count 0
            set firstPos -1
            set cursor 0
            set oldLen [string length $old]
            while {1} {
                set pos [string first $old $content $cursor]
                if {$pos < 0} {
                    break
                }
                if {$firstPos < 0} {
                    set firstPos $pos
                }
                incr count
                set cursor [expr {$pos + $oldLen}]
            }

            if {$count == 0} {
                return -code error "old_string not found"
            }
            if {$count > 1} {
                return -code error "old_string not unique"
            }

            set updated [string replace $content $firstPos [expr {$firstPos + $oldLen - 1}] $new]
            set out [open $path w]
            puts -nonewline $out $updated
            close $out
            return "edited $path"
        }
        apply_patch {
            if {[llength $args] != 1} {
                return -code error "usage: \$env apply_patch patch"
            }
            return [::coding_agent_loop::tools::__apply_patch_impl $root [lindex $args 0]]
        }
        shell {
            if {[llength $args] != 1} {
                return -code error "usage: \$env shell argsDict"
            }
            set shellArgs [lindex $args 0]
            set command [dict get $shellArgs command]
            set maxMs [dict get $state shell_max_ms]
            if {[dict exists $shellArgs max_ms]} {
                set maxMs [dict get $shellArgs max_ms]
            }
            set cwd ""
            if {[dict exists $shellArgs cwd]} {
                set cwd [::coding_agent_loop::tools::__resolve_path $root [dict get $shellArgs cwd]]
            } elseif {$root ne ""} {
                set cwd $root
            }

            set execArgs [list -command [list sh -lc $command] -max_ms $maxMs]
            if {$cwd ne ""} {
                lappend execArgs -cwd $cwd
            }

            set result [::attractor_core::exec_with_control {*}$execArgs]
            if {[dict get $result timed_out]} {
                return "[dict get $result stdout]\n\[CANCELLED max_ms=$maxMs\]"
            }
            return [dict get $result stdout]
        }
        grep {
            if {[llength $args] != 2} {
                return -code error "usage: \$env grep pattern path"
            }
            set pattern [lindex $args 0]
            set path [::coding_agent_loop::tools::__resolve_path $root [lindex $args 1]]
            if {[auto_execok rg] ne ""} {
                set result [::attractor_core::exec_with_control -command [list rg --line-number --color never $pattern $path] -max_ms 60000]
            } else {
                set result [::attractor_core::exec_with_control -command [list grep -R -n $pattern $path] -max_ms 60000]
            }
            return [dict get $result stdout]
        }
        glob {
            if {[llength $args] != 2} {
                return -code error "usage: \$env glob pattern root"
            }
            set pattern [lindex $args 0]
            set scanRoot [::coding_agent_loop::tools::__resolve_path $root [lindex $args 1]]
            set hits [glob -nocomplain -directory $scanRoot -types {f} $pattern]
            return [join $hits "\n"]
        }
        config {
            return $state
        }
        close {
            rename ::coding_agent_loop::tools::env::$id {}
            dict unset envs $id
            return {}
        }
        default {
            return -code error "unknown execution environment method: $method"
        }
    }
}

proc ::coding_agent_loop::tools::default_tool_schemas {} {
    return [dict create \
        read_file [dict create type object required {path} properties [dict create path [dict create type string]]] \
        write_file [dict create type object required {path content} properties [dict create path [dict create type string] content [dict create type string]]] \
        edit_file [dict create type object required {path old_string new_string} properties [dict create path [dict create type string] old_string [dict create type string] new_string [dict create type string]]] \
        apply_patch [dict create type object required {patch} properties [dict create patch [dict create type string]]] \
        shell [dict create type object required {command} properties [dict create command [dict create type string] max_ms [dict create type integer] cwd [dict create type string]]] \
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

proc ::coding_agent_loop::tools::__resolve_env {toolCall} {
    variable default_env_cmd

    if {[catch {dict exists $toolCall execution_env_cmd}] == 0 && [dict exists $toolCall execution_env_cmd]} {
        set envCmd [dict get $toolCall execution_env_cmd]
        if {[llength [info commands $envCmd]] > 0} {
            return $envCmd
        }
    }

    if {$default_env_cmd eq "" || [llength [info commands $default_env_cmd]] == 0} {
        set default_env_cmd [::coding_agent_loop::tools::execution_environment_new -type local]
    }
    return $default_env_cmd
}

proc ::coding_agent_loop::tools::read_file {args toolCall} {
    set envCmd [::coding_agent_loop::tools::__resolve_env $toolCall]
    return [$envCmd read_file [dict get $args path]]
}

proc ::coding_agent_loop::tools::write_file {args toolCall} {
    set envCmd [::coding_agent_loop::tools::__resolve_env $toolCall]
    return [$envCmd write_file [dict get $args path] [dict get $args content]]
}

proc ::coding_agent_loop::tools::edit_file {args toolCall} {
    set envCmd [::coding_agent_loop::tools::__resolve_env $toolCall]
    return [$envCmd edit_file [dict get $args path] [dict get $args old_string] [dict get $args new_string]]
}

proc ::coding_agent_loop::tools::apply_patch {args toolCall} {
    set envCmd [::coding_agent_loop::tools::__resolve_env $toolCall]
    return [$envCmd apply_patch [dict get $args patch]]
}

proc ::coding_agent_loop::tools::shell {args toolCall} {
    set envCmd [::coding_agent_loop::tools::__resolve_env $toolCall]
    return [$envCmd shell $args]
}

proc ::coding_agent_loop::tools::grep {args toolCall} {
    set envCmd [::coding_agent_loop::tools::__resolve_env $toolCall]
    set path "."
    if {[dict exists $args path]} {
        set path [dict get $args path]
    }
    return [$envCmd grep [dict get $args pattern] $path]
}

proc ::coding_agent_loop::tools::glob_paths {args toolCall} {
    set envCmd [::coding_agent_loop::tools::__resolve_env $toolCall]
    set root "."
    if {[dict exists $args root]} {
        set root [dict get $args root]
    }
    return [$envCmd glob [dict get $args pattern] $root]
}

proc ::coding_agent_loop::tools::__resolve_session_id {sessionRef} {
    if {[dict exists $::coding_agent_loop::sessions $sessionRef]} {
        return $sessionRef
    }
    if {[regexp {::coding_agent_loop::session::([0-9]+)$} $sessionRef -> numeric]} {
        if {[dict exists $::coding_agent_loop::sessions $numeric]} {
            return $numeric
        }
    }
    return ""
}

proc ::coding_agent_loop::tools::spawn_agent {args toolCall} {
    variable agents
    variable agent_seq

    set profile [dict get $args profile]
    set parentDepth 0
    set maxDepth 2
    set executionEnv [::coding_agent_loop::tools::__resolve_env $toolCall]

    if {[dict exists $toolCall session_id]} {
        set parentId [::coding_agent_loop::tools::__resolve_session_id [dict get $toolCall session_id]]
    } else {
        set parentId ""
    }

    if {$parentId ne ""} {
        set parentSession [dict get $::coding_agent_loop::sessions $parentId]
        if {[dict exists $parentSession subagent_depth]} {
            set parentDepth [dict get $parentSession subagent_depth]
        }
        if {[dict exists $parentSession max_subagent_depth]} {
            set maxDepth [dict get $parentSession max_subagent_depth]
        }
        if {[dict exists $parentSession execution_env]} {
            set executionEnv [dict get $parentSession execution_env]
        }
    }

    set nextDepth [expr {$parentDepth + 1}]
    if {$nextDepth > $maxDepth} {
        return -code error "subagent depth limit exceeded"
    }

    incr agent_seq
    set agentId "agent-$agent_seq"
    set session [::coding_agent_loop::session new \
        -profile $profile \
        -env ::coding_agent_loop::default_env \
        -execution_env $executionEnv \
        -config [dict create subagent_depth $nextDepth max_subagent_depth $maxDepth]]

    dict set agents $agentId [dict create session $session depth $nextDepth]
    return [dict create agent_id $agentId depth $nextDepth]
}

proc ::coding_agent_loop::tools::send_input {args _toolCall} {
    variable agents
    set agentId [dict get $args agent_id]
    set input [dict get $args input]
    if {![dict exists $agents $agentId]} {
        return -code error "unknown agent id: $agentId"
    }
    set session [dict get $agents $agentId session]
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
    set session [dict get $agents $agentId session]
    $session close
    dict unset agents $agentId
    return [dict create agent_id $agentId state closed]
}

proc ::coding_agent_loop::tools::default_registry {args} {
    array set opts {
        -execution_env ""
        -char_limit 6000
        -line_limit 200
        -shell_max_ms 60000
    }
    array set opts $args

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
        set item [dict create \
            name $name \
            command $command \
            schema [dict get $schemas $name] \
            char_limit $opts(-char_limit) \
            line_limit $opts(-line_limit) \
            execution_env $opts(-execution_env)]
        if {$name eq "shell"} {
            dict set item default_shell_max_ms $opts(-shell_max_ms)
        }
        dict set registry $name $item
    }

    return $registry
}
