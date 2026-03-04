package require Tcl 8.5-
package require tcltest

namespace import ::tcltest::*

set root [file normalize [file join [file dirname [info script]] ..]]
lappend auto_path $root

package require attractor_core
package require unified_llm
package require coding_agent_loop
package require attractor
package require attractor_web

source [file join $root tests support e2e_live_support.tcl]
source [file join $root tests support http_client.tcl]

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

set files [lsort [glob -nocomplain -directory [file join $root tests e2e_live] *.test]]
if {$listOnly} {
    foreach f $files {
        puts $f
    }
    exit 0
}

set preflightCode [catch {::tests::e2e_live::initialize_run_context} preflightErr preflightOpts]
if {$preflightCode} {
    puts stderr "live-e2e preflight failed: $preflightErr"
    exit 2
}

::tcltest::configure -testdir [file join $root tests e2e_live] -match $matchPattern
if {$skipPattern ne ""} {
    ::tcltest::configure -skip $skipPattern
}

foreach f $files {
    source $f
}

set failedCount $::tcltest::numTests(Failed)
::tcltest::cleanupTests

set leaks [::tests::e2e_live::scan_artifacts_for_secret_leaks]
if {[llength $leaks] > 0} {
    set leakReport [file join $::tests::e2e_live::artifact_root secret-leaks.json]
    ::tests::e2e_live::write_json_file $leakReport [dict create status failed leaked_files $leaks]
    puts stderr "live-e2e secret leak scan failed; offending files:"
    foreach f $leaks {
        puts stderr "  $f"
    }
    incr failedCount
} else {
    ::tests::e2e_live::write_json_file [file join $::tests::e2e_live::artifact_root secret-leaks.json] [dict create status passed leaked_files {}]
}

set status [expr {$failedCount > 0 ? "failed" : "passed"}]
::tests::e2e_live::finalize_run_context $status failed_tests $failedCount secret_leaks $leaks

if {$failedCount > 0} {
    exit 1
}
exit 0
