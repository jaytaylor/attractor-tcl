#!/usr/bin/env tclsh
package require Tcl 8.5-
package require json

proc usage {} {
    puts stderr "usage: tclsh tools/spec_coverage.tcl ?traceability_path? ?--trace <path>? ?--requirements <path>? ?--skip-verify-sanity?"
}

proc split_paths {value} {
    set tokens {}
    foreach part [split [string map [list "\t" " "] $value] ","] {
        set item [string trim $part]
        if {$item ne ""} {
            lappend tokens $item
        }
    }
    return $tokens
}

proc require_paths {reqId key value} {
    upvar 1 badPaths badPaths
    set paths [split_paths $value]
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

proc parse_traceability {path} {
    if {![file exists $path]} {
        puts stderr "traceability file not found: $path"
        exit 2
    }

    set fh [open $path r]
    set text [read $fh]
    close $fh

    set blocks [split [string map [list "\n---\n" "\u001f"] $text] "\u001f"]
    set parsed {}
    set errors {}
    set blockNum 0
    foreach block $blocks {
        incr blockNum
        set block [string trim $block]
        if {$block eq ""} {
            continue
        }
        array unset fields
        set sawKeyValue 0
        foreach line [split $block "\n"] {
            if {[regexp {^([a-z_]+):\s*(.*)$} [string trim $line] -> key value]} {
                set fields($key) [string trim $value]
                set sawKeyValue 1
            }
        }
        if {![info exists fields(id)] || $fields(id) eq ""} {
            if {$sawKeyValue} {
                lappend errors "MALFORMED_BLOCK block=$blockNum missing id"
            }
            continue
        }
        set one [dict create id $fields(id)]
        foreach k {spec impl tests verify} {
            if {[info exists fields($k)]} {
                dict set one $k $fields($k)
            }
        }
        lappend parsed $one
    }
    return [dict create mappings $parsed errors $errors]
}

proc parse_catalog_ids {path} {
    if {![file exists $path]} {
        puts stderr "requirements catalog not found: $path"
        exit 2
    }

    set fh [open $path r]
    set text [read $fh]
    close $fh

    if {[catch {set parsed [::json::json2dict $text]} err]} {
        puts stderr "requirements catalog parse error: $err"
        exit 2
    }

    if {[catch {dict exists $parsed requirements} hasRequirements]} {
        puts stderr "requirements catalog parse error: top-level JSON object expected"
        exit 2
    }
    if {!$hasRequirements} {
        puts stderr "requirements catalog missing 'requirements' array: $path"
        exit 2
    }

    set requirements [dict get $parsed requirements]
    if {[llength $requirements] == 0} {
        puts stderr "requirements catalog has no ids: $path"
        exit 2
    }

    set ids {}
    array set seen {}
    foreach req $requirements {
        if {[catch {dict exists $req id} hasId]} {
            puts stderr "requirements catalog entry is not an object: $path"
            exit 2
        }
        if {!$hasId} {
            puts stderr "requirements catalog entry missing id: $path"
            exit 2
        }
        set id [dict get $req id]
        if {$id eq ""} {
            puts stderr "requirements catalog entry has empty id: $path"
            exit 2
        }
        if {[info exists seen($id)]} {
            puts stderr "requirements catalog has duplicate id: $id"
            exit 2
        }
        set seen($id) 1
        lappend ids $id
    }

    return $ids
}

proc collect_test_names {} {
    set root [pwd]
    set files {}
    foreach dir {unit integration e2e} {
        foreach f [glob -nocomplain -directory [file join $root tests $dir] *.test] {
            lappend files $f
        }
    }

    set names {}
    foreach f [lsort $files] {
        set fh [open $f r]
        set lines [split [read $fh] "\n"]
        close $fh
        foreach line $lines {
            if {[regexp {^\s*test\s+([^\s]+)} $line -> name]} {
                lappend names $name
            }
        }
    }
    return $names
}

proc verify_pattern_matches_any_test {pattern testNames} {
    foreach name $testNames {
        if {[string match $pattern $name]} {
            return 1
        }
    }
    return 0
}

set tracePath [file join [pwd] docs spec-coverage traceability.md]
set requirementsPath [file join [pwd] docs spec-coverage requirements.json]
set verifySanity 1

set idx 0
while {$idx < $argc} {
    set arg [lindex $argv $idx]
    switch -- $arg {
        --trace {
            incr idx
            if {$idx >= $argc} { usage; exit 2 }
            set tracePath [lindex $argv $idx]
        }
        --requirements {
            incr idx
            if {$idx >= $argc} { usage; exit 2 }
            set requirementsPath [lindex $argv $idx]
        }
        --skip-verify-sanity {
            set verifySanity 0
        }
        default {
            if {[string match --* $arg]} {
                usage
                puts stderr "unknown arg: $arg"
                exit 2
            }
            set tracePath $arg
        }
    }
    incr idx
}

set parsedTraceability [parse_traceability $tracePath]
set mappings [dict get $parsedTraceability mappings]
set parseErrors [dict get $parsedTraceability errors]
set catalogIds [parse_catalog_ids $requirementsPath]

set total 0
set missing 0
set duplicates 0
set badPaths 0
set badVerify 0
set missingCatalog 0
set unknownCatalog 0
set malformedBlocks 0
array set seen {}
array set familyCount {}

set testNames {}
if {$verifySanity} {
    set testNames [collect_test_names]
}

foreach err $parseErrors {
    puts $err
    incr malformedBlocks
}

foreach mapping $mappings {
    set reqId [dict get $mapping id]

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
        if {![dict exists $mapping $key]} {
            puts "MISSING $reqId $key"
            incr missing
        } elseif {[string trim [dict get $mapping $key]] eq ""} {
            puts "MISSING $reqId $key"
            incr missing
        }
    }

    if {[dict exists $mapping impl] && [string trim [dict get $mapping impl]] ne ""} {
        require_paths $reqId impl [dict get $mapping impl]
    }
    if {[dict exists $mapping tests] && [string trim [dict get $mapping tests]] ne ""} {
        require_paths $reqId tests [dict get $mapping tests]
    }

    if {[dict exists $mapping verify] && [string trim [dict get $mapping verify]] ne ""} {
        set verify [dict get $mapping verify]
        if {[string first "`" $verify] < 0} {
            puts "BAD_VERIFY $reqId verify must contain command in backticks"
            incr badVerify
        } elseif {$verifySanity} {
            if {![regexp {`([^`]+)`} $verify -> command]} {
                puts "BAD_VERIFY $reqId verify command extraction failed"
                incr badVerify
            } else {
                if {![regexp {tests/all\.tcl\s+-match\s+([^\s]+)} $command -> pattern]} {
                    puts "BAD_VERIFY $reqId verify must include tests/all.tcl -match <pattern>"
                    incr badVerify
                } else {
                    set pattern [string trim $pattern "\"'"]
                    if {![verify_pattern_matches_any_test $pattern $testNames]} {
                        puts "BAD_VERIFY_PATTERN $reqId $pattern"
                        incr badVerify
                    }
                }
            }
        }
    }
}

array set catalogSet {}
foreach id $catalogIds {
    set catalogSet($id) 1
}

foreach id [array names catalogSet] {
    if {![info exists seen($id)]} {
        puts "MISSING_REQUIREMENT $id"
        incr missingCatalog
    }
}

foreach id [array names seen] {
    if {![info exists catalogSet($id)]} {
        puts "UNKNOWN_REQUIREMENT $id"
        incr unknownCatalog
    }
}

puts "requirements=$total"
puts "catalog_requirements=[llength $catalogIds]"
puts "missing=$missing"
puts "duplicates=$duplicates"
puts "bad_paths=$badPaths"
puts "bad_verify=$badVerify"
puts "malformed_blocks=$malformedBlocks"
puts "missing_catalog=$missingCatalog"
puts "unknown_catalog=$unknownCatalog"

foreach family [lsort [array names familyCount]] {
    puts "family_${family}=$familyCount($family)"
}

if {$missing > 0 || $duplicates > 0 || $badPaths > 0 || $badVerify > 0 || $malformedBlocks > 0 || $missingCatalog > 0 || $unknownCatalog > 0 || $total == 0} {
    exit 1
}
exit 0
