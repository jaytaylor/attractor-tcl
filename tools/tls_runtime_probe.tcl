#!/usr/bin/env tclsh
package require Tcl 8.5-

set root [file normalize [file join [file dirname [info script]] ..]]
lappend auto_path $root

if {$argc > 1} {
    puts stderr "usage: tclsh tools/tls_runtime_probe.tcl ?<min_tls_version>?"
    exit 2
}

if {[catch {package require unified_llm} requireErr]} {
    puts stderr "tls_probe_error=failed to load unified_llm package: $requireErr"
    exit 2
}

if {$argc == 1} {
    set ::unified_llm::transports::https_json::tls_min_version [lindex $argv 0]
}

set probe [::unified_llm::transports::https_json::runtime_preflight]

puts "tcl=[dict get $probe tcl_version]"
puts "tls_min=[dict get $probe tls_min_version]"
if {[dict exists $probe tls_version]} {
    puts "tls=[dict get $probe tls_version]"
} else {
    puts "tls=missing"
}
puts "tls_supported=[dict get $probe tls_supported]"

if {![dict get $probe tls_supported]} {
    puts stderr "tls_probe_error=[dict get $probe message]"
    if {[dict exists $probe error_detail] && [dict get $probe error_detail] ne ""} {
        puts stderr "tls_probe_detail=[dict get $probe error_detail]"
    }
    exit 1
}

puts "tls_probe_status=ok"
exit 0
