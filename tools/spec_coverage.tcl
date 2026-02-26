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
set duplicates 0
set badPaths 0
set badVerify 0
array set seen {}
array set familyCount {}

proc __split_paths {value} {
    set tokens {}
    foreach part [split [string map [list "\t" " "] $value] ","] {
        set item [string trim $part]
        if {$item ne ""} {
            lappend tokens $item
        }
    }
    return $tokens
}

proc __require_paths {reqId key value} {
    upvar 1 badPaths badPaths
    set paths [__split_paths $value]
    if {[llength $paths] == 0} {
        puts "MISSING_PATHS $reqId $key"
        incr badPaths
        return
    }
    foreach p $paths {
        if {![file exists $p]} {
            puts "BAD_PATH $reqId $key $p"
            incr badPaths
        }
    }
}

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
    if {[info exists seen($reqId)]} {
        puts "DUPLICATE $reqId"
        incr duplicates
        continue
    }
    set seen($reqId) 1
    incr total

    if {[regexp {^([A-Z]+)-} $reqId -> family]} {
        if {![info exists familyCount($family)]} {
            set familyCount($family) 0
        }
        incr familyCount($family)
    }

    foreach key {spec impl tests verify} {
        if {![info exists fields($key)]} {
            puts "MISSING $reqId $key"
            incr missing
        } elseif {$fields($key) eq ""} {
            puts "MISSING $reqId $key"
            incr missing
        }
    }

    if {[info exists fields(impl)] && $fields(impl) ne ""} {
        __require_paths $reqId impl $fields(impl)
    }
    if {[info exists fields(tests)] && $fields(tests) ne ""} {
        __require_paths $reqId tests $fields(tests)
    }
    if {[info exists fields(verify)] && $fields(verify) ne ""} {
        set verify $fields(verify)
        if {[string first "`" $verify] < 0} {
            puts "BAD_VERIFY $reqId verify must contain command in backticks"
            incr badVerify
        }
    }
}

puts "requirements=$total"
puts "missing=$missing"
puts "duplicates=$duplicates"
puts "bad_paths=$badPaths"
puts "bad_verify=$badVerify"

foreach family [lsort [array names familyCount]] {
    puts "family_${family}=$familyCount($family)"
}

if {$missing > 0 || $duplicates > 0 || $badPaths > 0 || $badVerify > 0 || $total == 0} {
    exit 1
}
exit 0
