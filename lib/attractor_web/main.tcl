namespace eval ::attractor_web {
    variable version 0.1.0
    variable server_seq 0
    variable run_seq 0
    variable servers {}
    variable dot_stream_seq 0
    variable dot_stream_states {}
    variable root [file normalize [file join [file dirname [info script]] .. ..]]
}

package require Tcl 8.5-
package require attractor
package require attractor_core
package require unified_llm

proc ::attractor_web::__json_quote {value} {
    return "\"[string map [list "\\" "\\\\" "\"" "\\\"" "\n" "\\n" "\r" "\\r" "\t" "\\t"] $value]\""
}

proc ::attractor_web::__json_read_raw {path fallback} {
    if {![file exists $path]} {
        return $fallback
    }
    if {[catch {set raw [::attractor_web::__read_file $path]}]} {
        return $fallback
    }
    if {[catch {::attractor_core::json_decode $raw}]} {
        return $fallback
    }
    return $raw
}

proc ::attractor_web::__iso8601_now {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]
}

proc ::attractor_web::__millis_now {} {
    if {[catch {set ms [clock clicks -milliseconds]}]} {
        set ms [expr {[clock seconds] * 1000}]
    }
    return $ms
}

proc ::attractor_web::__http_reason {status} {
    switch -- $status {
        200 { return "OK" }
        201 { return "Created" }
        400 { return "Bad Request" }
        404 { return "Not Found" }
        413 { return "Payload Too Large" }
        500 { return "Internal Server Error" }
        default { return "Status" }
    }
}

proc ::attractor_web::__json_error {message code} {
    return [dict create error $message code $code]
}

proc ::attractor_web::__read_file {path} {
    set fh [open $path r]
    set payload [read $fh]
    close $fh
    return $payload
}

proc ::attractor_web::__read_json_file {path} {
    if {![file exists $path]} {
        return {}
    }
    if {[catch {set payload [::attractor_web::__read_file $path]} err]} {
        return {}
    }
    if {[catch {set decoded [::attractor_core::json_decode $payload]}]} {
        return {}
    }
    return $decoded
}

proc ::attractor_web::__write_text_file {path payload} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts -nonewline $fh $payload
    close $fh
}

proc ::attractor_web::__write_json_file {path payload} {
    ::attractor_web::__write_text_file $path [::attractor_core::json_encode $payload]
}

proc ::attractor_web::__sha256_hex {payload} {
    if {[catch {package require sha256}]} {
        return ""
    }
    if {[catch {set digest [::sha2::sha256 -hex $payload]}]} {
        return ""
    }
    return $digest
}

proc ::attractor_web::__decode_component {value} {
    set value [string map [list + " "] $value]
    set out ""
    set i 0
    set n [string length $value]
    while {$i < $n} {
        set ch [string index $value $i]
        if {$ch eq "%" && $i + 2 < $n} {
            set hx [string range $value [expr {$i + 1}] [expr {$i + 2}]]
            if {[regexp {^[0-9A-Fa-f]{2}$} $hx]} {
                scan $hx %x code
                append out [format %c $code]
                incr i 3
                continue
            }
        }
        append out $ch
        incr i
    }
    return $out
}

proc ::attractor_web::__parse_query {queryText} {
    set out {}
    if {$queryText eq ""} {
        return $out
    }
    foreach pair [split $queryText &] {
        if {$pair eq ""} {
            continue
        }
        set eqIdx [string first = $pair]
        if {$eqIdx < 0} {
            set key [::attractor_web::__decode_component $pair]
            set value ""
        } else {
            set key [::attractor_web::__decode_component [string range $pair 0 [expr {$eqIdx - 1}]]]
            set value [::attractor_web::__decode_component [string range $pair [expr {$eqIdx + 1}] end]]
        }
        dict set out $key $value
    }
    return $out
}

proc ::attractor_web::__split_path_query {pathWithQuery} {
    set qidx [string first ? $pathWithQuery]
    if {$qidx < 0} {
        return [list $pathWithQuery {}]
    }
    set path [string range $pathWithQuery 0 [expr {$qidx - 1}]]
    set query [string range $pathWithQuery [expr {$qidx + 1}] end]
    return [list $path [::attractor_web::__parse_query $query]]
}

proc ::attractor_web::__run_id_valid {runId} {
    return [expr {[regexp {^[A-Za-z0-9][A-Za-z0-9_.-]*$} $runId] && [string first ".." $runId] < 0}]
}

proc ::attractor_web::__node_id_valid {nodeId} {
    return [regexp {^[A-Za-z_][A-Za-z0-9_]*$} $nodeId]
}

proc ::attractor_web::__qid_valid {qid} {
    return [regexp {^q-[0-9]+$} $qid]
}

proc ::attractor_web::__filename_valid {name} {
    if {[string trim $name] eq ""} {
        return 0
    }
    if {[string first ".." $name] >= 0} {
        return 0
    }
    if {[regexp {[/\\]} $name]} {
        return 0
    }
    return 1
}

proc ::attractor_web::normalize_dot_source {dotSource} {
    set trimmed [string trim $dotSource]

    if {[regexp {(?s)^```[ \t]*([A-Za-z0-9_-]+)?[ \t]*\n(.*)\n```[ \t]*$} $trimmed -> _ body]} {
        set trimmed [string trim $body]
    } else {
        set fenceStart [string first "```" $trimmed]
        if {$fenceStart >= 0} {
            set afterStart [string range $trimmed [expr {$fenceStart + 3}] end]
            set newlineIdx [string first "\n" $afterStart]
            if {$newlineIdx >= 0} {
                set fencedBody [string range $afterStart [expr {$newlineIdx + 1}] end]
                set fenceEnd [string first "```" $fencedBody]
                if {$fenceEnd >= 0} {
                    set fencedCandidate [string trim [string range $fencedBody 0 [expr {$fenceEnd - 1}]]]
                    if {[string first "digraph" [string tolower $fencedCandidate]] >= 0} {
                        set trimmed $fencedCandidate
                    }
                }
            }
        }
    }

    set lower [string tolower $trimmed]
    set digraphIdx [string first "digraph" $lower]
    if {$digraphIdx >= 0 && $digraphIdx > 0} {
        set trimmed [string trim [string range $trimmed $digraphIdx end]]
    }

    set braceStart [string first "\{" $trimmed]
    if {$braceStart >= 0} {
        set depth 0
        set stop -1
        set length [string length $trimmed]
        for {set idx $braceStart} {$idx < $length} {incr idx} {
            set ch [string index $trimmed $idx]
            if {$ch eq "\{"} {
                incr depth
            } elseif {$ch eq "\}"} {
                incr depth -1
                if {$depth == 0} {
                    set stop $idx
                    break
                }
            }
        }
        if {$stop >= 0} {
            set trimmed [string trim [string range $trimmed 0 $stop]]
        }
    }

    return $trimmed
}

proc ::attractor_web::__dot_diagnostics_summary {diagnostics} {
    set lines {}
    foreach d $diagnostics {
        if {![dict exists $d severity] || [dict get $d severity] ne "error"} {
            continue
        }
        set rule [expr {[dict exists $d rule] ? [dict get $d rule] : "validation.error"}]
        set message [expr {[dict exists $d message] ? [dict get $d message] : "validation error"}]
        lappend lines "$rule: $message"
        if {[llength $lines] >= 8} {
            break
        }
    }
    if {[llength $lines] == 0} {
        return "validation failed with unspecified diagnostics"
    }
    return [join $lines "\n"]
}

proc ::attractor_web::__dot_text_contains_any {text needles} {
    set lower [string tolower $text]
    foreach needle $needles {
        if {[string first [string tolower $needle] $lower] >= 0} {
            return 1
        }
    }
    return 0
}

proc ::attractor_web::__dot_node_text {nodeId attrs} {
    set parts [list $nodeId]
    foreach key {label prompt handler type tool_command retry_target question} {
        if {[dict exists $attrs $key]} {
            lappend parts [dict get $attrs $key]
        }
    }
    return [string tolower [join $parts " "]]
}

proc ::attractor_web::__dot_edge_text {edge} {
    if {![dict exists $edge attrs]} {
        return ""
    }
    set attrs [dict get $edge attrs]
    set parts {}
    foreach key {label condition outcome reason} {
        if {[dict exists $attrs $key]} {
            lappend parts [dict get $attrs $key]
        }
    }
    return [string tolower [join $parts " "]]
}

proc ::attractor_web::__dot_quality_summary {errors} {
    if {[llength $errors] == 0} {
        return ""
    }
    return [join [lrange $errors 0 7] "\n"]
}

proc ::attractor_web::__dot_quality_errors {graph} {
    set errors {}
    set nodes [dict get $graph nodes]
    set edges [dict get $graph edges]
    set exitNode [::attractor::__find_exit $graph]
    if {$exitNode eq ""} {
        lappend errors "cannot determine unique exit node"
        return $errors
    }

    set draftNodes {}
    set verifyNodes {}
    foreach nodeId [dict keys $nodes] {
        set attrs [dict get $nodes $nodeId attrs]
        set nodeText [::attractor_web::__dot_node_text $nodeId $attrs]

        if {[::attractor_web::__dot_text_contains_any $nodeText {draft implement build create generate author produce render compose craft write}] || ([dict exists $attrs handler] && [string tolower [dict get $attrs handler]] eq "codergen")} {
            lappend draftNodes $nodeId
        }
        set gateLike 0
        if {[dict exists $attrs goal_gate]} {
            set raw [string tolower [string trim [dict get $attrs goal_gate]]]
            if {$raw in {"1" "true" "yes"}} {
                set gateLike 1
            }
        }
        if {$gateLike || [::attractor_web::__dot_text_contains_any $nodeText {verify validation validate review check inspect assess test qa gate}]} {
            lappend verifyNodes $nodeId
        }
    }
    set draftNodes [lsort -unique $draftNodes]
    set verifyNodes [lsort -unique $verifyNodes]

    if {[llength $draftNodes] == 0} {
        lappend errors "missing draft/implement stage"
    }
    if {[llength $verifyNodes] == 0} {
        lappend errors "missing verify/review stage"
    }
    if {[llength $errors] > 0} {
        return $errors
    }

    set draftToVerify 0
    set retryRoute 0
    set successRoute 0

    foreach edge $edges {
        set from [dict get $edge from]
        set to [dict get $edge to]
        set edgeText [::attractor_web::__dot_edge_text $edge]

        if {[lsearch -exact $draftNodes $from] >= 0 && [lsearch -exact $verifyNodes $to] >= 0} {
            set draftToVerify 1
        }
        if {[lsearch -exact $verifyNodes $from] >= 0 && [lsearch -exact $draftNodes $to] >= 0} {
            if {$edgeText eq "" || [::attractor_web::__dot_text_contains_any $edgeText {retry fail failed rework revise fix again iterate change improve refine}]} {
                set retryRoute 1
            }
        }
        if {[lsearch -exact $verifyNodes $from] >= 0 && $to eq $exitNode} {
            if {$edgeText eq "" || [::attractor_web::__dot_text_contains_any $edgeText {success approve approved pass done complete}]} {
                set successRoute 1
            }
        }
    }

    if {!$draftToVerify} {
        lappend errors "missing draft/implement -> verify/review handoff edge"
    }
    if {!$retryRoute} {
        lappend errors "missing retry/rework loop from verify/review back to draft/implement"
    }
    if {!$successRoute} {
        lappend errors "missing verify/review success -> exit route"
    }

    return $errors
}

proc ::attractor_web::__dot_find_stage_node {nodes keywords} {
    foreach nodeId [dict keys $nodes] {
        set attrs [dict get $nodes $nodeId attrs]
        set nodeText [::attractor_web::__dot_node_text $nodeId $attrs]
        if {[::attractor_web::__dot_text_contains_any $nodeText $keywords]} {
            return $nodeId
        }
    }
    return ""
}

proc ::attractor_web::__dot_unique_node_id {nodes baseId} {
    set candidate [::attractor_web::__dot_sanitize_id $baseId]
    if {$candidate eq ""} {
        set candidate node
    }
    if {![dict exists $nodes $candidate]} {
        return $candidate
    }
    set idx 2
    while {[dict exists $nodes "${candidate}_$idx"]} {
        incr idx
    }
    return "${candidate}_$idx"
}

proc ::attractor_web::__dot_edge_exists {edges from to keywords} {
    foreach edge $edges {
        if {[dict get $edge from] ne $from || [dict get $edge to] ne $to} {
            continue
        }
        if {[llength $keywords] == 0} {
            return 1
        }
        set edgeText [::attractor_web::__dot_edge_text $edge]
        if {[::attractor_web::__dot_text_contains_any $edgeText $keywords]} {
            return 1
        }
    }
    return 0
}

