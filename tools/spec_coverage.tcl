#!/usr/bin/env tclsh
package require Tcl 8.5

if {$argc > 0} {
    set path [lindex $argv 0]
} else {
    set path [file join [pwd] docs spec-coverage traceability.md]
}

if {![file exists $path]} {
    puts stderr "traceability file not found: $path"
    exit 2
}

set fh [open $path r]
set text [read $fh]
close $fh

set blocks [split [string map [list "\n---\n" "\u001f"] $text] "\u001f"]
set total 0
set missing 0

foreach block $blocks {
    set block [string trim $block]
    if {$block eq ""} {
        continue
    }
    array unset fields
    foreach line [split $block "\n"] {
        if {[regexp {^([a-z_]+):\s*(.*)$} [string trim $line] -> key value]} {
            set fields($key) [string trim $value]
        }
    }

    if {![info exists fields(id)] || $fields(id) eq ""} {
        continue
    }
    set reqId $fields(id)
    incr total
    foreach key {spec impl tests verify} {
        if {![info exists fields($key)]} {
            puts "MISSING $reqId $key"
            incr missing
        } elseif {$fields($key) eq ""} {
            puts "MISSING $reqId $key"
            incr missing
        }
    }
}

puts "requirements=$total"
puts "missing=$missing"

if {$missing > 0 || $total == 0} {
    exit 1
}
exit 0
