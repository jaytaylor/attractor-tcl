#!/usr/bin/env tclsh
package require Tcl 8.5

set root [file normalize [file join [file dirname [info script]] ..]]
lappend auto_path $root

foreach pkg {attractor_core unified_llm coding_agent_loop attractor} {
    package require $pkg
    puts "loaded $pkg"
}

puts "build check complete"