proc ::attractor_web::__dot_enforce_quality_graph {graph} {
    set nodes [dict get $graph nodes]
    set edges [dict get $graph edges]

    set startNode [::attractor::__find_start $graph]
    if {$startNode eq ""} {
        set startNode [::attractor_web::__dot_unique_node_id $nodes start]
        dict set nodes $startNode [dict create id $startNode attrs [dict create shape Mdiamond label Start]]
    }
    set exitNode [::attractor::__find_exit $graph]
    if {$exitNode eq ""} {
        set exitNode [::attractor_web::__dot_unique_node_id $nodes exit]
        dict set nodes $exitNode [dict create id $exitNode attrs [dict create shape Msquare label Exit]]
    }

    set draftNode [::attractor_web::__dot_find_stage_node $nodes {draft implement implementation build codergen codegen create generate produce render compose craft write}]
    if {$draftNode eq ""} {
        set draftNode [::attractor_web::__dot_unique_node_id $nodes draft_artifact]
        dict set nodes $draftNode [dict create id $draftNode attrs [dict create label "Draft Artifact" prompt "Draft the requested output artifact from the user objective."]]
    }

    set verifyNode [::attractor_web::__dot_find_stage_node $nodes {verify validation validate review check inspect assess test qa gate}]
    if {$verifyNode eq ""} {
        set verifyNode [::attractor_web::__dot_unique_node_id $nodes verify_artifact]
        dict set nodes $verifyNode [dict create id $verifyNode attrs [dict create label "Verify Artifact" goal_gate true retry_target $draftNode prompt "Verify the artifact satisfies the objective. Return outcome=success or outcome=retry with specific issues."]]
    } else {
        set attrs [dict get $nodes $verifyNode attrs]
        if {![dict exists $attrs label] || [string trim [dict get $attrs label]] eq ""} {
            dict set attrs label "Verify Artifact"
        }
        dict set attrs goal_gate true
        dict set attrs retry_target $draftNode
        if {![dict exists $attrs prompt] || [string trim [dict get $attrs prompt]] eq ""} {
            dict set attrs prompt "Verify the artifact against the objective and return outcome=success or outcome=retry."
        }
        dict set nodes $verifyNode attrs $attrs
    }

    if {![::attractor_web::__dot_edge_exists $edges $startNode $draftNode {}]} {
        lappend edges [dict create from $startNode to $draftNode attrs [dict create]]
    }
    if {![::attractor_web::__dot_edge_exists $edges $draftNode $verifyNode {}]} {
        lappend edges [dict create from $draftNode to $verifyNode attrs [dict create]]
    }
    if {![::attractor_web::__dot_edge_exists $edges $verifyNode $draftNode {retry fail failed rework revise fix again iterate change improve refine}]} {
        lappend edges [dict create from $verifyNode to $draftNode attrs [dict create label retry condition "outcome=retry"]]
    }
    if {![::attractor_web::__dot_edge_exists $edges $verifyNode $draftNode {fail failed reject rejected}]} {
        lappend edges [dict create from $verifyNode to $draftNode attrs [dict create label fail condition "outcome=fail"]]
    }
    if {![::attractor_web::__dot_edge_exists $edges $verifyNode $exitNode {success approve approved pass done complete}]} {
        lappend edges [dict create from $verifyNode to $exitNode attrs [dict create label success condition "outcome=success"]]
    }

    set out $graph
    dict set out nodes $nodes
    dict set out edges $edges
    return $out
}

proc ::attractor_web::__dot_sanitize_id {raw} {
    set candidate [string trim [string map [list "-" "_"] $raw]]
    regsub -all {[^A-Za-z0-9_]} $candidate "_" candidate
    regsub -all {_+} $candidate "_" candidate
    set candidate [string trim $candidate "_"]
    if {$candidate eq ""} {
        return ""
    }
    if {![regexp {^[A-Za-z_]} $candidate]} {
        set candidate "n_$candidate"
    }
    return $candidate
}

proc ::attractor_web::__dot_attr_value {value} {
    if {[string is integer -strict $value] || [string is double -strict $value]} {
        return $value
    }
    if {[string equal -nocase $value true] || [string equal -nocase $value false]} {
        return [string tolower $value]
    }
    return "\"[string map [list "\\" "\\\\" "\"" "\\\"" "\n" "\\n" "\r" "\\r" "\t" "\\t"] $value]\""
}

proc ::attractor_web::__dot_graph_to_source {graph} {
    set graphId [dict get $graph id]
    set lines [list "digraph $graphId \{"]

    foreach nodeId [lsort [dict keys [dict get $graph nodes]]] {
        set attrs [dict get $graph nodes $nodeId attrs]
        if {[dict exists $attrs __implicit]} {
            dict unset attrs __implicit
        }
        set attrPairs {}
        foreach key [lsort [dict keys $attrs]] {
            lappend attrPairs "$key=[::attractor_web::__dot_attr_value [dict get $attrs $key]]"
        }
        if {[llength $attrPairs] == 0} {
            lappend lines "  $nodeId;"
        } else {
            lappend lines "  $nodeId \[[join $attrPairs {, }]\];"
        }
    }

    foreach edge [dict get $graph edges] {
        set attrs [dict get $edge attrs]
        set attrPairs {}
        foreach key [lsort [dict keys $attrs]] {
            lappend attrPairs "$key=[::attractor_web::__dot_attr_value [dict get $attrs $key]]"
        }
        if {[llength $attrPairs] == 0} {
            lappend lines "  [dict get $edge from] -> [dict get $edge to];"
        } else {
            lappend lines "  [dict get $edge from] -> [dict get $edge to] \[[join $attrPairs {, }]\];"
        }
    }

    lappend lines "\}"
    return [join $lines "\n"]
}

proc ::attractor_web::__dot_canonicalize_graph {graph} {
    set nodes [dict get $graph nodes]
    set edges [dict get $graph edges]
    set idMap {}
    set usedIds {}
    set fallbackSeq 0

    foreach oldId [lsort [dict keys $nodes]] {
        set base [::attractor_web::__dot_sanitize_id $oldId]
        if {$base eq ""} {
            set base "node_[incr fallbackSeq]"
        }
        set candidate $base
        set suffix 2
        while {[dict exists $usedIds $candidate]} {
            set candidate "${base}_$suffix"
            incr suffix
        }
        dict set usedIds $candidate 1
        dict set idMap $oldId $candidate
    }

    set newNodes {}
    foreach oldId [dict keys $nodes] {
        set newId [dict get $idMap $oldId]
        set attrs [dict get $nodes $oldId attrs]
        if {[dict exists $attrs __implicit]} {
            dict unset attrs __implicit
        }
        dict set newNodes $newId [dict create id $newId attrs $attrs]
    }

    set newEdges {}
    foreach edge $edges {
        if {![dict exists $idMap [dict get $edge from]] || ![dict exists $idMap [dict get $edge to]]} {
            continue
        }
        set fromId [dict get $idMap [dict get $edge from]]
        set toId [dict get $idMap [dict get $edge to]]
        lappend newEdges [dict create from $fromId to $toId attrs [dict get $edge attrs]]
    }

    set startNodes {}
    set exitNodes {}
    foreach nodeId [dict keys $newNodes] {
        set attrs [dict get $newNodes $nodeId attrs]
        if {[dict exists $attrs shape] && [dict get $attrs shape] eq "Mdiamond"} {
            lappend startNodes $nodeId
        }
        if {[dict exists $attrs shape] && [dict get $attrs shape] eq "Msquare"} {
            lappend exitNodes $nodeId
        }
    }

    if {[llength $startNodes] == 0} {
        set startId start
        set seq 2
        while {[dict exists $newNodes $startId]} {
            set startId "start_$seq"
            incr seq
        }
        dict set newNodes $startId [dict create id $startId attrs [dict create shape Mdiamond label Start]]
        lappend startNodes $startId
    }
    if {[llength $exitNodes] == 0} {
        set exitId exit
        set seq 2
        while {[dict exists $newNodes $exitId]} {
            set exitId "exit_$seq"
            incr seq
        }
        dict set newNodes $exitId [dict create id $exitId attrs [dict create shape Msquare label Exit]]
        lappend exitNodes $exitId
    }

    set keepStart [lindex $startNodes 0]
    set keepExit [lindex $exitNodes 0]

    foreach nodeId [lrange $startNodes 1 end] {
        set attrs [dict get $newNodes $nodeId attrs]
        if {[dict exists $attrs shape] && [dict get $attrs shape] eq "Mdiamond"} {
            dict unset attrs shape
        }
        dict set newNodes $nodeId attrs $attrs
    }
    foreach nodeId [lrange $exitNodes 1 end] {
        set attrs [dict get $newNodes $nodeId attrs]
        if {[dict exists $attrs shape] && [dict get $attrs shape] eq "Msquare"} {
            dict unset attrs shape
        }
        dict set newNodes $nodeId attrs $attrs
    }

    foreach nodeId [dict keys $newNodes] {
        if {$nodeId eq $keepStart || $nodeId eq $keepExit} {
            continue
        }
        set attrs [dict get $newNodes $nodeId attrs]
        if {![dict exists $attrs label] || [string trim [dict get $attrs label]] eq ""} {
            set defaultLabel [string map [list "_" " "] $nodeId]
            set defaultLabel [string trim [string totitle $defaultLabel]]
            if {$defaultLabel eq ""} {
                set defaultLabel $nodeId
            }
            dict set attrs label $defaultLabel
        }
        dict set newNodes $nodeId attrs $attrs
    }

    set filteredEdges {}
    foreach edge $newEdges {
        set fromId [dict get $edge from]
        set toId [dict get $edge to]
        if {$toId eq $keepStart} {
            continue
        }
        if {$fromId eq $keepExit} {
            continue
        }
        lappend filteredEdges $edge
    }

    set graphId [::attractor_web::__dot_sanitize_id [dict get $graph id]]
    if {$graphId eq ""} {
        set graphId Pipeline
    }

    return [dict create \
        id $graphId \
        graph_attrs [dict get $graph graph_attrs] \
        node_defaults [dict get $graph node_defaults] \
        edge_defaults [dict get $graph edge_defaults] \
        nodes $newNodes \
        edges $filteredEdges]
}

proc ::attractor_web::__dot_validate_result {dotSource} {
    set normalized [::attractor_web::normalize_dot_source $dotSource]
    if {[string trim $normalized] eq ""} {
        return [dict create valid 0 dot_source "" reason "DOT source is empty"]
    }

    if {[catch {set graph [::attractor::parse_dot $normalized]} parseErr]} {
        return [dict create valid 0 dot_source $normalized reason "parse error: $parseErr"]
    }

    set diagnostics [::attractor::validate $graph]
    if {[::attractor::__has_validation_errors $diagnostics]} {
        set canonical [::attractor_web::__dot_canonicalize_graph $graph]
        set canonicalDot [::attractor_web::__dot_graph_to_source $canonical]
        if {![catch {set canonicalGraph [::attractor::parse_dot $canonicalDot]}]} {
            set canonicalDiagnostics [::attractor::validate $canonicalGraph]
            if {![::attractor::__has_validation_errors $canonicalDiagnostics]} {
                return [dict create valid 1 dot_source $canonicalDot diagnostics $canonicalDiagnostics]
            }
        }
        set summary [::attractor_web::__dot_diagnostics_summary $diagnostics]
        return [dict create valid 0 dot_source $normalized reason "validation error(s):\n$summary" diagnostics $diagnostics]
    }

    set qualityErrors [::attractor_web::__dot_quality_errors $graph]
    if {[llength $qualityErrors] > 0} {
        set enforced [::attractor_web::__dot_enforce_quality_graph $graph]
        set enforcedDot [::attractor_web::__dot_graph_to_source $enforced]
        if {![catch {set enforcedGraph [::attractor::parse_dot $enforcedDot]}]} {
            set enforcedDiagnostics [::attractor::validate $enforcedGraph]
            if {![::attractor::__has_validation_errors $enforcedDiagnostics]} {
                set enforcedQualityErrors [::attractor_web::__dot_quality_errors $enforcedGraph]
                if {[llength $enforcedQualityErrors] == 0} {
                    return [dict create valid 1 dot_source $enforcedDot diagnostics $enforcedDiagnostics]
                }
            }
        }
        set summary [::attractor_web::__dot_quality_summary $qualityErrors]
        return [dict create valid 0 dot_source $normalized reason "semantic quality error(s):\n$summary" quality_errors $qualityErrors]
    }

    return [dict create valid 1 dot_source $normalized diagnostics $diagnostics]
}

proc ::attractor_web::__dot_repair_prompt {objectivePrompt invalidDot reason} {
    return "You previously returned Attractor DOT that failed strict parse/validation or semantic loop quality checks.\n\nOriginal objective:\n$objectivePrompt\n\nInvalid DOT:\n$invalidDot\n\nDetected failures:\n$reason\n\nRepair the DOT so it is syntactically valid Graphviz, passes Attractor validation rules, and includes a sensible iterative quality loop (plan -> implement -> validate -> review with success/retry/fail routes). Preserve the objective intent. Output ONLY raw DOT."
}

proc ::attractor_web::__extract_svg_markup {payload} {
    set text [string trim $payload]
    if {$text eq ""} {
        return ""
    }
    set lower [string tolower $text]
    set start [string first "<svg" $lower]
    if {$start < 0} {
        return ""
    }
    set end [string first "</svg>" $lower $start]
    if {$end < 0} {
        return ""
    }
    return [string trim [string range $text $start [expr {$end + 5}]]]
}

proc ::attractor_web::__env_nonempty {name} {
    return [expr {[info exists ::env($name)] && [string trim $::env($name)] ne ""}]
}

proc ::attractor_web::__dot_provider_default {} {
    if {[::attractor_web::__env_nonempty ATTRACTOR_DOT_PROVIDER]} {
        return [string tolower [string trim $::env(ATTRACTOR_DOT_PROVIDER)]]
    }
    if {[::attractor_web::__env_nonempty ATTRACTOR_PROVIDER]} {
        return [string tolower [string trim $::env(ATTRACTOR_PROVIDER)]]
    }
    if {[::attractor_web::__env_nonempty UNIFIED_LLM_PROVIDER]} {
        return [string tolower [string trim $::env(UNIFIED_LLM_PROVIDER)]]
    }
    return ""
}

proc ::attractor_web::__dot_model_default {provider} {
    switch -- $provider {
        openai {
            if {[::attractor_web::__env_nonempty OPENAI_MODEL]} {
                return [string trim $::env(OPENAI_MODEL)]
            }
            return gpt-5.2
        }
        anthropic {
            if {[::attractor_web::__env_nonempty ANTHROPIC_MODEL]} {
                return [string trim $::env(ANTHROPIC_MODEL)]
            }
            return claude-haiku-4-5
        }
        gemini {
            if {[::attractor_web::__env_nonempty GEMINI_MODEL]} {
                return [string trim $::env(GEMINI_MODEL)]
            }
            return gemini-3-flash-preview
        }
    }
    return ""
}

proc ::attractor_web::__graph_requires_llm {graphDict} {
    if {![dict exists $graphDict nodes]} {
        return 0
    }
    set startNode [::attractor::__find_start $graphDict]
    set exitNode [::attractor::__find_exit $graphDict]
    foreach nodeId [dict keys [dict get $graphDict nodes]] {
        set attrs [dict get $graphDict nodes $nodeId attrs]
        set handler [::attractor::__handler_from_node $nodeId $attrs $startNode $exitNode]
        if {$handler eq "codergen"} {
            return 1
        }
    }
    return 0
}

