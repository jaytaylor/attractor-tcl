#!/usr/bin/env tclsh
package require Tcl 8.5-
package require json

proc usage {} {
    puts stderr "usage: tclsh tools/requirements_catalog.tcl ?--check-ids? ?--summary? ?--out-json <path>? ?--out-md <path>? ?--spec <path|family|dod_heading>?"
}

proc default_specs {} {
    return [list \
        [dict create path unified-llm-spec.md family ULLM dod_heading {Definition of Done}] \
        [dict create path coding-agent-loop-spec.md family CAL dod_heading {Definition of Done}] \
        [dict create path attractor-spec.md family ATR dod_heading {Definition of Done}] \
    ]
}

proc extract_req_id {line} {
    if {[regexp {<!--\s*req_id:\s*([A-Za-z0-9._-]+)\s*-->} $line -> reqId]} {
        return $reqId
    }
    return ""
}

proc strip_req_comment {line} {
    regsub {\s*<!--\s*req_id:\s*[^>]+-->\s*$} $line "" out
    return $out
}

proc normalize_spaces {text} {
    regsub -all {\s+} [string trim $text] { } out
    return $out
}

proc strip_markdown_for_norm_scan {line} {
    set out $line
    regsub -all {`[^`]*`} $out " " out
    regsub -all {\[[^\]]*\]\([^\)]+\)} $out " " out
    regsub -all {https?://\S+} $out " " out
    regsub -all {<[^>]+>} $out " " out
    return $out
}

proc json_string {value} {
    set escaped [string map [list "\\" "\\\\" "\"" "\\\"" "\n" "\\n" "\r" "\\r" "\t" "\\t"] $value]
    return "\"$escaped\""
}

proc parse_spec {specConfig} {
    set path [dict get $specConfig path]
    set family [dict get $specConfig family]
    set dodHeading [dict get $specConfig dod_heading]

    set errors {}
    set requirements {}

    if {![file exists $path]} {
        lappend errors "MISSING_SPEC_FILE $path"
        return [dict create requirements $requirements errors $errors]
    }

    set fh [open $path r]
    set raw [read $fh]
    close $fh
    set lines [split $raw "\n"]

    set inFence 0
    set inDoD 0
    set doDDepth 0
    set sawDoD 0
    set currentHeading ""

    for {set idx 0} {$idx < [llength $lines]} {incr idx} {
        set lineNo [expr {$idx + 1}]
        set line [lindex $lines $idx]

        if {[regexp {^\s*```} $line]} {
            set inFence [expr {!$inFence}]
            continue
        }

        if {[regexp {^(#+)\s+(.*)$} $line -> hashes heading]} {
            set heading [normalize_spaces $heading]
            set depth [string length $hashes]
            set currentHeading $heading

            if {$inDoD && ![string match -nocase "*$dodHeading*" $heading] && $depth <= $doDDepth} {
                set inDoD 0
            }

            if {[string match -nocase "*$dodHeading*" $heading]} {
                set sawDoD 1
                set inDoD 1
                set doDDepth $depth
            }
            continue
        }

        if {$inFence} {
            continue
        }

        if {$inDoD && [regexp {^\s*-\s*\[[ xX]\]\s+(.+)$} $line -> body]} {
            set reqId [extract_req_id $line]
            if {$reqId eq ""} {
                lappend errors "MISSING_REQ_ID $path:$lineNo DOD"
                continue
            }
            set combined [strip_req_comment $body]

            # Include markdown hard-wrap continuation lines for the same checkbox.
            set j [expr {$idx + 1}]
            while {$j < [llength $lines]} {
                set nextLine [lindex $lines $j]
                set nextTrim [string trim $nextLine]
                if {$nextTrim eq ""} {
                    break
                }
                if {[regexp {^\s*```} $nextLine]} {
                    break
                }
                if {[regexp {^(#+)\s+} $nextLine]} {
                    break
                }
                if {[regexp {^\s*-\s*\[[ xX]\]\s+} $nextLine]} {
                    break
                }
                if {[regexp {^\s{2,}\S} $nextLine]} {
                    append combined " " [strip_req_comment $nextTrim]
                    incr j
                    continue
                }
                break
            }
            set idx [expr {$j - 1}]

            set clean [normalize_spaces $combined]
            lappend requirements [dict create \
                id $reqId \
                family $family \
                kind DOD \
                spec $path \
                section $currentHeading \
                line $lineNo \
                text $clean \
                source_anchor "$path:$lineNo"]
            continue
        }

        if {!$inDoD} {
            set trimmed [string trim $line]
            if {$trimmed eq ""} {
                continue
            }
            if {[string match "|*" $trimmed]} {
                continue
            }

            set scan [strip_markdown_for_norm_scan $line]
            if {[regexp -nocase {\m(MUST NOT|MUST|REQUIRED)\M} $scan]} {
                set reqId [extract_req_id $line]
                if {$reqId eq ""} {
                    lappend errors "MISSING_REQ_ID $path:$lineNo NORMATIVE"
                    continue
                }
                set clean [normalize_spaces [strip_req_comment $line]]
                lappend requirements [dict create \
                    id $reqId \
                    family $family \
                    kind NORMATIVE \
                    spec $path \
                    section $currentHeading \
                    line $lineNo \
                    text $clean \
                    source_anchor "$path:$lineNo"]
            }
        }
    }

    if {!$sawDoD} {
        lappend errors "MISSING_DOD_HEADER $path heading='$dodHeading'"
    }

    return [dict create requirements $requirements errors $errors]
}

proc validate_requirement_ids {requirements} {
    set errors {}
    array set seen {}

    foreach req $requirements {
        set reqId [dict get $req id]
        set family [dict get $req family]
        set kind [dict get $req kind]
        set loc [dict get $req source_anchor]

        if {[info exists seen($reqId)]} {
            lappend errors "DUPLICATE_REQ_ID $reqId first=$seen($reqId) second=$loc"
        } else {
            set seen($reqId) $loc
        }

        if {$kind eq "DOD"} {
            if {![regexp {^(ULLM|CAL|ATR)-DOD-[0-9]+\.[0-9]+-[A-Z0-9][A-Z0-9-]*$} $reqId]} {
                lappend errors "BAD_REQ_ID_FORMAT $loc kind=DOD id=$reqId"
            }
            if {![string match "$family-DOD-*" $reqId]} {
                lappend errors "BAD_REQ_ID_FAMILY $loc expected_prefix=$family-DOD- id=$reqId"
            }
        } elseif {$kind eq "NORMATIVE"} {
            if {![regexp {^(ULLM|CAL|ATR)-REQ-[A-Z0-9][A-Z0-9-]*$} $reqId]} {
                lappend errors "BAD_REQ_ID_FORMAT $loc kind=NORMATIVE id=$reqId"
            }
            if {![string match "$family-REQ-*" $reqId]} {
                lappend errors "BAD_REQ_ID_FAMILY $loc expected_prefix=$family-REQ- id=$reqId"
            }
        } else {
            lappend errors "BAD_KIND $loc kind=$kind"
        }
    }

    return $errors
}

proc compare_requirements {a b} {
    set specA [dict get $a spec]
    set specB [dict get $b spec]
    if {$specA ne $specB} {
        return [string compare $specA $specB]
    }

    set lineA [dict get $a line]
    set lineB [dict get $b line]
    if {$lineA < $lineB} {
        return -1
    }
    if {$lineA > $lineB} {
        return 1
    }

    return [string compare [dict get $a id] [dict get $b id]]
}

proc emit_json {path specs requirements} {
    set specObjs {}
    foreach spec $specs {
        set specJson [join [list \
            "\{" \
            "\"path\": [json_string [dict get $spec path]]," \
            "\"family\": [json_string [dict get $spec family]]," \
            "\"dod_heading\": [json_string [dict get $spec dod_heading]]" \
            "\}"] " "]
        lappend specObjs $specJson
    }

    set reqObjs {}
    foreach req $requirements {
        set reqJson [join [list \
            "\{" \
            "\"id\": [json_string [dict get $req id]]," \
            "\"family\": [json_string [dict get $req family]]," \
            "\"kind\": [json_string [dict get $req kind]]," \
            "\"spec\": [json_string [dict get $req spec]]," \
            "\"section\": [json_string [dict get $req section]]," \
            "\"line\": [dict get $req line]," \
            "\"text\": [json_string [dict get $req text]]," \
            "\"source_anchor\": [json_string [dict get $req source_anchor]]" \
            "\}"] " "]
        lappend reqObjs $reqJson
    }

    set json [join [list \
        "{" \
        "\"specs\": \[[join $specObjs ,]\]," \
        "\"requirements\": \[[join $reqObjs ,]\]" \
        "}"] " "]

    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh $json
    close $fh
}

proc emit_markdown {path requirements} {
    file mkdir [file dirname $path]
    set fh [open $path w]

    puts $fh "# Derived Requirements Catalog"
    puts $fh ""
    puts $fh "Generated by `tools/requirements_catalog.tcl`."
    puts $fh ""

    array set familyCounts {}
    array set kindCounts {}
    foreach req $requirements {
        set family [dict get $req family]
        set kind [dict get $req kind]
        if {![info exists familyCounts($family)]} { set familyCounts($family) 0 }
        if {![info exists kindCounts($kind)]} { set kindCounts($kind) 0 }
        incr familyCounts($family)
        incr kindCounts($kind)
    }

    puts $fh "## Summary"
    puts $fh ""
    puts $fh "- Total requirements: [llength $requirements]"
    foreach family [lsort [array names familyCounts]] {
        puts $fh "- $family: $familyCounts($family)"
    }
    foreach kind [lsort [array names kindCounts]] {
        puts $fh "- $kind: $kindCounts($kind)"
    }
    puts $fh ""

    puts $fh "## Requirements"
    puts $fh ""
    foreach req $requirements {
        puts $fh "- `[dict get $req id]` ([dict get $req kind])"
        puts $fh "  - Spec: `[dict get $req spec]`"
        puts $fh "  - Source: `[dict get $req source_anchor]`"
        puts $fh "  - Text: [dict get $req text]"
    }

    close $fh
}

set checkIds 0
set summaryOnly 0
set outJson [file join docs spec-coverage requirements.json]
set outMd [file join docs spec-coverage requirements.md]
set specs {}

set idx 0
while {$idx < $argc} {
    set arg [lindex $argv $idx]
    switch -- $arg {
        --check-ids {
            set checkIds 1
        }
        --summary {
            set summaryOnly 1
        }
        --out-json {
            incr idx
            if {$idx >= $argc} { usage; exit 2 }
            set outJson [lindex $argv $idx]
        }
        --out-md {
            incr idx
            if {$idx >= $argc} { usage; exit 2 }
            set outMd [lindex $argv $idx]
        }
        --spec {
            incr idx
            if {$idx >= $argc} { usage; exit 2 }
            set token [lindex $argv $idx]
            set parts [split $token "|"]
            if {[llength $parts] != 3} {
                puts stderr "invalid --spec value '$token' (expected path|family|dod_heading)"
                exit 2
            }
            lappend specs [dict create path [lindex $parts 0] family [lindex $parts 1] dod_heading [lindex $parts 2]]
        }
        default {
            usage
            puts stderr "unknown arg: $arg"
            exit 2
        }
    }
    incr idx
}

if {[llength $specs] == 0} {
    set specs [default_specs]
}

set allRequirements {}
set allErrors {}
foreach spec $specs {
    set parsed [parse_spec $spec]
    foreach req [dict get $parsed requirements] {
        lappend allRequirements $req
    }
    foreach err [dict get $parsed errors] {
        lappend allErrors $err
    }
}

foreach err [validate_requirement_ids $allRequirements] {
    lappend allErrors $err
}

if {[llength $allErrors] > 0} {
    foreach err $allErrors {
        puts stderr $err
    }
    exit 1
}

set sorted [lsort -command compare_requirements $allRequirements]

if {!$checkIds && !$summaryOnly} {
    emit_json $outJson $specs $sorted
    emit_markdown $outMd $sorted
}

array set familyCounts {}
array set kindCounts {}
foreach req $sorted {
    set family [dict get $req family]
    set kind [dict get $req kind]
    if {![info exists familyCounts($family)]} { set familyCounts($family) 0 }
    if {![info exists kindCounts($kind)]} { set kindCounts($kind) 0 }
    incr familyCounts($family)
    incr kindCounts($kind)
}

puts "requirements=[llength $sorted]"
foreach family [lsort [array names familyCounts]] {
    puts "family_${family}=$familyCounts($family)"
}
foreach kind [lsort [array names kindCounts]] {
    puts "kind_${kind}=$kindCounts($kind)"
}

exit 0
