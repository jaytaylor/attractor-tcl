package require Tcl 8.5-
package require tcltest

namespace import ::tcltest::*

set root [file normalize [file join [file dirname [info script]] ..]]
lappend auto_path $root

set matchPattern "*"
set skipPattern ""
set listOnly 0

set idx 0
while {$idx < $argc} {
    set arg [lindex $argv $idx]
    switch -- $arg {
        -match {
            incr idx
            set matchPattern [lindex $argv $idx]
        }
        -skip {
            incr idx
            set skipPattern [lindex $argv $idx]
        }
        -list {
            set listOnly 1
        }
        default {
            puts stderr "unknown arg: $arg"
            exit 2
        }
    }
    incr idx
}

::tcltest::configure -testdir [file dirname [info script]] -match $matchPattern
if {$skipPattern ne ""} {
    ::tcltest::configure -skip $skipPattern
}

source [file join $root tests support mock_http_server.tcl]
source [file join $root tests support http_client.tcl]

set files {}
foreach dir {unit integration e2e} {
    foreach f [lsort [glob -nocomplain -directory [file join $root tests $dir] *.test]] {
        lappend files $f
    }
}

if {$listOnly} {
    foreach f $files {
        puts $f
    }
    exit 0
}

foreach f $files {
    source $f
}

set failedCount $::tcltest::numTests(Failed)
::tcltest::cleanupTests

if {$failedCount > 0} {
    exit 1
}
exit 0