proc ::attractor_web::__provider_runtime_preflight {provider} {
    set probeRequest [dict create provider $provider]
    set baseUrl [::unified_llm::transports::https_json::__resolve_base_url $probeRequest]
    if {$baseUrl eq ""} {
        return -code error -errorcode [list ATTRACTOR_WEB RUNTIME_PREFLIGHT MISSING_BASE_URL] "no base URL configured for provider $provider"
    }

    if {![string match "https://*" [string tolower $baseUrl]]} {
        return
    }

    set preflight [::unified_llm::transports::https_json::runtime_preflight]
    if {[dict get $preflight tls_supported]} {
        return
    }

    set reason [dict get $preflight message]
    return -code error -errorcode [list ATTRACTOR_WEB RUNTIME_PREFLIGHT TLS_UNSUPPORTED] $reason
}

proc ::attractor_web::__dot_system_prompt {} {
    return {You write Attractor pipeline files in Graphviz DOT.

Output MUST be directly accepted by a strict parser.
Do not output markdown, explanations, comments, or code fences.
Output only raw DOT.

Hard constraints:
1. Start with `digraph Name {` and end with `}`.
2. Do NOT emit `graph [...]`, `node [...]`, `edge [...]`, `subgraph`, `rankdir`, or any global attributes.
3. Node IDs must match: `[A-Za-z_][A-Za-z0-9_]*` (no spaces, no hyphens).
4. Include exactly one start node: `start [shape=Mdiamond, label="Start"];`
5. Include exactly one exit node: `exit [shape=Msquare, label="Exit"];`
6. Every non-start/non-exit node must have a `label`.
7. Keep all nodes reachable from `start` and ensure a path to `exit`.
8. Use double quotes around attribute string values.
9. For tool stages, use `type=tool` and `tool_command="..."`.

Default workflow policy:
10. Prefer the smallest sensible workflow for the user objective.
11. For simple single-artifact prompts (for example: "draw a dog with svg"), use a compact loop:
    start -> draft_artifact -> verify_artifact -> (success -> exit, retry/fail -> draft_artifact).
12. Do NOT produce one-shot linear pipelines.
13. Include explicit outcome routes labeled/conditioned as `success` and `retry` (optionally `fail`).
14. Use `goal_gate=true` on the verify/review stage and set `retry_target` to the draft stage.
15. Only add extra stages (plan, tools, multiple validation passes, handoff stages) when the user prompt explicitly requires multi-step orchestration.
16. Avoid redundant nodes and duplicate validation/review phases for simple tasks.

Common shapes:
- `box` (default): LLM step
- `parallelogram`: tool step
- `hexagon`: wait.human step
- `diamond`: conditional router
- `component`: fan-out
- `tripleoctagon`: fan-in
- `house`: manager loop

Canonical minimal template:
digraph PipelineName {
  start [shape=Mdiamond, label="Start"];
  draft_artifact [label="Draft Artifact", prompt="Create the requested output artifact."];
  verify_artifact [label="Verify Artifact", goal_gate=true, retry_target="draft_artifact", prompt="Verify artifact quality against the objective; return success or retry."];
  exit [shape=Msquare, label="Exit"];
  start -> draft_artifact;
  draft_artifact -> verify_artifact;
  verify_artifact -> exit [condition="outcome=success", label="success"];
  verify_artifact -> draft_artifact [condition="outcome=retry", label="retry"];
  verify_artifact -> draft_artifact [condition="outcome=fail", label="fail"];
}}
}

proc ::attractor_web::__dot_generation_examples_prompt {} {
    set sampleDir [file normalize ~/src/swift-omnikit/sampleDOTs]
    set files [list \
        consensus_task_parity.dot \
        megaplan_quality.dot \
        semport.dot \
        vulnerability_analyzer.dot \
        consensus_task.dot \
        megaplan.dot \
        sprint_exec.dot]

    set blocks {}
    foreach name $files {
        set path [file join $sampleDir $name]
        if {![file exists $path]} {
            continue
        }
        if {[catch {set body [string trim [::attractor_web::__read_file $path]]}]} {
            continue
        }
        if {$body eq ""} {
            continue
        }
        lappend blocks "Example: $name\n```dot\n$body\n```"
    }

    if {[llength $blocks] == 0} {
        return ""
    }
    return "## Gold DOT Examples\nThe following are high-quality Attractor DOT files. Use them as style and structure references for generation.\n\n[join $blocks \"\n\n\"]"
}

proc ::attractor_web::__dot_stream_state_new {chan} {
    variable dot_stream_seq
    variable dot_stream_states
    incr dot_stream_seq
    set id "dot-stream-$dot_stream_seq"
    dict set dot_stream_states $id [dict create chan $chan text "" error ""]
    return $id
}

proc ::attractor_web::__dot_stream_state_take {id} {
    variable dot_stream_states
    if {![dict exists $dot_stream_states $id]} {
        return [dict create text "" error "stream state not found"]
    }
    set state [dict get $dot_stream_states $id]
    dict unset dot_stream_states $id
    return $state
}

proc ::attractor_web::__dot_stream_event {id event} {
    variable dot_stream_states
    if {![dict exists $dot_stream_states $id]} {
        return
    }
    set state [dict get $dot_stream_states $id]
    set eventType [dict get $event type]
    if {$eventType eq "TEXT_DELTA"} {
        if {![dict exists $event delta]} {
            return
        }
        set delta [dict get $event delta]
        dict set state text "[dict get $state text]$delta"
        set chan [dict get $state chan]
        catch {
            ::attractor_web::__send_sse_data $chan "{\"delta\":[::attractor_web::__json_quote $delta]}"
        }
        dict set dot_stream_states $id $state
        return
    }

    if {$eventType eq "ERROR"} {
        set message "provider stream error"
        if {[dict exists $event error message] && [string trim [dict get $event error message]] ne ""} {
            set message [dict get $event error message]
        } elseif {[dict exists $event error] && [string trim [dict get $event error]] ne ""} {
            set message [dict get $event error]
        }
        dict set state error $message
        dict set dot_stream_states $id $state
        return
    }

    if {$eventType eq "FINISH"} {
        if {[dict get $state text] eq "" && [dict exists $event response text]} {
            dict set state text [dict get $event response text]
            dict set dot_stream_states $id $state
        }
    }
}

proc ::attractor_web::__dot_client_from_state {state} {
    if {[dict exists $state dot_llm_client]} {
        set client [dict get $state dot_llm_client]
        if {$client ne "" && [llength [info commands $client]] > 0} {
            return [list $client 0]
        }
    }

    return [list [::unified_llm::from_env -transport ::unified_llm::transports::https_json::call] 1]
}

proc ::attractor_web::__dot_build_request {state payload userPrompt client mode} {
    set provider ""
    if {[dict exists $state dot_llm_provider] && [string trim [dict get $state dot_llm_provider]] ne ""} {
        set provider [string tolower [string trim [dict get $state dot_llm_provider]]]
    } else {
        set provider [::attractor_web::__dot_provider_default]
    }
    if {[dict exists $payload provider] && [string trim [dict get $payload provider]] ne ""} {
        set provider [string tolower [string trim [dict get $payload provider]]]
    }

    if {$provider eq ""} {
        set config [$client config]
        if {[dict exists $config default_provider]} {
            set provider [dict get $config default_provider]
        }
    }
    if {$provider ni {openai anthropic gemini}} {
        return -code error -errorcode [list ATTRACTOR_WEB BAD_REQUEST] "provider must be one of openai, anthropic, gemini"
    }

    set model ""
    if {[dict exists $state dot_llm_model] && [string trim [dict get $state dot_llm_model]] ne ""} {
        set model [string trim [dict get $state dot_llm_model]]
    } else {
        set model [::attractor_web::__dot_model_default $provider]
    }
    if {[dict exists $payload model] && [string trim [dict get $payload model]] ne ""} {
        set model [string trim [dict get $payload model]]
    }

    set providerOptions {}
    if {[dict exists $payload provider_options]} {
        set providerOptions [dict get $payload provider_options]
    }

    set systemPrompt [::attractor_web::__dot_system_prompt]
    if {$mode eq "generate"} {
        set examplesPrompt [::attractor_web::__dot_generation_examples_prompt]
        if {$examplesPrompt ne ""} {
            append systemPrompt "\n\n" $examplesPrompt
        }
    }

    set messages [list \
        [::unified_llm::message system $systemPrompt] \
        [::unified_llm::message user $userPrompt]]
    set args [list -client $client -provider $provider -messages $messages -model $model -provider_options $providerOptions]
    return $args
}

proc ::attractor_web::__dot_user_prompt {mode payload} {
    switch -- $mode {
        generate {
            if {![dict exists $payload prompt] || [string trim [dict get $payload prompt]] eq ""} {
                return -code error -errorcode [list ATTRACTOR_WEB BAD_REQUEST] "prompt is required"
            }
            set prompt [string trim [dict get $payload prompt]]
            append prompt "\n\nMandatory workflow requirements:\n"
            append prompt "- Use the smallest sensible loop for the task.\n"
            append prompt "- For simple single-output tasks, prefer: draft -> verify -> (retry back to draft) -> success exit.\n"
            append prompt "- Avoid extra phases unless the prompt clearly requires complex orchestration.\n"
            append prompt "- Include explicit labeled outcome routes: success and retry (optional fail).\n"
            append prompt "- The draft stage prompt must directly encode the user task objective.\n"
            append prompt "- Output ONLY valid raw DOT."
            return $prompt
        }
        fix {
            if {![dict exists $payload dotSource] || [string trim [dict get $payload dotSource]] eq ""} {
                return -code error -errorcode [list ATTRACTOR_WEB BAD_REQUEST] "dotSource is required"
            }
            if {![dict exists $payload error] || [string trim [dict get $payload error]] eq ""} {
                return -code error -errorcode [list ATTRACTOR_WEB BAD_REQUEST] "error is required"
            }
            set broken [::attractor_web::normalize_dot_source [dict get $payload dotSource]]
            set errText [string trim [dict get $payload error]]
            return "The following Graphviz DOT pipeline has a syntax error. Fix it so it renders correctly.\n\nGraphviz error:\n$errText\n\nBroken DOT source:\n$broken\n\nOutput ONLY the corrected raw DOT source - no markdown fences, no explanations."
        }
        iterate {
            if {![dict exists $payload baseDot] || [string trim [dict get $payload baseDot]] eq ""} {
                return -code error -errorcode [list ATTRACTOR_WEB BAD_REQUEST] "baseDot is required"
            }
            if {![dict exists $payload changes] || [string trim [dict get $payload changes]] eq ""} {
                return -code error -errorcode [list ATTRACTOR_WEB BAD_REQUEST] "changes is required"
            }
            set baseDot [::attractor_web::normalize_dot_source [dict get $payload baseDot]]
            set changes [string trim [dict get $payload changes]]
            return "Given the following existing Attractor pipeline DOT source:\n\n$baseDot\n\nModify it according to these instructions: $changes\n\nOutput ONLY the modified raw DOT source - no markdown fences, no explanations.\nKeep all existing nodes and edges unless explicitly told to remove them."
        }
        default {
            return -code error -errorcode [list ATTRACTOR_WEB BAD_REQUEST] "unknown dot stream mode: $mode"
        }
    }
}

proc ::attractor_web::__chunk_text {text chunkSize} {
    if {$text eq ""} {
        return {}
    }
    if {$chunkSize < 1} {
        set chunkSize 1
    }
    set out {}
    for {set idx 0} {$idx < [string length $text]} {incr idx $chunkSize} {
        lappend out [string range $text $idx [expr {$idx + $chunkSize - 1}]]
    }
    return $out
}

proc ::attractor_web::__dot_stream_generate {state payload mode chan} {
    set userPrompt [::attractor_web::__dot_user_prompt $mode $payload]
    lassign [::attractor_web::__dot_client_from_state $state] client isTemp

    set code [catch {
        set dotSource ""
        set workingPrompt $userPrompt
        set attempt 0
        set maxAttempts 4
        while {$attempt < $maxAttempts} {
            incr attempt
            set requestArgs [::attractor_web::__dot_build_request $state $payload $workingPrompt $client $mode]
            set response [::unified_llm::generate {*}$requestArgs -max_tool_rounds 0]

            set text ""
            if {[dict exists $response text]} {
                set text [dict get $response text]
            }

            set validation [::attractor_web::__dot_validate_result $text]
            if {[dict get $validation valid]} {
                set dotSource [dict get $validation dot_source]
                break
            }

            if {$attempt >= $maxAttempts} {
                set reason [dict get $validation reason]
                return -code error -errorcode [list ATTRACTOR_WEB GENERATION_ERROR INVALID_DOT] "model returned invalid DOT after $maxAttempts attempts: $reason"
            }

            set candidate [dict get $validation dot_source]
            if {[string trim $candidate] eq ""} {
                set candidate [::attractor_web::normalize_dot_source $text]
            }
            set reason [dict get $validation reason]
            set workingPrompt [::attractor_web::__dot_repair_prompt $userPrompt $candidate $reason]
        }
    } err opts]

    if {$isTemp} {
        catch {$client close}
    }
    if {$code} {
        return -options $opts $err
    }

    if {[string trim $dotSource] eq ""} {
        return -code error -errorcode [list ATTRACTOR_WEB GENERATION_ERROR] "model returned empty DOT source"
    }

    foreach chunk [::attractor_web::__chunk_text $dotSource 64] {
        ::attractor_web::__send_sse_data $chan "{\"delta\":[::attractor_web::__json_quote $chunk]}"
    }
    return $dotSource
}

