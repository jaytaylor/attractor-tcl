namespace eval ::attractor_core {
    variable version 0.1.0
}

package require Tcl 8.5
package require json
package require json::write

proc ::attractor_core::json_decode {payload} {
    if {$payload eq ""} {
        return {}
    }
    return [::json::json2dict $payload]
}

proc ::attractor_core::__json_escape {value} {
    return [string map [list "\\" "\\\\" "\"" "\\\"" "\n" "\\n" "\r" "\\r" "\t" "\\t"] $value]
}

proc ::attractor_core::__is_dict_like {value} {
    if {[catch {set vlen [llength $value]}]} {
        return 0
    }
    if {$vlen == 0} {
        return 1
    }
    if {$vlen == 2} {
        set key [lindex $value 0]
        set val [lindex $value 1]
        if {[::attractor_core::__is_dict_like $key]} {
            return 0
        }
        if {![regexp {^[A-Za-z_][A-Za-z0-9_:-]*$} $key]} {
            return 0
        }
        if {[::attractor_core::__is_dict_like $val] || [regexp {\s} $val] || [regexp {\}\s+\{} $val] || [regexp {[^A-Za-z0-9_.-]} $val]} {
            return 1
        }
        return 0
    }
    if {$vlen < 4} {
        return 0
    }
    if {[expr {$vlen % 2}] != 0} {
        return 0
    }
    if {[catch {dict size $value}]} {
        return 0
    }

    # Reject list-of-dicts payloads that can be parsed as dicts accidentally.
    for {set idx 0} {$idx < $vlen} {incr idx 2} {
        set key [lindex $value $idx]
        if {[::attractor_core::__is_dict_like $key]} {
            return 0
        }
    }

    return 1
}

proc ::attractor_core::__is_list_like {value} {
    if {[catch {llength $value}]} {
        return 0
    }
    if {[llength $value] == 0} {
        return 0
    }
    if {[::attractor_core::__is_dict_like $value]} {
        return 0
    }

    # Container-style Tcl list representations must be treated as JSON arrays.
    if {[regexp {\}\s+\{} $value]} {
        return 1
    }

    # Lists containing dictionary-like items should always serialize as arrays,
    # including the one-item case used by provider request payloads.
    foreach item $value {
        if {[::attractor_core::__is_dict_like $item]} {
            return 1
        }
    }

    # Treat whitespace-delimited scalar text as a JSON string, not an array.
    return 0
}

proc ::attractor_core::__json_encode_value {value} {
    if {[::attractor_core::__is_dict_like $value]} {
        set parts {}
        foreach key [dict keys $value] {
            set encodedKey "\"[::attractor_core::__json_escape $key]\""
            set encodedValue [::attractor_core::__json_encode_value [dict get $value $key]]
            lappend parts "${encodedKey}:${encodedValue}"
        }
        return "{[join $parts ,]}"
    }

    if {[::attractor_core::__is_list_like $value]} {
        set parts {}
        foreach item $value {
            lappend parts [::attractor_core::__json_encode_value $item]
        }
        return "\[[join $parts ,]\]"
    }

    if {[string is integer -strict $value] || [string is double -strict $value]} {
        return $value
    }
    if {$value in {true false null}} {
        return $value
    }
    return "\"[::attractor_core::__json_escape $value]\""
}

proc ::attractor_core::json_encode {value} {
    return [::attractor_core::__json_encode_value $value]
}

proc ::attractor_core::schema_validate {schema value {path "$"}} {
    set errors {}

    if {[dict exists $schema enum]} {
        set options [dict get $schema enum]
        if {[lsearch -exact $options $value] < 0} {
            lappend errors [dict create \
                path $path \
                code enum \
                message "value is not in enum set"]
            return $errors
        }
    }

    if {![dict exists $schema type]} {
        return $errors
    }

    set stype [dict get $schema type]
    switch -- $stype {
        object {
            if {[catch {dict size $value}]} {
                lappend errors [dict create \
                    path $path \
                    code type \
                    message "expected object"]
                return $errors
            }

            if {[dict exists $schema required]} {
                foreach key [dict get $schema required] {
                    if {![dict exists $value $key]} {
                        lappend errors [dict create \
                            path "$path.$key" \
                            code required \
                            message "required key missing"]
                    }
                }
            }

            if {[dict exists $schema properties]} {
                set props [dict get $schema properties]
                foreach key [dict keys $props] {
                    if {[dict exists $value $key]} {
                        set childSchema [dict get $props $key]
                        set childValue [dict get $value $key]
                        foreach childError [::attractor_core::schema_validate $childSchema $childValue "$path.$key"] {
                            lappend errors $childError
                        }
                    }
                }
            }
        }
        array {
            if {[catch {llength $value}]} {
                lappend errors [dict create \
                    path $path \
                    code type \
                    message "expected array"]
                return $errors
            }
            if {[dict exists $schema items]} {
                set itemSchema [dict get $schema items]
                set idx 0
                foreach item $value {
                    foreach childError [::attractor_core::schema_validate $itemSchema $item "$path\[$idx\]"] {
                        lappend errors $childError
                    }
                    incr idx
                }
            }
        }
        string {
            # Tcl uses strings as native values; nothing more required here.
            return $errors
        }
        integer {
            if {![regexp {^-?[0-9]+$} $value]} {
                lappend errors [dict create \
                    path $path \
                    code type \
                    message "expected integer"]
            }
        }
        number {
            if {![string is double -strict $value]} {
                lappend errors [dict create \
                    path $path \
                    code type \
                    message "expected number"]
            }
        }
        boolean {
            if {![string is boolean -strict $value]} {
                lappend errors [dict create \
                    path $path \
                    code type \
                    message "expected boolean"]
            }
        }
        default {
            lappend errors [dict create \
                path $path \
                code schema \
                message "unsupported schema type: $stype"]
        }
    }

    return $errors
}

