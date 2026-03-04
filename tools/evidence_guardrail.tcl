#!/usr/bin/env tclsh
package require Tcl 8.5-

if {$argc < 1} {
    puts stderr "usage: tclsh tools/evidence_guardrail.tcl <doc-path> ?<doc-path> ...?"
    exit 2
}

set missing 0
set checked 0
array set seen {}

foreach doc $argv {
    if {![file exists $doc]} {
        puts stderr "MISSING_DOC $doc"
        incr missing
        continue
    }

    set fh [open $doc r]
    set lines [split [read $fh] "\n"]
    close $fh

    for {set i 0} {$i < [llength $lines]} {incr i} {
        set lineNo [expr {$i + 1}]
        set line [lindex $lines $i]
        set matches [regexp -all -inline {\.scratch/[A-Za-z0-9._/\-]+} $line]
        foreach raw $matches {
            set path $raw
            regsub {[`'",\)\]]+$} $path "" path
            if {$path eq ""} {
                continue
            }
            if {[info exists seen($doc|$path)]} {
                continue
            }
            set seen($doc|$path) 1
            incr checked
            if {![file exists $path]} {
                puts "MISSING_EVIDENCE $doc:$lineNo $path"
                incr missing
            }
        }
    }
}

puts "checked=$checked"
puts "missing=$missing"

if {$missing > 0} {
    exit 1
}
exit 0