proc ::attractor_web::__html_dashboard {} {
    return {<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Attractor Dashboard</title>
  <style>
    :root {
      color-scheme: light;
      --bg-a: #f7fbff;
      --bg-b: #eff6f1;
      --surface: #ffffff;
      --line: #d5e3d7;
      --ink: #173126;
      --ink-muted: #577266;
      --accent: #14593d;
      --accent-soft: #d4eadf;
      --danger: #a32121;
      --danger-soft: #ffe8e8;
      --code-bg: #0d1d16;
      --code-ink: #d7f7e9;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Avenir Next", "IBM Plex Sans", "Segoe UI", sans-serif;
      color: var(--ink);
      background:
        radial-gradient(1400px 520px at 8% -15%, #dff0ff 0%, transparent 65%),
        radial-gradient(1200px 520px at 100% -10%, #dbf3e3 0%, transparent 62%),
        linear-gradient(145deg, var(--bg-a), var(--bg-b));
    }
    header {
      position: sticky;
      top: 0;
      z-index: 10;
      padding: 14px 18px;
      background: linear-gradient(90deg, #0f4331, #14553b);
      color: #f4fff7;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid #0d3d2b;
    }
    .brand-title { font-weight: 700; letter-spacing: 0.2px; }
    .brand-sub { font-size: 12px; opacity: 0.86; margin-top: 2px; }
    .header-right { display: flex; align-items: center; gap: 8px; }
    .indicator {
      font-size: 12px;
      padding: 5px 10px;
      border-radius: 999px;
      background: #1e6f4d;
      border: 1px solid #2e8b63;
    }
    .indicator.offline { background: #762a2a; border-color: #934040; }
    .activity {
      font-size: 12px;
      padding: 5px 10px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.13);
      border: 1px solid rgba(255, 255, 255, 0.2);
    }
    .activity.busy { background: #f3d58b; border-color: #ebc067; color: #3b2a00; }
    .activity.error { background: #f6c6c6; border-color: #e39494; color: #5f1515; }
    .activity.ok { background: #b9e5cb; border-color: #8fcdaa; color: #103726; }
    main {
      display: grid;
      grid-template-columns: 376px 1fr;
      min-height: calc(100vh - 62px);
      gap: 14px;
      padding: 14px;
    }
    aside, section { overflow: auto; }
    .panel {
      background: var(--surface);
      border: 1px solid var(--line);
      border-radius: 14px;
      padding: 12px;
      margin-bottom: 12px;
      box-shadow: 0 8px 24px rgba(18, 40, 30, 0.05);
    }
    h3 { margin: 0 0 10px 0; }
    h4 { margin: 14px 0 8px 0; }
    .label {
      margin: 2px 0 6px 1px;
      font-size: 12px;
      font-weight: 600;
      color: var(--ink-muted);
      text-transform: uppercase;
      letter-spacing: 0.45px;
    }
    textarea, input, select {
      width: 100%;
      border: 1px solid #c8d7cc;
      border-radius: 10px;
      background: #fbfefd;
      color: var(--ink);
      padding: 8px 9px;
      font: inherit;
      line-height: 1.35;
    }
    textarea { min-height: 144px; resize: vertical; }
    textarea.small { min-height: 78px; }
    .row { display: flex; gap: 8px; margin: 8px 0; align-items: center; }
    .grow { flex: 1; }
    button {
      border: 1px solid #b8cfc0;
      background: #f4fbf7;
      color: #103226;
      border-radius: 10px;
      padding: 7px 11px;
      font-weight: 600;
      cursor: pointer;
      transition: background 120ms ease, transform 120ms ease;
    }
    button:hover { background: #e8f6ee; transform: translateY(-1px); }
    button:disabled { opacity: 0.58; cursor: not-allowed; transform: none; }
    button.loading {
      background: #d3ecdf;
      border-color: #96c7ad;
      position: relative;
      padding-left: 27px;
    }
    button.loading::before {
      content: "";
      position: absolute;
      left: 10px;
      top: 50%;
      width: 11px;
      height: 11px;
      margin-top: -6px;
      border: 2px solid #2f7658;
      border-top-color: transparent;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    #generateBtn, #runBtn, #previewBtn { background: #def4e7; border-color: #9dcfb2; }
    #generateBtn:hover, #runBtn:hover, #previewBtn:hover { background: #d0eedf; }
    .hint { color: var(--ink-muted); font-size: 12px; margin: 6px 0 2px 1px; }
    .stream-status { min-height: 16px; margin: 2px 1px 8px; transition: color 120ms ease; }
    .stream-status.active { color: #14593d; }
    .stream-status.error { color: #8e2222; }
    .stream-status.ok { color: #0f5135; }
    .workflow { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 10px; }
    .step {
      font-size: 12px;
      border: 1px solid #cad9ce;
      border-radius: 999px;
      padding: 5px 10px;
      background: #f7fbf8;
      color: #557166;
    }
    .step.active { background: var(--accent); color: #f5fff9; border-color: var(--accent); }
    .step.done { background: var(--accent-soft); color: #0f4630; border-color: #9dcdb4; }
    .run {
      border: 1px solid #cadccf;
      padding: 10px;
      border-radius: 10px;
      margin-bottom: 8px;
      background: #fff;
      cursor: pointer;
    }
    .run.active { border-color: #1b6c4e; box-shadow: 0 0 0 2px #d6ebdf; }
    .status { font-weight: 700; }
    .meta { color: var(--ink-muted); font-size: 12px; }
    #graph {
      min-height: 230px;
      border: 1px solid var(--line);
      border-radius: 12px;
      background:
        linear-gradient(45deg, rgba(190, 214, 201, 0.12) 25%, transparent 25%),
        linear-gradient(-45deg, rgba(190, 214, 201, 0.12) 25%, transparent 25%),
        linear-gradient(45deg, transparent 75%, rgba(190, 214, 201, 0.12) 75%),
        linear-gradient(-45deg, transparent 75%, rgba(190, 214, 201, 0.12) 75%);
      background-size: 20px 20px;
      background-position: 0 0, 0 10px, 10px -10px, -10px 0;
      padding: 10px;
      display: flex;
      align-items: flex-start;
      overflow: auto;
    }
    #graph svg { width: min(560px, 100%); height: auto; display: block; }
    #summary {
      background: #fff;
      border: 1px solid var(--line);
      border-radius: 10px;
      padding: 10px;
      margin-bottom: 8px;
      white-space: pre-wrap;
      color: var(--ink);
    }
    pre {
      background: var(--code-bg);
      color: var(--code-ink);
      padding: 12px;
      border-radius: 10px;
      overflow: auto;
      min-height: 60px;
      max-height: 240px;
      white-space: pre-wrap;
      word-break: break-word;
    }
    .question { border: 1px solid #f5d06f; background: #fff9ea; padding: 10px; border-radius: 10px; margin: 8px 0; }
    .error { color: var(--danger); font-weight: 600; margin: 8px 2px 2px; }
    .error-meta {
      margin: 2px 2px 8px;
      border-left: 3px solid #e68f8f;
      padding: 6px 8px;
      border-radius: 4px;
      background: var(--danger-soft);
      color: #682020;
      font-size: 12px;
      white-space: pre-wrap;
      display: none;
    }
    @media (max-width: 1080px) {
      main { grid-template-columns: 1fr; }
      aside { order: 2; }
      section { order: 1; }
      header { position: static; }
    }
    @keyframes spin {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <header>
    <div>
      <div class="brand-title">Attractor Web Dashboard</div>
      <div class="brand-sub">Prompt -> DOT -> Preview -> Run</div>
    </div>
    <div class="header-right">
      <div id="conn" class="indicator offline">SSE offline</div>
      <div id="activity" class="activity">Idle</div>
    </div>
  </header>
  <main>
    <aside>
      <div class="panel">
        <h3>Compose</h3>
        <div class="label">Prompt</div>
        <textarea id="dotPrompt" class="small" placeholder="Describe the pipeline you want"></textarea>
        <div class="row">
          <select id="provider">
            <option value="">auto provider</option>
            <option value="openai">openai</option>
            <option value="anthropic">anthropic</option>
            <option value="gemini">gemini</option>
          </select>
          <input id="model" class="grow" placeholder="optional model override">
        </div>
        <div class="row">
          <button id="generateBtn">Generate DOT</button>
          <button id="previewBtn">Preview DOT</button>
        </div>
        <div id="streamStatus" class="hint stream-status">Ready</div>
        <div class="row">
          <input id="dotfile" class="grow" type="file" accept=".dot,text/plain">
        </div>

        <div class="label">DOT Source</div>
        <textarea id="dot" placeholder="Paste DOT source"></textarea>

        <div class="label">Iterate DOT</div>
        <textarea id="dotChanges" class="small" placeholder="Describe what should change in the graph"></textarea>
        <div class="row">
          <button id="iterateBtn">Iterate DOT</button>
        </div>
        <div class="label">Fix DOT</div>
        <textarea id="dotFixErr" class="small" placeholder="Paste Graphviz or validation errors to guide fixes"></textarea>
        <div class="row">
          <button id="fixBtn">Fix DOT</button>
          <button id="runBtn">Run</button>
          <button id="refreshBtn">Refresh</button>
        </div>
        <p class="hint">Tip: edit DOT directly and press Preview for instant validation feedback.</p>
        <div id="runErr" class="error"></div>
        <div id="runErrMeta" class="error-meta"></div>
      </div>

      <div class="panel">
        <h3>Runs</h3>
        <div id="runs"></div>
      </div>
    </aside>
    <section>
      <div id="workflow" class="workflow">
        <div class="step active" data-step="prompt">1 Prompt</div>
        <div class="step" data-step="generate">2 Generate</div>
        <div class="step" data-step="preview">3 Preview</div>
        <div class="step" data-step="iterate">4 Iterate</div>
        <div class="step" data-step="run">5 Run</div>
      </div>
      <h3 id="title">Select a run</h3>
      <div id="summary"></div>
      <div id="questions"></div>
      <h4>Rendered Graph</h4>
      <div id="graph"></div>
      <h4>Stage Artifact</h4>
      <pre id="stage">(none)</pre>
      <h4>Run Events</h4>
      <pre id="events">(none)</pre>
    </section>
  </main>
  <script>
    const state = {
      runs: [],
      selected: null,
      fileName: '',
      eventSource: null,
      runEventSource: null,
      runEvents: [],
      previewReq: 0,
      previewTimer: null,
      busy: false
    };

    function setConn(ok) {
      const el = document.getElementById('conn');
      el.classList.toggle('offline', !ok);
      el.textContent = ok ? 'SSE online' : 'SSE offline';
    }

    function setActivity(message) {
      const el = document.getElementById('activity');
      el.textContent = message || 'Idle';
      el.classList.remove('busy', 'error', 'ok');
    }

    function setActivityTone(tone) {
      const el = document.getElementById('activity');
      el.classList.remove('busy', 'error', 'ok');
      if (tone) {
        el.classList.add(tone);
      }
    }

    function setWorkflow(stepName) {
      const order = ['prompt', 'generate', 'preview', 'iterate', 'run'];
      const idx = order.indexOf(stepName);
      const steps = document.querySelectorAll('#workflow .step');
      steps.forEach((el) => {
        const cur = order.indexOf(el.getAttribute('data-step'));
        el.classList.remove('active', 'done');
        if (cur < idx) el.classList.add('done');
        if (cur === idx) el.classList.add('active');
      });
    }

    function setBusy(isBusy) {
      state.busy = isBusy;
      const ids = ['generateBtn', 'previewBtn', 'iterateBtn', 'fixBtn', 'runBtn', 'refreshBtn'];
      for (const id of ids) {
        const el = document.getElementById(id);
        if (el) el.disabled = isBusy;
      }
    }

    function setButtonLoading(id, enabled, label) {
      const el = document.getElementById(id);
      if (!el) return;
      if (enabled) {
        if (!el.dataset.baseLabel) {
          el.dataset.baseLabel = el.textContent;
        }
        el.textContent = label || el.dataset.baseLabel;
        el.classList.add('loading');
        el.setAttribute('aria-busy', 'true');
      } else {
        if (el.dataset.baseLabel) {
          el.textContent = el.dataset.baseLabel;
        }
        el.classList.remove('loading');
        el.removeAttribute('aria-busy');
      }
    }

    function showStreamStatus(message, tone) {
      const el = document.getElementById('streamStatus');
      el.textContent = message || 'Ready';
      el.classList.remove('active', 'error', 'ok');
      if (tone) {
        el.classList.add(tone);
      }
    }

    function showGraphMessage(message) {
      const graph = document.getElementById('graph');
      graph.innerHTML = '';
      graph.textContent = message || '';
    }

    function formatDiagnostics(details) {
      if (!details || !Array.isArray(details.diagnostics) || details.diagnostics.length === 0) {
        if (typeof details === 'string') return details;
        if (details && typeof details.error === 'string') return details.error;
        if (details && details.error && typeof details.error === 'object') return JSON.stringify(details.error, null, 2);
        return '';
      }
      const lines = [];
      for (const d of details.diagnostics.slice(0, 6)) {
        const sev = d && d.severity ? `[${d.severity}] ` : '';
        const rule = d && d.rule ? `${d.rule}: ` : '';
        const msg = d && d.message ? d.message : JSON.stringify(d);
        lines.push(`${sev}${rule}${msg}`);
      }
      return lines.join('\n');
    }

    function showError(msg, details) {
      const text = msg || '';
      document.getElementById('runErr').textContent = text;
      const meta = document.getElementById('runErrMeta');
      const diag = formatDiagnostics(details);
      if (diag) {
        meta.style.display = 'block';
        meta.textContent = diag;
      } else {
        meta.style.display = 'none';
        meta.textContent = '';
      }
    }

    function extractSvgMarkup(value) {
      const text = (value || '').trim();
      const start = text.search(/<svg[\s>]/i);
      if (start < 0) return '';
      const endMatch = text.slice(start).match(/<\/svg>/i);
      if (!endMatch) return '';
      return text.slice(start, start + endMatch.index + endMatch[0].length);
    }

    async function renderGraphFromDot(dotSource, opts) {
      const options = opts || {};
      const quiet = Boolean(options.quiet);
      const reqId = ++state.previewReq;
      const graph = document.getElementById('graph');

      if (!dotSource || !dotSource.trim()) {
        if (!quiet) {
          showGraphMessage('(DOT source is empty)');
        }
        return;
      }

      try {
        if (!quiet) setActivity('Rendering graph preview');
        if (!quiet) setActivityTone('busy');
        const rendered = await api('/api/render', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ dotSource })
        });
        if (reqId !== state.previewReq) return;
        const svg = extractSvgMarkup(rendered.svg || '');
        if (!svg) {
          throw new Error('DOT_RENDER_INVALID_OUTPUT: renderer returned non-SVG output');
        }
        graph.innerHTML = svg;
        if (!quiet) {
          setActivity('Preview updated');
          setActivityTone('ok');
        }
      } catch (err) {
        if (reqId !== state.previewReq) return;
        showGraphMessage(err.message);
        if (!quiet) {
          showError(err.message, err.details);
          setActivity('Preview failed');
          setActivityTone('error');
        }
      }
    }

    async function previewDot(opts) {
      if (state.previewTimer) {
        clearTimeout(state.previewTimer);
        state.previewTimer = null;
      }
      showError('');
      setWorkflow('preview');
      const quiet = Boolean(opts && opts.quiet);
      if (!quiet) {
        showStreamStatus('Rendering preview...', 'active');
      }
      await renderGraphFromDot(document.getElementById('dot').value, opts);
      if (!quiet) {
        showStreamStatus('Preview updated', 'ok');
      }
    }

    function schedulePreview() {
      if (state.previewTimer) clearTimeout(state.previewTimer);
      showStreamStatus('DOT changed. Preview pending...', 'active');
      showGraphMessage('Preview pending...');
      state.previewTimer = setTimeout(() => {
        state.previewTimer = null;
        previewDot({ quiet: true });
        showStreamStatus('Ready');
      }, 420);
    }

    async function api(path, opts) {
      const res = await fetch(path, opts);
      const ct = res.headers.get('content-type') || '';
      const body = ct.includes('application/json') ? await res.json() : await res.text();
      if (!res.ok) {
        const msg = body && body.error ? `${body.code || 'ERROR'}: ${body.error}` : `HTTP ${res.status}`;
        const err = new Error(msg);
        err.details = body;
        throw err;
      }
      return body;
    }

    function dotOptions() {
      const provider = document.getElementById('provider').value.trim();
      const model = document.getElementById('model').value.trim();
      const out = {};
      if (provider) out.provider = provider;
      if (model) out.model = model;
      return out;
    }

    function runSummaryText(run) {
      const web = run.web || {};
      const worker = run.worker_result || {};
      const reason = run.reason || worker.reason || '';
      const lines = [
        `Status: ${run.status || '-'}`,
        `Current Node: ${run.current_node || '-'}`,
        `Run ID: ${run.id || web.run_id || '-'}`,
        `Provider: ${web.provider || 'default'}`,
        `Model: ${web.model || 'default'}`
      ];
      if (reason) lines.push(`Reason: ${reason}`);
      if (worker.ended_at) lines.push(`Ended: ${worker.ended_at}`);
      if (worker.error) {
        const rawError = typeof worker.error === 'string' ? worker.error : JSON.stringify(worker.error);
        lines.push(`Error: ${rawError.length > 320 ? `${rawError.slice(0, 320)}...` : rawError}`);
      }
      return lines.join('\n');
    }

    function parseSseFramesChunk(chunk, onEvent) {
      const frame = chunk.trim();
      if (!frame) return;
      const lines = frame.split('\n');
      const payload = [];
      for (const line of lines) {
        if (line.startsWith('data:')) payload.push(line.slice(5).trimStart());
      }
      if (!payload.length) return;
      try {
        onEvent(JSON.parse(payload.join('\n')));
      } catch (_) {}
    }

    async function readSseJsonFrames(response, onEvent) {
      const parseText = (text) => {
        const normalized = (text || '').replace(/\r\n/g, '\n').replace(/\r/g, '\n');
        const frames = normalized.split('\n\n');
        for (const frame of frames) {
          parseSseFramesChunk(frame, onEvent);
        }
      };

      if (!response.body || !response.body.getReader) {
        parseText(await response.text());
        return;
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        buffer = buffer.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
        while (true) {
          const sep = buffer.indexOf('\n\n');
          if (sep < 0) break;
          const frame = buffer.slice(0, sep);
          buffer = buffer.slice(sep + 2);
          parseSseFramesChunk(frame, onEvent);
        }
      }
      if (buffer.trim()) {
        parseSseFramesChunk(buffer, onEvent);
      }
    }

    async function streamDot(path, payload, onDelta) {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 150000);
      const res = await fetch(path, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'text/event-stream' },
        body: JSON.stringify(payload),
        signal: controller.signal
      }).finally(() => clearTimeout(timeoutId));
      if (!res.ok) {
        const text = await res.text();
        let parsed = null;
        try {
          parsed = JSON.parse(text);
        } catch (_) {}
        if (parsed && parsed.error) {
          throw new Error(`${parsed.code || 'ERROR'}: ${parsed.error}`);
        }
        throw new Error(`HTTP ${res.status}`);
      }

      let doneDot = '';
      let streamErr = '';
      let deltaCount = 0;
      let deltaChars = 0;
      await readSseJsonFrames(res, (evt) => {
        if (typeof evt.delta === 'string') {
          deltaCount += 1;
          deltaChars += evt.delta.length;
          showStreamStatus(`Receiving model output: ${deltaChars} chars`, 'active');
          onDelta(evt.delta);
        } else if (evt.done && typeof evt.dotSource === 'string') {
          doneDot = evt.dotSource;
          showStreamStatus(`Generation complete (${deltaCount} chunks)`, 'ok');
        } else if (evt.error) {
          streamErr = evt.error;
          showStreamStatus(`Generation error: ${evt.error}`, 'error');
        }
      });

      if (streamErr) throw new Error(streamErr);
      if (!doneDot) throw new Error('stream ended without done event');
      return doneDot;
    }

    async function generateDot() {
      showError('');
      setWorkflow('generate');
      const prompt = document.getElementById('dotPrompt').value.trim();
      if (!prompt) {
        showError('Prompt is required for DOT generation');
        showStreamStatus('Enter a prompt before generating', 'error');
        setActivity('Prompt required');
        setActivityTone('error');
        document.getElementById('dotPrompt').focus();
        return;
      }
      const dotEl = document.getElementById('dot');
      dotEl.value = '';
      setBusy(true);
      setActivity('Generating DOT');
      setActivityTone('busy');
      showStreamStatus('Submitting generation request...', 'active');
      showGraphMessage('Generating DOT...');
      setButtonLoading('generateBtn', true, 'Generating...');
      try {
        const finalDot = await streamDot('/api/v1/dot/generate/stream', { prompt, ...dotOptions() }, (delta) => {
          dotEl.value += delta;
        });
        dotEl.value = finalDot;
        await previewDot({ quiet: true });
        setActivity('DOT generated');
        setActivityTone('ok');
        showStreamStatus('DOT generated successfully', 'ok');
      } catch (err) {
        showError(err.message, err.details);
        setActivity('Generation failed');
        setActivityTone('error');
        showStreamStatus('Generation failed', 'error');
      } finally {
        setButtonLoading('generateBtn', false);
        setBusy(false);
      }
    }

    async function fixDot() {
      showError('');
      setWorkflow('iterate');
      const dotSource = document.getElementById('dot').value;
      const error = document.getElementById('dotFixErr').value.trim();
      if (!dotSource.trim()) {
        showError('DOT source is required for Fix');
        showStreamStatus('DOT source is required for Fix', 'error');
        return;
      }
      if (!error) {
        showError('Fix error text is required');
        showStreamStatus('Fix error text is required', 'error');
        return;
      }
      const dotEl = document.getElementById('dot');
      dotEl.value = '';
      setBusy(true);
      setActivity('Fixing DOT');
      setActivityTone('busy');
      showStreamStatus('Submitting fix request...', 'active');
      showGraphMessage('Fixing DOT...');
      setButtonLoading('fixBtn', true, 'Fixing...');
      try {
        const finalDot = await streamDot('/api/v1/dot/fix/stream', { dotSource, error, ...dotOptions() }, (delta) => {
          dotEl.value += delta;
        });
        dotEl.value = finalDot;
        await previewDot({ quiet: true });
        setActivity('DOT fixed');
        setActivityTone('ok');
        showStreamStatus('DOT fixed successfully', 'ok');
      } catch (err) {
        showError(err.message, err.details);
        setActivity('Fix failed');
        setActivityTone('error');
        showStreamStatus('Fix failed', 'error');
      } finally {
        setButtonLoading('fixBtn', false);
        setBusy(false);
      }
    }

    async function iterateDot() {
      showError('');
      setWorkflow('iterate');
      const baseDot = document.getElementById('dot').value;
      const changes = document.getElementById('dotChanges').value.trim();
      if (!baseDot.trim()) {
        showError('DOT source is required for Iterate');
        showStreamStatus('DOT source is required for Iterate', 'error');
        return;
      }
      if (!changes) {
        showError('Iterate changes are required');
        showStreamStatus('Iterate changes are required', 'error');
        return;
      }
      const dotEl = document.getElementById('dot');
      dotEl.value = '';
      setBusy(true);
      setActivity('Iterating DOT');
      setActivityTone('busy');
      showStreamStatus('Submitting iterate request...', 'active');
      showGraphMessage('Iterating DOT...');
      setButtonLoading('iterateBtn', true, 'Iterating...');
      try {
        const finalDot = await streamDot('/api/v1/dot/iterate/stream', { baseDot, changes, ...dotOptions() }, (delta) => {
          dotEl.value += delta;
        });
        dotEl.value = finalDot;
        await previewDot({ quiet: true });
        setActivity('DOT updated');
        setActivityTone('ok');
        showStreamStatus('DOT iterated successfully', 'ok');
      } catch (err) {
        showError(err.message, err.details);
        setActivity('Iterate failed');
        setActivityTone('error');
        showStreamStatus('Iterate failed', 'error');
      } finally {
        setButtonLoading('iterateBtn', false);
        setBusy(false);
      }
    }

    function renderRuns() {
      const wrap = document.getElementById('runs');
      wrap.innerHTML = '';
      if (!state.runs.length) {
        wrap.innerHTML = '<div class="meta">No runs yet. Generate or paste DOT and click Run.</div>';
        return;
      }
      for (const run of state.runs) {
        const el = document.createElement('div');
        el.className = `run${state.selected === run.id ? ' active' : ''}`;
        const reason = run.reason ? ` reason=${run.reason}` : '';
        el.innerHTML = `<div><strong>${run.id}</strong></div><div class="status">${run.status}</div><div class="meta">node=${run.current_node || '-'} completed=${run.completed_nodes_count || 0}${reason}</div>`;
        el.onclick = () => selectRun(run.id);
        wrap.appendChild(el);
      }
    }

    async function refreshRuns() {
      try {
        state.runs = await api('/api/pipelines');
        renderRuns();
        if (state.selected && !state.runs.find(r => r.id === state.selected)) {
          state.selected = null;
        }
        if (state.selected) {
          await loadRun(state.selected);
        }
      } catch (err) {
        showError(err.message, err.details);
      }
    }

    async function startRun() {
      showError('');
      setWorkflow('run');
      setBusy(true);
      setActivity('Starting run');
      setActivityTone('busy');
      setButtonLoading('runBtn', true, 'Starting...');
      try {
        const payload = { dotSource: document.getElementById('dot').value };
        const opts = dotOptions();
        if (opts.provider) payload.provider = opts.provider;
        if (opts.model) payload.model = opts.model;
        if (state.fileName) payload.fileName = state.fileName;
        const out = await api('/api/run', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        await refreshRuns();
        await selectRun(out.id);
        setActivity('Run started');
        setActivityTone('ok');
        showStreamStatus('Run started successfully', 'ok');
      } catch (err) {
        showError(err.message, err.details);
        if (err.details && err.details.code === 'INVALID_DOT_SOURCE') {
          const diagnosticText = formatDiagnostics(err.details);
          if (diagnosticText) {
            document.getElementById('dotFixErr').value = diagnosticText;
          }
        }
        setActivity('Run failed');
        setActivityTone('error');
        showStreamStatus('Run failed', 'error');
      } finally {
        setButtonLoading('runBtn', false);
        setBusy(false);
      }
    }

    async function loadRun(runId) {
      const run = await api(`/api/pipeline?id=${encodeURIComponent(runId)}`);
      document.getElementById('title').textContent = `Run ${run.id}`;
      document.getElementById('summary').textContent = runSummaryText(run);
      setWorkflow('run');

      await renderGraphFromDot(run.dotSource, { quiet: true });

      const qWrap = document.getElementById('questions');
      qWrap.innerHTML = '';
      for (const q of (run.pending_questions || [])) {
        const node = document.createElement('div');
        node.className = 'question';
        node.innerHTML = `<div><strong>${q.question}</strong></div>`;
        const row = document.createElement('div');
        row.className = 'row';
        for (const choice of (q.choices || [])) {
          const b = document.createElement('button');
          b.textContent = choice.label;
          b.onclick = async () => {
            await api('/api/answer', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ id: run.id, qid: q.qid, chosen_label: choice.label })
            });
            await loadRun(run.id);
          };
          row.appendChild(b);
        }
        node.appendChild(row);
        qWrap.appendChild(node);
      }

      const nodes = run.nodes || {};
      let stageNode = '';
      if (run.current_node && nodes[run.current_node]) {
        stageNode = run.current_node;
      }
      if (!stageNode && run.checkpoint && run.checkpoint.completed_nodes) {
        let completed = run.checkpoint.completed_nodes;
        if (typeof completed === 'string') {
          completed = completed.trim() ? completed.trim().split(/\s+/) : [];
        }
        if (Array.isArray(completed) && completed.length > 0) {
          const candidate = completed[completed.length - 1];
          if (nodes[candidate]) stageNode = candidate;
        }
      }
      if (!stageNode) {
        const nodeKeys = Object.keys(nodes).sort();
        if (nodeKeys.length > 0) stageNode = nodeKeys[nodeKeys.length - 1];
      }

      if (stageNode) {
        const stage = await api(`/api/stage?id=${encodeURIComponent(run.id)}&node=${encodeURIComponent(stageNode)}`);
        document.getElementById('stage').textContent = JSON.stringify(stage, null, 2);
      } else {
        document.getElementById('stage').textContent = '(none)';
      }

      if ((run.status || '') === 'failed') {
        const reason = run.reason || (run.worker_result && run.worker_result.reason) || 'failed';
        const errMeta = run.worker_result && run.worker_result.error ? { error: run.worker_result.error } : null;
        showError(`Run failed: ${reason}`, errMeta);
      } else {
        showError('');
      }
    }

    async function selectRun(runId) {
      state.selected = runId;
      renderRuns();
      await loadRun(runId);
      if (state.runEventSource) state.runEventSource.close();
      state.runEvents = [];
      document.getElementById('events').textContent = '(waiting)';
      state.runEventSource = new EventSource(`/events/${encodeURIComponent(runId)}`);
      state.runEventSource.onmessage = (evt) => {
        state.runEvents.push(evt.data);
        if (state.runEvents.length > 80) state.runEvents.shift();
        document.getElementById('events').textContent = state.runEvents.join('\n');
        setActivity(`Streaming events: ${runId}`);
      };
      state.runEventSource.onerror = () => {};
    }

    function connectGlobalSse() {
      if (state.eventSource) state.eventSource.close();
      const es = new EventSource('/events');
      state.eventSource = es;
      es.onopen = () => setConn(true);
      es.onerror = () => setConn(false);
      es.onmessage = async (evt) => {
        try {
          state.runs = JSON.parse(evt.data);
          renderRuns();
          if (state.selected) {
            await loadRun(state.selected);
          }
        } catch (_) {}
      };
    }

    document.addEventListener('keydown', async (evt) => {
      if (!(evt.ctrlKey || evt.metaKey)) return;
      if (evt.key === 'Enter') {
        evt.preventDefault();
        if (evt.shiftKey) {
          await previewDot({ quiet: false });
        } else {
          await startRun();
        }
      }
    });

    document.getElementById('generateBtn').onclick = generateDot;
    document.getElementById('previewBtn').onclick = () => previewDot({ quiet: false });
    document.getElementById('fixBtn').onclick = fixDot;
    document.getElementById('iterateBtn').onclick = iterateDot;
    document.getElementById('runBtn').onclick = startRun;
    document.getElementById('refreshBtn').onclick = refreshRuns;
    document.getElementById('dot').addEventListener('input', schedulePreview);
    document.getElementById('dotfile').onchange = async (evt) => {
      const file = evt.target.files && evt.target.files[0];
      if (!file) return;
      state.fileName = file.name;
      document.getElementById('dot').value = await file.text();
      await previewDot({ quiet: true });
    };

    setWorkflow('prompt');
    setActivity('Idle');
    refreshRuns().then(connectGlobalSse);
  </script>
</body>
</html>
}
}

proc ::attractor_web::__server_path_safe {base path} {
    set baseNorm [file normalize $base]
    set pathNorm [file normalize $path]
    if {$pathNorm eq $baseNorm} {
        return 1
    }
    return [expr {[string first "$baseNorm/" "$pathNorm/"] == 0}]
}

proc ::attractor_web::__run_dir {runsRoot runId} {
    return [file normalize [file join $runsRoot $runId]]
}

proc ::attractor_web::__run_ids {runsRoot} {
    set ids {}
    foreach path [lsort [glob -nocomplain -directory $runsRoot *]] {
        if {[file isdirectory $path]} {
            lappend ids [file tail $path]
        }
    }
    return $ids
}

proc ::attractor_web::__load_checkpoint_summary {runDir} {
    set checkpoint [::attractor_web::__read_json_file [file join $runDir checkpoint.json]]
    if {[dict size $checkpoint] == 0} {
        return [dict create current_node "" completed_nodes_count 0]
    }
    set current [expr {[dict exists $checkpoint current_node] ? [dict get $checkpoint current_node] : ""}]
    set count 0
    if {[dict exists $checkpoint completed_nodes]} {
        set count [llength [dict get $checkpoint completed_nodes]]
    }
    return [dict create current_node $current completed_nodes_count $count]
}

proc ::attractor_web::__load_run_status {runDir} {
    set status running
    set reason ""
    set error ""
    set endedAt ""
    set worker [::attractor_web::__read_json_file [file join $runDir worker-result.json]]
    if {[dict size $worker] > 0 && [dict exists $worker status]} {
        set status [dict get $worker status]
        if {[dict exists $worker reason]} {
            set reason [dict get $worker reason]
        }
        if {[dict exists $worker error]} {
            set error [dict get $worker error]
        }
        if {[dict exists $worker ended_at]} {
            set endedAt [dict get $worker ended_at]
        }
    }
    return [dict create status $status reason $reason error $error ended_at $endedAt]
}

proc ::attractor_web::__pipelines_snapshot {runsRoot} {
    set out {}
    foreach runId [::attractor_web::__run_ids $runsRoot] {
        if {![::attractor_web::__run_id_valid $runId]} {
            continue
        }
        set runDir [::attractor_web::__run_dir $runsRoot $runId]
        if {![::attractor_web::__server_path_safe $runsRoot $runDir]} {
            continue
        }
        set web [::attractor_web::__read_json_file [file join $runDir web.json]]
        set summary [::attractor_web::__load_checkpoint_summary $runDir]
        set statusInfo [::attractor_web::__load_run_status $runDir]
        set startedAt ""
        if {[dict size $web] > 0 && [dict exists $web created_at]} {
            set startedAt [dict get $web created_at]
        } else {
            set manifest [::attractor_web::__read_json_file [file join $runDir manifest.json]]
            if {[dict size $manifest] > 0 && [dict exists $manifest started_at]} {
                set startedAt [dict get $manifest started_at]
            }
        }
        if {$startedAt eq ""} {
            set startedAt "-"
        }
        set currentNode [dict get $summary current_node]
        if {$currentNode eq ""} {
            set currentNode "-"
        }
        lappend out [dict create \
            id $runId \
            started_at $startedAt \
            status [dict get $statusInfo status] \
            reason [dict get $statusInfo reason] \
            current_node $currentNode \
            completed_nodes_count [dict get $summary completed_nodes_count] \
            logs_root $runDir]
    }
    return $out
}

proc ::attractor_web::__events_lines {runDir} {
    set path [file join $runDir events.ndjson]
    if {![file exists $path]} {
        return {}
    }
    set payload [::attractor_web::__read_file $path]
    set out {}
    foreach line [split $payload "\n"] {
        set line [string trim $line]
        if {$line ne ""} {
            lappend out $line
        }
    }
    return $out
}

proc ::attractor_web::__pipelines_snapshot_json {runsRoot} {
    set items {}
    foreach row [::attractor_web::__pipelines_snapshot $runsRoot] {
        lappend items "{\"id\":[::attractor_web::__json_quote [dict get $row id]],\"started_at\":[::attractor_web::__json_quote [dict get $row started_at]],\"status\":[::attractor_web::__json_quote [dict get $row status]],\"reason\":[::attractor_web::__json_quote [dict get $row reason]],\"current_node\":[::attractor_web::__json_quote [dict get $row current_node]],\"completed_nodes_count\":[dict get $row completed_nodes_count],\"logs_root\":[::attractor_web::__json_quote [dict get $row logs_root]]}"
    }
    return "\[[join $items ,]\]"
}

proc ::attractor_web::__pending_questions {runDir} {
    set out {}
    set qdir [file join $runDir questions]
    foreach pending [lsort [glob -nocomplain -directory $qdir *.pending.json]] {
        set qid [string range [file tail $pending] 0 end-13]
        set answer [file join $qdir "$qid.answer.json"]
        if {[file exists $answer]} {
            continue
        }
        set payload [::attractor_web::__read_json_file $pending]
        if {[dict size $payload] > 0} {
            lappend out $payload
        }
    }
    return $out
}

proc ::attractor_web::__pending_questions_json {runDir} {
    set items {}
    set qdir [file join $runDir questions]
    foreach pending [lsort [glob -nocomplain -directory $qdir *.pending.json]] {
        set qid [string range [file tail $pending] 0 end-13]
        set answer [file join $qdir "$qid.answer.json"]
        if {[file exists $answer]} {
            continue
        }
        lappend items [::attractor_web::__json_read_raw $pending "{}"]
    }
    return "\[[join $items ,]\]"
}

proc ::attractor_web::__nodes_json {runDir} {
    set items {}
    foreach p [lsort [glob -nocomplain -directory $runDir *]] {
        if {![file isdirectory $p]} {
            continue
        }
        set nodeId [file tail $p]
        if {![::attractor_web::__node_id_valid $nodeId]} {
            continue
        }
        set statusPath [file join $p status.json]
        if {![file exists $statusPath]} {
            continue
        }
        lappend items "[::attractor_web::__json_quote $nodeId]:[::attractor_web::__json_read_raw $statusPath "{}"]"
    }
    return "{[join $items ,]}"
}

proc ::attractor_web::__pipeline_detail_json {runsRoot runId} {
    if {![::attractor_web::__run_id_valid $runId]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_ID] "invalid run id"
    }
    set runDir [::attractor_web::__run_dir $runsRoot $runId]
    if {![::attractor_web::__server_path_safe $runsRoot $runDir] || ![file isdirectory $runDir]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "run not found"
    }

    set status running
    set reason ""
    set currentNode "-"
    set completedCount 0
    foreach row [::attractor_web::__pipelines_snapshot $runsRoot] {
        if {[dict get $row id] eq $runId} {
            set status [dict get $row status]
            if {[dict exists $row reason]} {
                set reason [dict get $row reason]
            }
            set currentNode [dict get $row current_node]
            set completedCount [dict get $row completed_nodes_count]
            break
        }
    }

    set dotSource ""
    set dotPath [file join $runDir pipeline.dot]
    if {[file exists $dotPath]} {
        set dotSource [::attractor_web::__read_file $dotPath]
    }

    set webJson [::attractor_web::__json_read_raw [file join $runDir web.json] "{}"]
    set manifestJson [::attractor_web::__json_read_raw [file join $runDir manifest.json] "{}"]
    set checkpointJson [::attractor_web::__json_read_raw [file join $runDir checkpoint.json] "{}"]
    set workerJson [::attractor_web::__json_read_raw [file join $runDir worker-result.json] "{}"]
    set nodesJson [::attractor_web::__nodes_json $runDir]
    set questionsJson [::attractor_web::__pending_questions_json $runDir]

    return "{\"id\":[::attractor_web::__json_quote $runId],\"status\":[::attractor_web::__json_quote $status],\"reason\":[::attractor_web::__json_quote $reason],\"current_node\":[::attractor_web::__json_quote $currentNode],\"completed_nodes_count\":$completedCount,\"dotSource\":[::attractor_web::__json_quote $dotSource],\"web\":$webJson,\"manifest\":$manifestJson,\"checkpoint\":$checkpointJson,\"worker_result\":$workerJson,\"nodes\":$nodesJson,\"pending_questions\":$questionsJson}"
}

proc ::attractor_web::__stage_detail_json {runsRoot runId nodeId} {
    if {![::attractor_web::__run_id_valid $runId] || ![::attractor_web::__node_id_valid $nodeId]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_ID] "invalid id"
    }
    set runDir [::attractor_web::__run_dir $runsRoot $runId]
    set nodeDir [file normalize [file join $runDir $nodeId]]
    if {![::attractor_web::__server_path_safe $runDir $nodeDir] || ![file isdirectory $nodeDir]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "stage not found"
    }

    set statusPath [file join $nodeDir status.json]
    if {![file exists $statusPath]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "stage not found"
    }

    set prompt ""
    set response ""
    set promptPath [file join $nodeDir prompt.md]
    set responsePath [file join $nodeDir response.md]
    if {[file exists $promptPath]} {
        set prompt [::attractor_web::__read_file $promptPath]
    }
    if {[file exists $responsePath]} {
        set response [::attractor_web::__read_file $responsePath]
    }

    set statusJson [::attractor_web::__json_read_raw $statusPath "{}"]
    return "{\"status\":$statusJson,\"prompt_md\":[::attractor_web::__json_quote $prompt],\"response_md\":[::attractor_web::__json_quote $response]}"
}

proc ::attractor_web::__node_artifacts {runDir} {
    set out {}
    foreach p [lsort [glob -nocomplain -directory $runDir *]] {
        if {![file isdirectory $p]} {
            continue
        }
        set nodeId [file tail $p]
        if {![::attractor_web::__node_id_valid $nodeId]} {
            continue
        }
        set status [::attractor_web::__read_json_file [file join $p status.json]]
        if {[dict size $status] == 0} {
            continue
        }
        dict set out $nodeId $status
    }
    return $out
}

proc ::attractor_web::__pipeline_detail {runsRoot runId} {
    if {![::attractor_web::__run_id_valid $runId]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_ID] "invalid run id"
    }
    set runDir [::attractor_web::__run_dir $runsRoot $runId]
    if {![::attractor_web::__server_path_safe $runsRoot $runDir] || ![file isdirectory $runDir]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "run not found"
    }

    set snapshot {}
    foreach row [::attractor_web::__pipelines_snapshot $runsRoot] {
        if {[dict get $row id] eq $runId} {
            set snapshot $row
            break
        }
    }
    if {$snapshot eq ""} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "run not found"
    }

    set dotSource ""
    set dotPath [file join $runDir pipeline.dot]
    if {[file exists $dotPath]} {
        set dotSource [::attractor_web::__read_file $dotPath]
    }

    return [dict create \
        id $runId \
        status [dict get $snapshot status] \
        reason [dict get $snapshot reason] \
        current_node [dict get $snapshot current_node] \
        completed_nodes_count [dict get $snapshot completed_nodes_count] \
        dotSource $dotSource \
        web [::attractor_web::__read_json_file [file join $runDir web.json]] \
        manifest [::attractor_web::__read_json_file [file join $runDir manifest.json]] \
        checkpoint [::attractor_web::__read_json_file [file join $runDir checkpoint.json]] \
        worker_result [::attractor_web::__read_json_file [file join $runDir worker-result.json]] \
        nodes [::attractor_web::__node_artifacts $runDir] \
        pending_questions [::attractor_web::__pending_questions $runDir]]
}

proc ::attractor_web::__stage_detail {runsRoot runId nodeId} {
    if {![::attractor_web::__run_id_valid $runId] || ![::attractor_web::__node_id_valid $nodeId]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_ID] "invalid id"
    }
    set runDir [::attractor_web::__run_dir $runsRoot $runId]
    set nodeDir [file normalize [file join $runDir $nodeId]]
    if {![::attractor_web::__server_path_safe $runDir $nodeDir] || ![file isdirectory $nodeDir]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "stage not found"
    }

    set status [::attractor_web::__read_json_file [file join $nodeDir status.json]]
    if {[dict size $status] == 0} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "stage not found"
    }

    set prompt ""
    set response ""
    set promptPath [file join $nodeDir prompt.md]
    set responsePath [file join $nodeDir response.md]
    if {[file exists $promptPath]} {
        set prompt [::attractor_web::__read_file $promptPath]
    }
    if {[file exists $responsePath]} {
        set response [::attractor_web::__read_file $responsePath]
    }

    return [dict create status $status prompt_md $prompt response_md $response]
}