proc ::attractor_core::schema_validate_or_error {schema value} {
    set errors [::attractor_core::schema_validate $schema $value]
    if {[llength $errors] > 0} {
        return -code error -errorcode [list ATTRACTOR_CORE SCHEMA] $errors
    }
    return {}
}

proc ::attractor_core::sse_parse {payload} {
    set payload [string map [list "\r\n" "\n" "\r" "\n"] $payload]
    set events {}
    set current [dict create event message data {}]

    foreach line [split $payload "\n"] {
        if {$line eq ""} {
            set dataLines [dict get $current data]
            if {[llength $dataLines] > 0 || [dict exists $current id] || [dict exists $current retry]} {
                set emitted [dict create event [dict get $current event] data [join $dataLines "\n"]]
                if {[dict exists $current id]} {
                    dict set emitted id [dict get $current id]
                }
                if {[dict exists $current retry]} {
                    dict set emitted retry [dict get $current retry]
                }
                lappend events $emitted
            }
            set current [dict create event message data {}]
            continue
        }

        if {[string index $line 0] eq ":"} {
            continue
        }

        set sep [string first ":" $line]
        if {$sep < 0} {
            set field $line
            set value ""
        } else {
            set field [string range $line 0 [expr {$sep - 1}]]
            set value [string range $line [expr {$sep + 1}] end]
            if {[string index $value 0] eq " "} {
                set value [string range $value 1 end]
            }
        }

        switch -- $field {
            event {
                dict set current event $value
            }
            data {
                dict lappend current data $value
            }
            id {
                dict set current id $value
            }
            retry {
                dict set current retry $value
            }
            default {
                # Ignore unsupported fields.
            }
        }
    }

    return $events
}

proc ::attractor_core::__shell_quote {value} {
    return "'[string map {' '\\''} $value]'"
}

proc ::attractor_core::__read_pipe {chan doneVar outputVar} {
    upvar 1 $doneVar done
    upvar 1 $outputVar output

    append output [read $chan]
    if {[eof $chan]} {
        set done 1
    }
}

proc ::attractor_core::exec_with_control {args} {
    array set opts {
        -command {}
        -cwd ""
        -max_ms 0
    }
    array set opts $args

    if {[llength $opts(-command)] == 0} {
        return -code error "-command is required"
    }

    set command $opts(-command)
    if {$opts(-cwd) ne ""} {
        set quoted {}
        foreach part $opts(-command) {
            lappend quoted [::attractor_core::__shell_quote $part]
        }
        set command [list sh -lc "cd [::attractor_core::__shell_quote $opts(-cwd)] && [join $quoted { }]"]
    }

    set timedOut 0
    set output ""
    set exitCode 0

    set wrapped $command
    if {$opts(-max_ms) > 0} {
        set seconds [expr {int(ceil(double($opts(-max_ms)) / 1000.0))}]
        if {$seconds < 1} {
            set seconds 1
        }
        set wrapped [concat [list perl -e {alarm shift; exec @ARGV} $seconds] $command]
    }

    if {[catch {exec {*}$wrapped 2>@1} output errOpts]} {
        set exitCode 1
        if {[dict exists $errOpts -errorcode]} {
            set ec [dict get $errOpts -errorcode]
            if {[lindex $ec 0] eq "CHILDSTATUS"} {
                set exitCode [lindex $ec 2]
            } elseif {[lindex $ec 0] eq "CHILDKILLED"} {
                set signal [lindex $ec 2]
                if {$signal eq "SIGALRM"} {
                    set exitCode 142
                } else {
                    set exitCode 137
                }
            }
        }
    }

    if {$opts(-max_ms) > 0 && $exitCode == 142} {
        set timedOut 1
        set exitCode 124
    }

    return [dict create \
        stdout $output \
        stderr "" \
        exit_code $exitCode \
        timed_out $timedOut]
}

package provide attractor_core $::attractor_core::version
