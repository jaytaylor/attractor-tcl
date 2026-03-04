#!/usr/bin/env tclsh
package require Tcl 8.5-

set root [file normalize [file join [file dirname [info script]] ..]]
lappend auto_path $root

proc run_checked {argv} {
    puts "running [join $argv { }]"
    if {[catch {exec {*}$argv} output]} {
        if {$output ne ""} {
            puts stderr $output
        }
        error "command failed: [join $argv { }]"
    }
    if {$output ne ""} {
        puts $output
    }
}

set startDir [pwd]
cd $root

foreach pkg {attractor_core unified_llm coding_agent_loop attractor} {
    package require $pkg
    puts "loaded $pkg"
}

run_checked [list tclsh tools/requirements_catalog.tcl --check-ids]
run_checked [list tclsh tools/spec_coverage.tcl]

cd $startDir
puts "build check complete"