proc ::attractor_web::__request_json {requestVar} {
    upvar 1 $requestVar request
    set body [dict get $request body]
    if {[string trim $body] eq ""} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_JSON] "request body is required"
    }
    if {[catch {set decoded [::attractor_core::json_decode $body]} err]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_JSON] $err
    }
    return $decoded
}

proc ::attractor_web::__worker_script_path {} {
    variable root
    return [file join $root bin attractor-worker]
}

proc ::attractor_web::__spawn_worker {id runId runDir {provider ""} {model ""}} {
    variable servers
    set state [dict get $servers $id]

    set workerScript [::attractor_web::__worker_script_path]
    set cmd [list [info nameofexecutable] $workerScript --run-id $runId --run-dir $runDir --max-question-wait-ms [dict get $state max_question_wait_ms]]
    if {[string trim $provider] ne ""} {
        lappend cmd --provider [string trim $provider]
    }
    if {[string trim $model] ne ""} {
        lappend cmd --model [string trim $model]
    }
    set pipeline [linsert $cmd 0 |]

    if {[catch {set chan [open $pipeline r]} err]} {
        return -code error -errorcode [list ATTRACTOR_WEB WORKER_SPAWN_FAILED] $err
    }
    fconfigure $chan -blocking 0 -buffering none -translation binary -encoding utf-8
    set pid [lindex [pid $chan] 0]

    dict set state workers $chan [dict create run_id $runId pid $pid output ""]
    dict set servers $id $state

    fileevent $chan readable [list ::attractor_web::__worker_readable $id $chan]
    return $pid
}

proc ::attractor_web::__worker_readable {id chan} {
    variable servers
    if {![dict exists $servers $id]} {
        catch {close $chan}
        return
    }
    set state [dict get $servers $id]
    if {![dict exists $state workers $chan]} {
        catch {close $chan}
        return
    }

    set chunk [read $chan]
    if {$chunk ne ""} {
        set worker [dict get $state workers $chan]
        dict append worker output $chunk
        dict set state workers $chan $worker
    }

    if {[eof $chan]} {
        set worker [dict get $state workers $chan]
        set runId [dict get $worker run_id]
        set runsRoot [dict get $state runs_root]
        set runDir [::attractor_web::__run_dir $runsRoot $runId]

        set exitCode 0
        if {[catch {close $chan} closeErr closeOpts]} {
            set exitCode 1
            if {[dict exists $closeOpts -errorcode] && [lindex [dict get $closeOpts -errorcode] 0] eq "CHILDSTATUS"} {
                set exitCode [lindex [dict get $closeOpts -errorcode] 2]
            }
        }

        if {$exitCode != 0 && ![file exists [file join $runDir worker-result.json]]} {
            ::attractor_web::__write_json_file [file join $runDir worker-result.json] [dict create \
                run_id $runId \
                status failed \
                reason worker_failed \
                ended_at [::attractor_web::__iso8601_now]]
        }

        dict unset state workers $chan
        dict set servers $id $state
    } else {
        dict set servers $id $state
    }
}

proc ::attractor_web::__send_response {chan status contentType body {extraHeaders {}}} {
    set reason [::attractor_web::__http_reason $status]
    set headers [dict create \
        Content-Type $contentType \
        Content-Length [string length $body] \
        Connection close]
    foreach {k v} $extraHeaders {
        dict set headers $k $v
    }

    puts -nonewline $chan "HTTP/1.1 $status $reason\r\n"
    foreach key [dict keys $headers] {
        puts -nonewline $chan "$key: [dict get $headers $key]\r\n"
    }
    puts -nonewline $chan "\r\n$body"
    flush $chan
}

proc ::attractor_web::__send_json {chan status payload} {
    ::attractor_web::__send_response $chan $status application/json [::attractor_core::json_encode $payload]
}

proc ::attractor_web::__send_sse_headers {chan} {
    puts -nonewline $chan "HTTP/1.1 200 OK\r\n"
    puts -nonewline $chan "Content-Type: text/event-stream\r\n"
    puts -nonewline $chan "Cache-Control: no-cache\r\n"
    puts -nonewline $chan "Connection: keep-alive\r\n\r\n"
    flush $chan
}

proc ::attractor_web::__send_sse_headers_close {chan} {
    puts -nonewline $chan "HTTP/1.1 200 OK\r\n"
    puts -nonewline $chan "Content-Type: text/event-stream\r\n"
    puts -nonewline $chan "Cache-Control: no-cache\r\n"
    puts -nonewline $chan "Connection: close\r\n\r\n"
    flush $chan
}

proc ::attractor_web::__send_sse_data {chan payload} {
    foreach line [split $payload "\n"] {
        puts -nonewline $chan "data: $line\n"
    }
    puts -nonewline $chan "\n"
    flush $chan
}

proc ::attractor_web::__send_sse_comment {chan text} {
    puts -nonewline $chan ": $text\n\n"
    flush $chan
}

proc ::attractor_web::__remove_sse_client {id chan} {
    variable servers
    if {![dict exists $servers $id]} {
        catch {close $chan}
        return
    }
    set state [dict get $servers $id]
    if {[dict exists $state sse_clients $chan]} {
        dict unset state sse_clients $chan
        dict set servers $id $state
    }
    catch {close $chan}
}

proc ::attractor_web::__sse_readable {id chan} {
    if {[eof $chan]} {
        ::attractor_web::__remove_sse_client $id $chan
        return
    }
    read $chan
}

proc ::attractor_web::__sse_add_global {id chan} {
    variable servers
    set state [dict get $servers $id]
    set snapshotJson [::attractor_web::__pipelines_snapshot_json [dict get $state runs_root]]
    dict set state sse_clients $chan [dict create kind global last_payload $snapshotJson sent_count 0 run_id ""]
    dict set servers $id $state
    ::attractor_web::__send_sse_headers $chan
    ::attractor_web::__send_sse_data $chan $snapshotJson
    fileevent $chan readable [list ::attractor_web::__sse_readable $id $chan]
}

proc ::attractor_web::__sse_add_run {id chan runId} {
    variable servers
    set state [dict get $servers $id]
    set runDir [::attractor_web::__run_dir [dict get $state runs_root] $runId]
    if {![file isdirectory $runDir]} {
        ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error "run not found" NOT_FOUND]
        catch {close $chan}
        return
    }
    set lines [::attractor_web::__events_lines $runDir]
    dict set state sse_clients $chan [dict create kind run run_id $runId sent_count 0 last_payload ""]
    dict set servers $id $state
    ::attractor_web::__send_sse_headers $chan
    foreach line $lines {
        ::attractor_web::__send_sse_data $chan $line
    }
    set state [dict get $servers $id]
    if {[dict exists $state sse_clients $chan]} {
        dict set state sse_clients $chan sent_count [llength $lines]
        dict set servers $id $state
    }
    fileevent $chan readable [list ::attractor_web::__sse_readable $id $chan]
}

proc ::attractor_web::__collect_http_request {buffer maxBodyBytes} {
    set markerIdx [string first "\r\n\r\n" $buffer]
    set markerLen 4
    if {$markerIdx < 0} {
        set markerIdx [string first "\n\n" $buffer]
        set markerLen 2
    }
    if {$markerIdx < 0} {
        return [dict create ready 0]
    }

    set headerText [string range $buffer 0 [expr {$markerIdx - 1}]]
    set bodyText [string range $buffer [expr {$markerIdx + $markerLen}] end]
    set lines [split [string map [list "\r\n" "\n" "\r" "\n"] $headerText] "\n"]
    set requestLine [lindex $lines 0]
    if {![regexp {^([A-Z]+) ([^ ]+) (HTTP/[0-9.]+)$} $requestLine -> method path version]} {
        return [dict create ready 1 error INVALID_HTTP]
    }

    set headers {}
    for {set i 1} {$i < [llength $lines]} {incr i} {
        set line [lindex $lines $i]
        if {$line eq ""} {
            continue
        }
        set sep [string first : $line]
        if {$sep < 0} {
            continue
        }
        set key [string trim [string range $line 0 [expr {$sep - 1}]]]
        set value [string trim [string range $line [expr {$sep + 1}] end]]
        dict set headers [string tolower $key] $value
    }

    set contentLength 0
    if {[dict exists $headers content-length]} {
        set contentLength [dict get $headers content-length]
        if {![string is integer -strict $contentLength] || $contentLength < 0} {
            return [dict create ready 1 error INVALID_HTTP]
        }
    }

    if {$contentLength > $maxBodyBytes} {
        return [dict create ready 1 error BODY_TOO_LARGE]
    }

    if {[string length $bodyText] < $contentLength} {
        return [dict create ready 0]
    }

    set body [string range $bodyText 0 [expr {$contentLength - 1}]]
    return [dict create \
        ready 1 \
        request [dict create method $method path $path version $version headers $headers body $body] \
        consumed [expr {$markerIdx + $markerLen + $contentLength}]]
}

proc ::attractor_web::__dispatch_route {id chan request} {
    variable servers
    set state [dict get $servers $id]
    lassign [::attractor_web::__split_path_query [dict get $request path]] path query
    set method [dict get $request method]
    set runsRoot [dict get $state runs_root]

    if {$method eq "GET" && $path eq "/"} {
        ::attractor_web::__send_response $chan 200 "text/html; charset=utf-8" [::attractor_web::__html_dashboard]
        return 0
    }

    if {$method eq "GET" && $path eq "/favicon.ico"} {
        ::attractor_web::__send_response $chan 204 "image/x-icon" ""
        return 0
    }

    if {$method eq "GET" && $path eq "/api/pipelines"} {
        ::attractor_web::__send_response $chan 200 application/json [::attractor_web::__pipelines_snapshot_json $runsRoot]
        return 0
    }

    if {$method eq "POST" && $path eq "/api/run"} {
        if {[catch {set payload [::attractor_web::__request_json request]} err opts]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_JSON]
            return 0
        }
        if {![dict exists $payload dotSource]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "dotSource is required" INVALID_DOT_SOURCE]
            return 0
        }

        set dotSource [::attractor_web::normalize_dot_source [dict get $payload dotSource]]
        if {[string trim $dotSource] eq ""} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "dotSource is empty after normalization" INVALID_DOT_SOURCE]
            return 0
        }

        set fileName ""
        if {[dict exists $payload fileName]} {
            set fileName [dict get $payload fileName]
            if {![::attractor_web::__filename_valid $fileName]} {
                ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "fileName must be a simple leaf name" INVALID_FILE_NAME]
                return 0
            }
        }

        set runProvider [::attractor_web::__dot_provider_default]
        if {[dict exists $payload provider] && [string trim [dict get $payload provider]] ne ""} {
            set runProvider [string tolower [string trim [dict get $payload provider]]]
        }
        if {$runProvider eq ""} {
            set runProvider openai
        }
        if {$runProvider ni {openai anthropic gemini}} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "provider must be one of openai, anthropic, gemini" BAD_REQUEST]
            return 0
        }

        set runModel ""
        if {[dict exists $payload model]} {
            set runModel [string trim [dict get $payload model]]
        }

        if {[catch {set _graph [::attractor::parse_dot $dotSource]} parseErr]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $parseErr INVALID_DOT_SOURCE]
            return 0
        }
        set diagnostics [::attractor::validate $_graph]
        if {[::attractor::__has_validation_errors $diagnostics]} {
            ::attractor_web::__send_json $chan 400 [dict create error "validation failed" code INVALID_DOT_SOURCE diagnostics $diagnostics]
            return 0
        }

        if {[::attractor_web::__graph_requires_llm $_graph]} {
            if {[catch {::attractor_web::__provider_runtime_preflight $runProvider} preflightErr]} {
                ::attractor_web::__send_json $chan 503 [dict create \
                    error $preflightErr \
                    code RUNTIME_UNAVAILABLE \
                    provider $runProvider]
                return 0
            }
        }

        variable run_seq
        incr run_seq
        set runId "run-[::attractor_web::__millis_now]-$run_seq"
        set runDir [::attractor_web::__run_dir $runsRoot $runId]
        file mkdir $runDir

        ::attractor_web::__write_text_file [file join $runDir pipeline.dot] $dotSource
        set webMeta [dict create \
            run_id $runId \
            created_at [::attractor_web::__iso8601_now] \
            provider $runProvider \
            dot_sha256 [::attractor_web::__sha256_hex $dotSource] \
            worker_pid ""]
        if {$fileName ne ""} {
            dict set webMeta file_name $fileName
        }
        if {$runModel ne ""} {
            dict set webMeta model $runModel
        }
        ::attractor_web::__write_json_file [file join $runDir web.json] $webMeta

        if {[catch {set pid [::attractor_web::__spawn_worker $id $runId $runDir $runProvider $runModel]} spawnErr]} {
            ::attractor_web::__write_json_file [file join $runDir worker-result.json] [dict create run_id $runId status failed reason worker_spawn_failed error $spawnErr ended_at [::attractor_web::__iso8601_now]]
            ::attractor_web::__send_json $chan 500 [::attractor_web::__json_error $spawnErr WORKER_SPAWN_FAILED]
            return 0
        }

        dict set webMeta worker_pid $pid
        ::attractor_web::__write_json_file [file join $runDir web.json] $webMeta
        ::attractor_web::__send_json $chan 200 [dict create ok true id $runId]
        return 0
    }

    if {$method eq "GET" && $path eq "/api/pipeline"} {
        if {![dict exists $query id]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "id is required" INVALID_ID]
            return 0
        }
        set runId [dict get $query id]
        if {[catch {set detailJson [::attractor_web::__pipeline_detail_json $runsRoot $runId]} err opts]} {
            set code [expr {[dict exists $opts -errorcode] ? [lindex [dict get $opts -errorcode] end] : ""}]
            if {$code eq "NOT_FOUND"} {
                ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error $err NOT_FOUND]
            } else {
                ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_ID]
            }
            return 0
        }
        ::attractor_web::__send_response $chan 200 application/json $detailJson
        return 0
    }

    if {$method eq "GET" && $path eq "/api/stage"} {
        if {![dict exists $query id] || ![dict exists $query node]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "id and node are required" INVALID_ID]
            return 0
        }
        if {[catch {set detailJson [::attractor_web::__stage_detail_json $runsRoot [dict get $query id] [dict get $query node]]} err opts]} {
            set code [expr {[dict exists $opts -errorcode] ? [lindex [dict get $opts -errorcode] end] : ""}]
            if {$code eq "NOT_FOUND"} {
                ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error $err NOT_FOUND]
            } else {
                ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_ID]
            }
            return 0
        }
        ::attractor_web::__send_response $chan 200 application/json $detailJson
        return 0
    }

    if {$method eq "POST" && $path eq "/api/answer"} {
        if {[catch {set payload [::attractor_web::__request_json request]} err opts]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_JSON]
            return 0
        }
        foreach key {id qid chosen_label} {
            if {![dict exists $payload $key] || [string trim [dict get $payload $key]] eq ""} {
                ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "missing required field: $key" INVALID_ID]
                return 0
            }
        }

        set runId [dict get $payload id]
        set qid [dict get $payload qid]
        if {![::attractor_web::__run_id_valid $runId] || ![::attractor_web::__qid_valid $qid]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "invalid id" INVALID_ID]
            return 0
        }

        set runDir [::attractor_web::__run_dir $runsRoot $runId]
        if {![file isdirectory $runDir]} {
            ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error "run not found" NOT_FOUND]
            return 0
        }

        set pendingPath [file join $runDir questions "$qid.pending.json"]
        if {![file exists $pendingPath]} {
            ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error "question not found" NOT_FOUND]
            return 0
        }

        set pending [::attractor_web::__read_json_file $pendingPath]
        set chosen [dict get $payload chosen_label]
        set valid 0
        foreach choice [dict get $pending choices] {
            if {[dict get $choice label] eq $chosen} {
                set valid 1
                break
            }
        }
        if {!$valid} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "chosen_label is not valid for this question" INVALID_ID]
            return 0
        }

        ::attractor_web::__write_json_file [file join $runDir questions "$qid.answer.json"] [dict create qid $qid chosen_label $chosen answered_at [::attractor_web::__iso8601_now]]
        ::attractor_web::__send_json $chan 200 [dict create ok true id $runId qid $qid]
        return 0
    }

    if {$method eq "POST" && $path eq "/api/render"} {
        if {[catch {set payload [::attractor_web::__request_json request]} err opts]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_JSON]
            return 0
        }
        if {![dict exists $payload dotSource]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "dotSource is required" INVALID_DOT_SOURCE]
            return 0
        }
        set dotSource [::attractor_web::normalize_dot_source [dict get $payload dotSource]]
        if {[string trim $dotSource] eq ""} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "dotSource is empty after normalization" INVALID_DOT_SOURCE]
            return 0
        }

        set dotCmd [dict get $state dot_bin]
        if {[auto_execok $dotCmd] eq ""} {
            ::attractor_web::__send_json $chan 500 [::attractor_web::__json_error "Graphviz dot binary not found" DOT_BINARY_MISSING]
            return 0
        }

        set tmpPath [file join [dict get $state runs_root] ".render-[pid]-[::attractor_web::__millis_now].dot"]
        ::attractor_web::__write_text_file $tmpPath $dotSource
        set code [catch {set svg [exec $dotCmd -Tsvg $tmpPath]} renderErr renderOpts]
        file delete -force $tmpPath
        if {$code != 0} {
            ::attractor_web::__send_json $chan 500 [::attractor_web::__json_error $renderErr DOT_RENDER_FAILED]
            return 0
        }
        set svg [::attractor_web::__extract_svg_markup $svg]
        if {[string trim $svg] eq ""} {
            ::attractor_web::__send_json $chan 500 [::attractor_web::__json_error "Graphviz dot output did not contain SVG markup" DOT_RENDER_INVALID_OUTPUT]
            return 0
        }

        ::attractor_web::__send_response $chan 200 application/json "{\"ok\":true,\"svg\":[::attractor_web::__json_quote $svg]}"
        return 0
    }

    if {$method eq "POST" && $path in {"/api/v1/dot/generate/stream" "/api/v1/dot/fix/stream" "/api/v1/dot/iterate/stream"}} {
        if {[catch {set payload [::attractor_web::__request_json request]} err opts]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_JSON]
            return 0
        }

        set mode ""
        switch -- $path {
            "/api/v1/dot/generate/stream" { set mode generate }
            "/api/v1/dot/fix/stream" { set mode fix }
            "/api/v1/dot/iterate/stream" { set mode iterate }
        }

        if {[catch {::attractor_web::__dot_user_prompt $mode $payload} inputErr]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $inputErr BAD_REQUEST]
            return 0
        }

        ::attractor_web::__send_sse_headers_close $chan
        if {[catch {set dotSource [::attractor_web::__dot_stream_generate $state $payload $mode $chan]} genErr]} {
            ::attractor_web::__send_sse_data $chan "{\"error\":[::attractor_web::__json_quote $genErr],\"code\":\"GENERATION_ERROR\"}"
            return 0
        }
        ::attractor_web::__send_sse_data $chan "{\"done\":true,\"dotSource\":[::attractor_web::__json_quote $dotSource]}"
        return 0
    }

    if {$method eq "GET" && $path eq "/events"} {
        ::attractor_web::__sse_add_global $id $chan
        return 1
    }

    if {$method eq "GET" && [string first "/events/" $path] == 0} {
        set runId [string range $path 8 end]
        if {![::attractor_web::__run_id_valid $runId]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "invalid id" INVALID_ID]
            return 0
        }
        ::attractor_web::__sse_add_run $id $chan $runId
        return 1
    }

    ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error "not found" NOT_FOUND]
    return 0
}

proc ::attractor_web::__on_client_readable {id chan} {
    variable servers
    if {![dict exists $servers $id]} {
        catch {close $chan}
        return
    }
    set state [dict get $servers $id]
    if {![dict exists $state clients $chan]} {
        catch {close $chan}
        return
    }

    set data [read $chan]
    if {$data ne ""} {
        set conn [dict get $state clients $chan]
        dict append conn buffer $data
        dict set state clients $chan $conn
        dict set servers $id $state
    }

    set state [dict get $servers $id]
    if {![dict exists $state clients $chan]} {
        catch {close $chan}
        return
    }

    set conn [dict get $state clients $chan]
    set parsed [::attractor_web::__collect_http_request [dict get $conn buffer] [dict get $state max_body_bytes]]
    if {![dict get $parsed ready]} {
        if {[eof $chan] && $data eq ""} {
            dict unset state clients $chan
            dict set servers $id $state
            catch {close $chan}
        }
        return
    }

    if {[dict exists $parsed error]} {
        set code [dict get $parsed error]
        if {$code eq "BODY_TOO_LARGE"} {
            ::attractor_web::__send_json $chan 413 [::attractor_web::__json_error "request body exceeds limit" BODY_TOO_LARGE]
        } else {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "malformed HTTP request" INVALID_JSON]
        }
        dict unset state clients $chan
        dict set servers $id $state
        catch {close $chan}
        return
    }

    set request [dict get $parsed request]
    dict unset state clients $chan
    dict set servers $id $state

    set keepOpen [::attractor_web::__dispatch_route $id $chan $request]
    if {!$keepOpen} {
        catch {close $chan}
    }
}

proc ::attractor_web::__on_accept {id chan addr port} {
    variable servers
    if {![dict exists $servers $id]} {
        catch {close $chan}
        return
    }

    fconfigure $chan -blocking 0 -buffering none -translation binary -encoding utf-8
    set state [dict get $servers $id]
    dict set state clients $chan [dict create addr $addr port $port buffer ""]
    dict set servers $id $state
    fileevent $chan readable [list ::attractor_web::__on_client_readable $id $chan]
}

proc ::attractor_web::__tick {id} {
    variable servers
    if {![dict exists $servers $id]} {
        return
    }
    set state [dict get $servers $id]

    set runsRoot [dict get $state runs_root]
    set snapshot [::attractor_web::__pipelines_snapshot $runsRoot]
    set snapshotJson [::attractor_web::__pipelines_snapshot_json $runsRoot]

    set ticks [expr {[dict exists $state tick_count] ? [dict get $state tick_count] : 0}]
    incr ticks
    dict set state tick_count $ticks

    foreach chan [dict keys [dict get $state sse_clients]] {
        set client [dict get $state sse_clients $chan]
        set kind [dict get $client kind]
        if {$kind eq "global"} {
            if {![dict exists $client last_payload] || [dict get $client last_payload] ne $snapshotJson} {
                if {[catch {::attractor_web::__send_sse_data $chan $snapshotJson}]} {
                    ::attractor_web::__remove_sse_client $id $chan
                    continue
                }
                dict set state sse_clients $chan last_payload $snapshotJson
            } elseif {($ticks % 20) == 0} {
                if {[catch {::attractor_web::__send_sse_comment $chan "heartbeat"}]} {
                    ::attractor_web::__remove_sse_client $id $chan
                    continue
                }
            }
        } else {
            set runId [dict get $client run_id]
            set runDir [::attractor_web::__run_dir $runsRoot $runId]
            set lines [::attractor_web::__events_lines $runDir]
            set sent [dict get $client sent_count]
            for {set i $sent} {$i < [llength $lines]} {incr i} {
                if {[catch {::attractor_web::__send_sse_data $chan [lindex $lines $i]}]} {
                    ::attractor_web::__remove_sse_client $id $chan
                    continue
                }
            }
            dict set state sse_clients $chan sent_count [llength $lines]
            if {($ticks % 20) == 0} {
                if {[catch {::attractor_web::__send_sse_comment $chan "heartbeat"}]} {
                    ::attractor_web::__remove_sse_client $id $chan
                    continue
                }
            }
        }
    }

    dict set servers $id $state
    set afterId [after 250 [list ::attractor_web::__tick $id]]
    set state [dict get $servers $id]
    dict set state tick_after $afterId
    dict set servers $id $state
}

proc ::attractor_web::server_new {args} {
    variable server_seq
    variable servers

    array set opts {
        -bind 127.0.0.1
        -web_port 7070
        -runs_root .scratch/runs/attractor-web
        -max_body_bytes 2097152
        -max_question_wait_ms 300000
        -dot_bin dot
        -dot_llm_provider ""
        -dot_llm_model ""
        -dot_llm_client ""
    }
    array set opts $args

    if {![string is integer -strict $opts(-web_port)] || $opts(-web_port) < 0 || $opts(-web_port) > 65535} {
        return -code error "invalid -web_port: $opts(-web_port)"
    }

    set runsRoot [file normalize $opts(-runs_root)]
    file mkdir $runsRoot

    incr server_seq
    set id $server_seq
    set cmd ::attractor_web::server::$id

    set listener [socket -server [list ::attractor_web::__on_accept $id] -myaddr $opts(-bind) $opts(-web_port)]
    set sock [fconfigure $listener -sockname]
    set actualPort [lindex $sock 2]

    set state [dict create \
        listener $listener \
        bind $opts(-bind) \
        web_port $actualPort \
        runs_root $runsRoot \
        max_body_bytes $opts(-max_body_bytes) \
        max_question_wait_ms $opts(-max_question_wait_ms) \
        dot_bin $opts(-dot_bin) \
        dot_llm_provider $opts(-dot_llm_provider) \
        dot_llm_model $opts(-dot_llm_model) \
        dot_llm_client $opts(-dot_llm_client) \
        clients {} \
        sse_clients {} \
        workers {} \
        tick_count 0]
    dict set servers $id $state

    set afterId [after 250 [list ::attractor_web::__tick $id]]
    set state [dict get $servers $id]
    dict set state tick_after $afterId
    dict set servers $id $state

    interp alias {} $cmd {} ::attractor_web::__server_dispatch $id
    return $cmd
}

proc ::attractor_web::__server_dispatch {id method args} {
    variable servers
    if {![dict exists $servers $id]} {
        return -code error "unknown server id: $id"
    }
    set state [dict get $servers $id]

    switch -- $method {
        port {
            return [dict get $state web_port]
        }
        url {
            set host [dict get $state bind]
            if {$host eq "0.0.0.0"} {
                set host 127.0.0.1
            }
            return "http://$host:[dict get $state web_port]"
        }
        close {
            catch {after cancel [dict get $state tick_after]}
            foreach chan [dict keys [dict get $state clients]] {
                catch {close $chan}
            }
            foreach chan [dict keys [dict get $state sse_clients]] {
                catch {close $chan}
            }
            foreach chan [dict keys [dict get $state workers]] {
                catch {close $chan}
            }
            catch {close [dict get $state listener]}
            dict unset servers $id
            rename ::attractor_web::server::$id {}
            return {}
        }
        default {
            return -code error "unknown server method: $method"
        }
    }
}

proc ::attractor_web::serve {args} {
    set server [::attractor_web::server_new {*}$args]
    set waitVar ::attractor_web::__serve_wait
    set $waitVar 0
    vwait $waitVar
    return $server
}

package provide attractor_web $::attractor_web::version
