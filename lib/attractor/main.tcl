namespace eval ::attractor {
    variable version 0.1.0
    variable runner_seq 0
    variable runners {}
    variable custom_handlers {}
}

namespace eval ::attractor::interviewer {
    variable queue_seq 0
    variable queues {}
}

package require Tcl 8.5-
package require attractor_core
package require unified_llm
package require coding_agent_loop

proc ::attractor::__strip_comments {source} {
    set out ""
    set inQuote 0
    set i 0
    set n [string length $source]
    while {$i < $n} {
        set ch [string index $source $i]
        set next [expr {$i + 1 < $n ? [string index $source [expr {$i + 1}]] : ""}]

        if {$ch eq "\"" && ($i == 0 || [string index $source [expr {$i - 1}]] ne "\\")} {
            set inQuote [expr {!$inQuote}]
            append out $ch
            incr i
            continue
        }

        if {!$inQuote && $ch eq "/" && $next eq "/"} {
            while {$i < $n && [string index $source $i] ne "\n"} {
                incr i
            }
            continue
        }

        if {!$inQuote && $ch eq "/" && $next eq "*"} {
            incr i 2
            while {$i + 1 < $n} {
                if {[string index $source $i] eq "*" && [string index $source [expr {$i + 1}]] eq "/"} {
                    incr i 2
                    break
                }
                incr i
            }
            continue
        }

        if {!$inQuote && $ch eq "#"} {
            while {$i < $n && [string index $source $i] ne "\n"} {
                incr i
            }
            continue
        }

        append out $ch
        incr i
    }
    return $out
}

proc ::attractor::__split_statements {body} {
    set stmts {}
    set current ""
    set bracketDepth 0
    set braceDepth 0
    set inQuote 0

    foreach ch [split $body ""] {
        if {$ch eq "\"" && [string index $current end] ne "\\"} {
            set inQuote [expr {!$inQuote}]
        }

        if {!$inQuote} {
            if {$ch eq "\["} {
                incr bracketDepth
            } elseif {$ch eq "\]" && $bracketDepth > 0} {
                incr bracketDepth -1
            } elseif {$ch eq "\{"} {
                incr braceDepth
            } elseif {$ch eq "\}" && $braceDepth > 0} {
                incr braceDepth -1
            }

            if {$ch eq ";" && $bracketDepth == 0 && $braceDepth == 0} {
                set stmt [string trim $current]
                if {$stmt ne ""} {
                    lappend stmts $stmt
                }
                set current ""
                continue
            }
        }

        append current $ch
    }

    set tail [string trim $current]
    if {$tail ne ""} {
        lappend stmts $tail
    }

    return $stmts
}

proc ::attractor::__split_attr_pairs {text} {
    set out {}
    set current ""
    set inQuote 0

    foreach ch [split $text ""] {
        if {$ch eq "\"" && [string index $current end] ne "\\"} {
            set inQuote [expr {!$inQuote}]
        }
        if {!$inQuote && $ch eq ","} {
            set part [string trim $current]
            if {$part ne ""} {
                lappend out $part
            }
            set current ""
            continue
        }
        append current $ch
    }

    set tail [string trim $current]
    if {$tail ne ""} {
        lappend out $tail
    }
    return $out
}

proc ::attractor::__parse_scalar {value} {
    set value [string trim $value]
    if {[string length $value] >= 2 && [string index $value 0] eq "\"" && [string index $value end] eq "\""} {
        return [string range $value 1 end-1]
    }
    if {[regexp {^-?[0-9]+$} $value]} {
        return $value
    }
    if {[string is double -strict $value]} {
        return $value
    }
    if {[string equal -nocase $value true] || [string equal -nocase $value false]} {
        return [string tolower $value]
    }
    return $value
}

proc ::attractor::__parse_attrs {payload} {
    set text [string trim $payload]
    if {$text eq ""} {
        return {}
    }

    if {[string index $text 0] eq "\[" && [string index $text end] eq "\]"} {
        set text [string range $text 1 end-1]
    }

    set attrs {}
    foreach pair [::attractor::__split_attr_pairs $text] {
        set idx [string first "=" $pair]
        if {$idx < 0} {
            continue
        }
        set key [string trim [string range $pair 0 [expr {$idx - 1}]]]
        set value [string trim [string range $pair [expr {$idx + 1}] end]]
        dict set attrs $key [::attractor::__parse_scalar $value]
    }
    return $attrs
}

proc ::attractor::__normalize_node_id {id} {
    set id [string trim $id]
    if {[string length $id] >= 2 && [string index $id 0] eq "\"" && [string index $id end] eq "\""} {
        return [string range $id 1 end-1]
    }
    return $id
}

proc ::attractor::parse_dot {dotSource} {
    set source [::attractor::__strip_comments $dotSource]
    set source [string trim $source]

    if {![regexp {^digraph[[:space:]]+([^\{[:space:]]+)[[:space:]]*\{(.*)\}[[:space:]]*$} $source -> graphId body]} {
        return -code error "invalid digraph source"
    }

    set graphAttrs {}
    set nodeDefaults {}
    set edgeDefaults {}
    set nodes {}
    set edges {}

    foreach stmt [::attractor::__split_statements $body] {
        if {[regexp {^graph[[:space:]]*(\[.*\])$} $stmt -> attrs]} {
            set graphAttrs [dict merge $graphAttrs [::attractor::__parse_attrs $attrs]]
            continue
        }
        if {[regexp {^node[[:space:]]*(\[.*\])$} $stmt -> attrs]} {
            set nodeDefaults [dict merge $nodeDefaults [::attractor::__parse_attrs $attrs]]
            continue
        }
        if {[regexp {^edge[[:space:]]*(\[.*\])$} $stmt -> attrs]} {
            set edgeDefaults [dict merge $edgeDefaults [::attractor::__parse_attrs $attrs]]
            continue
        }

        if {[regexp {^subgraph[[:space:]]+[^\{]+\{(.*)\}$} $stmt -> subBody]} {
            set partial [::attractor::parse_dot "digraph ${graphId}_sub { $subBody }"]
            set nodes [dict merge $nodes [dict get $partial nodes]]
            set edges [concat $edges [dict get $partial edges]]
            continue
        }

        if {[string first "->" $stmt] >= 0} {
            set attrs {}
            if {[regexp {(.*)(\[.*\])$} $stmt -> linkPart attrPart]} {
                set stmt [string trim $linkPart]
                set attrs [::attractor::__parse_attrs $attrPart]
            }
            set parts {}
            set edgeExpr [string map [list "->" "\u001f"] $stmt]
            foreach p [split $edgeExpr "\u001f"] {
                lappend parts [::attractor::__normalize_node_id $p]
            }
            for {set i 0} {$i < [expr {[llength $parts] - 1}]} {incr i} {
                set from [lindex $parts $i]
                set to [lindex $parts [expr {$i + 1}]]
                if {![dict exists $nodes $from]} {
                    set implicitAttrs [dict merge $nodeDefaults [dict create __implicit 1]]
                    dict set nodes $from [dict create id $from attrs $implicitAttrs]
                }
                if {![dict exists $nodes $to]} {
                    set implicitAttrs [dict merge $nodeDefaults [dict create __implicit 1]]
                    dict set nodes $to [dict create id $to attrs $implicitAttrs]
                }
                lappend edges [dict create from $from to $to attrs [dict merge $edgeDefaults $attrs]]
            }
            continue
        }

        if {[regexp {^([^\[]+)[[:space:]]*(\[.*\])$} $stmt -> nodeId attrs]} {
            set nodeId [::attractor::__normalize_node_id $nodeId]
            set nodeAttrs [dict merge $nodeDefaults [::attractor::__parse_attrs $attrs]]
            if {[dict exists $nodeAttrs __implicit]} {
                dict unset nodeAttrs __implicit
            }
            dict set nodes $nodeId [dict create id $nodeId attrs $nodeAttrs]
            continue
        }

        if {[regexp {^([A-Za-z0-9_\.]+)[[:space:]]*=[[:space:]]*(.+)$} $stmt -> key value]} {
            dict set graphAttrs $key [::attractor::__parse_scalar $value]
            continue
        }

        set lone [::attractor::__normalize_node_id $stmt]
        if {$lone ne ""} {
            set loneAttrs $nodeDefaults
            if {[dict exists $loneAttrs __implicit]} {
                dict unset loneAttrs __implicit
            }
            dict set nodes $lone [dict create id $lone attrs $loneAttrs]
        }
    }

    return [dict create \
        id $graphId \
        graph_attrs $graphAttrs \
        node_defaults $nodeDefaults \
        edge_defaults $edgeDefaults \
        nodes $nodes \
        edges $edges]
}

proc ::attractor::__diag {severity rule message args} {
    set d [dict create severity $severity rule $rule message $message]
    foreach {k v} $args {
        dict set d $k $v
    }
    return $d
}

proc ::attractor::__find_nodes_by_shape {graphDict shape} {
    set hits {}
    foreach nodeId [dict keys [dict get $graphDict nodes]] {
        set attrs [dict get $graphDict nodes $nodeId attrs]
        if {[dict exists $attrs shape] && [dict get $attrs shape] eq $shape} {
            lappend hits $nodeId
        }
    }
    return $hits
}

proc ::attractor::validate {graphDict} {
    set diagnostics {}
    set nodes [dict get $graphDict nodes]
    set edges [dict get $graphDict edges]

    foreach nodeId [dict keys $nodes] {
        if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $nodeId]} {
            lappend diagnostics [::attractor::__diag error validation.node_id.invalid {node id must match [A-Za-z_][A-Za-z0-9_]*} node $nodeId]
        }
    }

    set starts [::attractor::__find_nodes_by_shape $graphDict Mdiamond]
    set exits [::attractor::__find_nodes_by_shape $graphDict Msquare]

    if {[llength $starts] == 0} {
        lappend diagnostics [::attractor::__diag error validation.start.required "graph must define exactly one start node with shape=Mdiamond"]
    }
    if {[llength $starts] > 1} {
        lappend diagnostics [::attractor::__diag error validation.start.unique "graph defines multiple start nodes" nodes $starts]
    }
    if {[llength $exits] == 0} {
        lappend diagnostics [::attractor::__diag error validation.exit.required "graph must define exactly one exit node with shape=Msquare"]
    }
    if {[llength $exits] > 1} {
        lappend diagnostics [::attractor::__diag error validation.exit.unique "graph defines multiple exit nodes" nodes $exits]
    }

    foreach edge $edges {
        if {![dict exists $nodes [dict get $edge from]]} {
            lappend diagnostics [::attractor::__diag error validation.edge.from_unknown "edge source node does not exist" edge $edge]
        } elseif {[dict exists $nodes [dict get $edge from] attrs __implicit] && [dict get $nodes [dict get $edge from] attrs __implicit]} {
            lappend diagnostics [::attractor::__diag error validation.edge.from_unknown "edge source node must be explicitly declared" edge $edge]
        }
        if {![dict exists $nodes [dict get $edge to]]} {
            lappend diagnostics [::attractor::__diag error validation.edge.to_unknown "edge target node does not exist" edge $edge]
        } elseif {[dict exists $nodes [dict get $edge to] attrs __implicit] && [dict get $nodes [dict get $edge to] attrs __implicit]} {
            lappend diagnostics [::attractor::__diag error validation.edge.to_unknown "edge target node must be explicitly declared" edge $edge]
        }
    }

    if {[llength $starts] == 1} {
        set start [lindex $starts 0]
        foreach edge $edges {
            if {[dict get $edge to] eq $start} {
                lappend diagnostics [::attractor::__diag error validation.start.no_incoming "start node must not have incoming edges" node $start]
                break
            }
        }
    }

    if {[llength $exits] == 1} {
        set exitNode [lindex $exits 0]
        foreach edge $edges {
            if {[dict get $edge from] eq $exitNode} {
                lappend diagnostics [::attractor::__diag error validation.exit.no_outgoing "exit node must not have outgoing edges" node $exitNode]
                break
            }
        }
    }

    if {[llength $starts] == 1} {
        set visited [dict create]
        set queue [list [lindex $starts 0]]
        while {[llength $queue] > 0} {
            set node [lindex $queue 0]
            set queue [lrange $queue 1 end]
            if {[dict exists $visited $node]} {
                continue
            }
            dict set visited $node 1
            foreach edge $edges {
                if {[dict get $edge from] eq $node} {
                    lappend queue [dict get $edge to]
                }
            }
        }

        foreach nodeId [dict keys $nodes] {
            if {![dict exists $visited $nodeId]} {
                lappend diagnostics [::attractor::__diag warning validation.node.unreachable "node is unreachable from start" node $nodeId]
            }
        }
    }

    return $diagnostics
}

proc ::attractor::__has_validation_errors {diagnostics} {
    foreach d $diagnostics {
        if {[dict get $d severity] eq "error"} {
            return 1
        }
    }
    return 0
}

proc ::attractor::__find_start {graphDict} {
    set starts [::attractor::__find_nodes_by_shape $graphDict Mdiamond]
    if {[llength $starts] == 1} {
        return [lindex $starts 0]
    }
    return ""
}

proc ::attractor::__find_exit {graphDict} {
    set exits [::attractor::__find_nodes_by_shape $graphDict Msquare]
    if {[llength $exits] == 1} {
        return [lindex $exits 0]
    }
    return ""
}

proc ::attractor::__condition_matches {condition context outcome preferredLabel} {
    set condition [string trim $condition]
    if {$condition eq "" || $condition eq "true"} {
        return 1
    }
    if {$condition eq "false"} {
        return 0
    }

    foreach clause [split $condition "&&"] {
        set clause [string trim $clause]
        if {$clause eq ""} {
            continue
        }

        if {![regexp {^([^!=]+)(!=|=)(.+)$} $clause -> lhs op rhs]} {
            return -code error "invalid condition expression: $clause"
        }

        set lhs [string trim $lhs]
        set rhs [string trim [string trim $rhs "\""]]

        set actual ""
        set exists 1
        if {$lhs eq "outcome"} {
            set actual $outcome
        } elseif {$lhs eq "preferred_label"} {
            set actual $preferredLabel
        } elseif {[string first "context." $lhs] == 0} {
            set key [string range $lhs 8 end]
            if {[dict exists $context $key]} {
                set actual [dict get $context $key]
            } else {
                set exists 0
            }
        } else {
            if {[dict exists $context $lhs]} {
                set actual [dict get $context $lhs]
            } else {
                set exists 0
            }
        }

        if {$op eq "="} {
            if {!$exists || "$actual" ne "$rhs"} {
                return 0
            }
        } else {
            if {$exists && "$actual" eq "$rhs"} {
                return 0
            }
        }
    }

    return 1
}

proc ::attractor::__select_next_edge {edges outcome context} {
    if {[llength $edges] == 0} {
        return {}
    }

    set candidates {}
    foreach edge $edges {
        set attrs [dict get $edge attrs]
        if {[dict exists $attrs condition]} {
            if {[catch {::attractor::__condition_matches [dict get $attrs condition] $context [dict get $outcome status] [expr {[dict exists $outcome preferred_label] ? [dict get $outcome preferred_label] : ""}]} match]} {
                continue
            }
            if {!$match} {
                continue
            }
        }
        lappend candidates $edge
    }

    if {[llength $candidates] == 0} {
        return {}
    }

    if {[dict exists $outcome preferred_label] && [dict get $outcome preferred_label] ne ""} {
        set preferred [dict get $outcome preferred_label]
        set filtered {}
        foreach edge $candidates {
            if {[dict exists [dict get $edge attrs] label] && [dict get [dict get $edge attrs] label] eq $preferred} {
                lappend filtered $edge
            }
        }
        if {[llength $filtered] > 0} {
            set candidates $filtered
        }
    }

    if {[dict exists $outcome suggested_next_ids] && [llength [dict get $outcome suggested_next_ids]] > 0} {
        set suggested [dict get $outcome suggested_next_ids]
        set filtered {}
        foreach edge $candidates {
            if {[lsearch -exact $suggested [dict get $edge to]] >= 0} {
                lappend filtered $edge
            }
        }
        if {[llength $filtered] > 0} {
            set candidates $filtered
        }
    }

    set weighted {}
    foreach edge $candidates {
        set weight 0
        if {[dict exists [dict get $edge attrs] weight] && [string is double -strict [dict get [dict get $edge attrs] weight]]} {
            set weight [dict get [dict get $edge attrs] weight]
        }
        lappend weighted [list $weight [dict get $edge to] $edge]
    }

    set sorted [lsort -decreasing -index 0 -real $weighted]
    set bestWeight [lindex [lindex $sorted 0] 0]
    set best {}
    foreach item $sorted {
        if {[lindex $item 0] == $bestWeight} {
            lappend best $item
        }
    }
    set lexical [lsort -index 1 -dictionary $best]
    return [lindex [lindex $lexical 0] 2]
}

proc ::attractor::__write_json_file {path payload} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts -nonewline $fh [::attractor_core::json_encode $payload]
    close $fh
}

proc ::attractor::__write_text_file {path payload} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts -nonewline $fh $payload
    close $fh
}

proc ::attractor::__timestamp_iso8601 {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]
}

proc ::attractor::__emit_event {callback runId seqVar type args} {
    if {$callback eq ""} {
        return
    }
    upvar 1 $seqVar seq
    incr seq
    set event [dict create ts [::attractor::__timestamp_iso8601] run_id $runId type $type seq $seq]
    foreach {k v} $args {
        dict set event $k $v
    }
    {*}$callback $event
}

proc ::attractor::default_interviewer {request} {
    return [::attractor::interviewer::autoapprove $request]
}

proc ::attractor::__default_provider {} {
    if {[info exists ::env(ATTRACTOR_PROVIDER)] && [string trim $::env(ATTRACTOR_PROVIDER)] ne ""} {
        return [string tolower [string trim $::env(ATTRACTOR_PROVIDER)]]
    }
    if {[info exists ::env(UNIFIED_LLM_PROVIDER)] && [string trim $::env(UNIFIED_LLM_PROVIDER)] ne ""} {
        return [string tolower [string trim $::env(UNIFIED_LLM_PROVIDER)]]
    }
    return ""
}

proc ::attractor::__default_model {provider} {
    switch -- $provider {
        openai {
            if {[info exists ::env(OPENAI_MODEL)] && [string trim $::env(OPENAI_MODEL)] ne ""} {
                return [string trim $::env(OPENAI_MODEL)]
            }
            return gpt-5.2
        }
        anthropic {
            if {[info exists ::env(ANTHROPIC_MODEL)] && [string trim $::env(ANTHROPIC_MODEL)] ne ""} {
                return [string trim $::env(ANTHROPIC_MODEL)]
            }
            return claude-haiku-4-5
        }
        gemini {
            if {[info exists ::env(GEMINI_MODEL)] && [string trim $::env(GEMINI_MODEL)] ne ""} {
                return [string trim $::env(GEMINI_MODEL)]
            }
            return gemini-3-flash-preview
        }
        default {
            return ""
        }
    }
}

proc ::attractor::default_codergen_backend {request} {
    set prompt [dict get $request prompt]
    set provider [::attractor::__default_provider]
    set model [::attractor::__default_model $provider]
    set client [::unified_llm::from_env -transport ::unified_llm::transports::https_json::call]
    set args [list -client $client -prompt $prompt -max_tool_rounds 0]
    if {$provider ne ""} {
        lappend args -provider $provider
    }
    if {$model ne ""} {
        lappend args -model $model
    }
    set code [catch {::unified_llm::generate {*}$args} response opts]
    catch {$client close}
    if {$code} {
        return -options $opts $response
    }
    return [dict create text [dict get $response text] usage [dict get $response usage]]
}

proc ::attractor::register_handler {name cmdPrefix} {
    variable custom_handlers
    dict set custom_handlers $name $cmdPrefix
}

proc ::attractor::clear_handlers {} {
    variable custom_handlers
    set custom_handlers {}
}

proc ::attractor::__expand_prompt_vars {prompt context} {
    set out $prompt
    foreach key [dict keys $context] {
        set token "\$$key"
        set out [string map [list $token [dict get $context $key]] $out]
    }
    return $out
}

proc ::attractor::__dict_get_or {mapping key fallback} {
    if {[dict exists $mapping $key]} {
        return [dict get $mapping $key]
    }
    return $fallback
}

proc ::attractor::__to_bool {value fallback} {
    set normalized [string tolower [string trim "$value"]]
    if {$normalized eq ""} {
        return $fallback
    }
    if {$normalized in {1 true yes on}} {
        return 1
    }
    if {$normalized in {0 false no off}} {
        return 0
    }
    return $fallback
}

proc ::attractor::__to_int {value fallback} {
    if {[string is integer -strict "$value"]} {
        return $value
    }
    return $fallback
}

proc ::attractor::__manager_attr {nodeAttrs context key fallback} {
    if {[dict exists $nodeAttrs $key]} {
        return [dict get $nodeAttrs $key]
    }
    if {[dict exists $context $key]} {
        return [dict get $context $key]
    }
    return $fallback
}

proc ::attractor::__manager_actions {rawActions} {
    set normalized {}
    foreach token [split "$rawActions" ","] {
        set action [string tolower [string trim $token]]
        if {$action eq ""} {
            continue
        }
        if {$action ni {observe steer wait}} {
            return -code error "unsupported manager action: $action"
        }
        if {[lsearch -exact $normalized $action] < 0} {
            lappend normalized $action
        }
    }
    if {[llength $normalized] == 0} {
        return {observe wait}
    }
    return $normalized
}

proc ::attractor::__manager_loop_write_log {logsRoot nodeId payload} {
    ::attractor::__write_json_file [file join $logsRoot $nodeId manager_loop.json] $payload
}

proc ::attractor::__handler_from_node {nodeId nodeAttrs startNode exitNode} {
    if {[dict exists $nodeAttrs type]} {
        return [dict get $nodeAttrs type]
    }
    if {[dict exists $nodeAttrs handler]} {
        return [dict get $nodeAttrs handler]
    }
    if {$nodeId eq $startNode} {
        return start
    }
    if {$nodeId eq $exitNode} {
        return exit
    }
    if {[dict exists $nodeAttrs shape]} {
        switch -- [dict get $nodeAttrs shape] {
            Mdiamond { return start }
            Msquare { return exit }
            diamond { return conditional }
            box { return codergen }
            hexagon { return wait.human }
            parallelogram { return tool }
            component { return parallel }
            tripleoctagon { return parallel.fan_in }
            house { return stack.manager_loop }
        }
    }
    return codergen
}

proc ::attractor::__execute_handler {handler nodeId nodeAttrs context backend interviewer outgoingEdges logsRoot customHandlers} {
    if {[dict exists $customHandlers $handler]} {
        return [{*}[dict get $customHandlers $handler] [dict create node_id $nodeId attrs $nodeAttrs context $context outgoing_edges $outgoingEdges logs_root $logsRoot]]
    }

    switch -- $handler {
        start {
            return [dict create status success preferred_label "" suggested_next_ids {} context_updates {} notes "start" terminal 0]
        }
        exit {
            return [dict create status success preferred_label "" suggested_next_ids {} context_updates {} notes "exit" terminal 1]
        }
        codergen {
            set prompt "node:$nodeId"
            if {[dict exists $nodeAttrs prompt]} {
                set prompt [dict get $nodeAttrs prompt]
            }
            set prompt [::attractor::__expand_prompt_vars $prompt $context]
            set backendResponse [{*}$backend [dict create node_id $nodeId prompt $prompt context $context attrs $nodeAttrs outgoing_edges $outgoingEdges]]

            set text ""
            if {[dict exists $backendResponse text]} {
                set text [dict get $backendResponse text]
            }

            set updates {}
            if {[dict exists $backendResponse context_updates]} {
                set updates [dict get $backendResponse context_updates]
            }

            return [dict create \
                status success \
                preferred_label [expr {[dict exists $backendResponse preferred_label] ? [dict get $backendResponse preferred_label] : ""}] \
                suggested_next_ids [expr {[dict exists $backendResponse suggested_next_ids] ? [dict get $backendResponse suggested_next_ids] : {}}] \
                context_updates $updates \
                notes $text \
                prompt $prompt \
                response_text $text \
                terminal 0]
        }
        conditional {
            set condition [expr {[dict exists $nodeAttrs condition] ? [dict get $nodeAttrs condition] : "false"}]
            if {[catch {::attractor::__condition_matches $condition $context success ""} matched]} {
                return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes $matched terminal 1 failure_reason invalid_condition]
            }
            set outcome [expr {$matched ? "true" : "false"}]
            return [dict create status success preferred_label $outcome suggested_next_ids {} context_updates {} notes $outcome terminal 0]
        }
        wait.human {
            set question [expr {[dict exists $nodeAttrs question] ? [dict get $nodeAttrs question] : "Continue?"}]
            set choices {}
            foreach edge $outgoingEdges {
                set label [expr {[dict exists [dict get $edge attrs] label] ? [dict get [dict get $edge attrs] label] : [dict get $edge to]}]
                lappend choices [dict create label $label to [dict get $edge to]]
            }
            set decision [{*}$interviewer [dict create node_id $nodeId question $question choices $choices context $context]]
            if {[dict exists $decision failure_reason]} {
                set failureReason [dict get $decision failure_reason]
                set failureNotes [expr {[dict exists $decision notes] ? [dict get $decision notes] : $failureReason}]
                return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes $failureNotes terminal 1 failure_reason $failureReason]
            }
            if {[dict exists $decision chosen_label]} {
                return [dict create status success preferred_label [dict get $decision chosen_label] suggested_next_ids {} context_updates {} notes "human-selected" terminal 0]
            }
            if {[dict exists $decision approved] && [dict get $decision approved]} {
                set label "approved"
                if {[llength $choices] > 0} {
                    set label [dict get [lindex $choices 0] label]
                }
                return [dict create status success preferred_label $label suggested_next_ids {} context_updates {} notes "approved" terminal 0]
            }
            return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes "rejected" terminal 1 failure_reason rejected]
        }
        parallel {
            set suggested {}
            if {[dict exists $nodeAttrs branches]} {
                foreach branch [split [dict get $nodeAttrs branches] ","] {
                    lappend suggested [string trim $branch]
                }
            } else {
                foreach edge $outgoingEdges {
                    lappend suggested [dict get $edge to]
                }
            }
            return [dict create status success preferred_label "" suggested_next_ids $suggested context_updates {} notes "parallel" terminal 0]
        }
        parallel.fan_in -
        fan-in {
            return [dict create status success preferred_label "" suggested_next_ids {} context_updates {} notes "fan-in" terminal 0]
        }
        tool {
            if {![dict exists $nodeAttrs tool_command]} {
                return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes "missing tool_command" terminal 1 failure_reason missing_tool_command]
            }
            set maxMs 60000
            if {[dict exists $nodeAttrs max_ms]} {
                set maxMs [dict get $nodeAttrs max_ms]
            }
            set result [::attractor_core::exec_with_control -command [list sh -lc [dict get $nodeAttrs tool_command]] -max_ms $maxMs]
            set out [dict get $result stdout]
            if {[dict get $result timed_out]} {
                append out "\n[CANCELLED max_ms=$maxMs]"
            }
            set status success
            if {[dict get $result exit_code] != 0} {
                set status failed
            }
            return [dict create status $status preferred_label [expr {$status eq "failed" ? "retry" : ""}] suggested_next_ids {} context_updates {} notes $out terminal 0]
        }
        stack.manager_loop {
            set childDotFile [::attractor::__manager_attr $nodeAttrs $context stack.child_dotfile ""]
            if {[string trim $childDotFile] eq ""} {
                return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes "missing stack.child_dotfile" terminal 1 failure_reason missing_child_dotfile]
            }
            if {![file exists $childDotFile]} {
                return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes "child dotfile not found: $childDotFile" terminal 1 failure_reason child_dotfile_not_found]
            }

            set maxCycles [::attractor::__to_int [::attractor::__manager_attr $nodeAttrs $context manager.max_cycles 10] 10]
            if {$maxCycles < 1} {
                set maxCycles 1
            }
            set pollMs [::attractor::__to_int [::attractor::__manager_attr $nodeAttrs $context manager.poll_interval 0] 0]
            if {$pollMs < 0} {
                set pollMs 0
            }
            set stopCondition [string trim [::attractor::__manager_attr $nodeAttrs $context manager.stop_condition ""]]
            if {[catch {::attractor::__manager_actions [::attractor::__manager_attr $nodeAttrs $context manager.actions "observe,wait"]} actionsErr]} {
                return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes $actionsErr terminal 1 failure_reason invalid_manager_actions]
            }
            set actions $actionsErr
            set autostart [::attractor::__to_bool [::attractor::__manager_attr $nodeAttrs $context stack.child_autostart true] 1]
            set childLogsRoot [file join $logsRoot $nodeId child]

            set cycles {}
            set childStatus not_started
            set childCurrentNode ""
            set childCompletedCount 0
            set childReason ""
            set childRunStarted 0
            set lastContextUpdate {}

            for {set cycle 1} {$cycle <= $maxCycles} {incr cycle} {
                set cycleRecord [dict create cycle $cycle actions $actions child_status $childStatus]

                if {!$childRunStarted && $autostart} {
                    set childRunStarted 1
                    dict set cycleRecord autostarted 1

                    if {[catch {
                        set childSourceFile [open $childDotFile r]
                        set childSource [read $childSourceFile]
                        close $childSourceFile
                        set childGraph [::attractor::parse_dot $childSource]
                        set childResult [::attractor::run $childGraph -backend $backend -interviewer $interviewer -logs_root $childLogsRoot]
                    } childErr]} {
                        set childStatus failed
                        set childReason child_launch_failed
                        dict set cycleRecord child_status $childStatus
                        dict set cycleRecord failure_reason $childReason
                        dict set cycleRecord notes $childErr
                        lappend cycles $cycleRecord
                        set telemetry [dict create node_id $nodeId child_dotfile $childDotFile actions $actions max_cycles $maxCycles poll_interval_ms $pollMs cycles $cycles final_status failed failure_reason $childReason]
                        ::attractor::__manager_loop_write_log $logsRoot $nodeId $telemetry
                        return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes $childErr terminal 1 failure_reason $childReason]
                    }

                    set childStatus [::attractor::__dict_get_or $childResult status failed]
                    set childCurrentNode [::attractor::__dict_get_or $childResult current_node ""]
                    if {[dict exists $childResult completed_nodes]} {
                        set childCompletedCount [llength [dict get $childResult completed_nodes]]
                    }
                    if {[dict exists $childResult reason]} {
                        set childReason [dict get $childResult reason]
                    } else {
                        set childReason ""
                    }
                    dict set cycleRecord child_status $childStatus
                } else {
                    dict set cycleRecord autostarted 0
                }

                if {[lsearch -exact $actions observe] >= 0} {
                    dict set cycleRecord observed 1
                }
                if {[lsearch -exact $actions steer] >= 0} {
                    dict set cycleRecord steered 1
                }
                if {[lsearch -exact $actions wait] >= 0} {
                    dict set cycleRecord waited [expr {$pollMs > 0 ? $pollMs : 0}]
                }

                set lastContextUpdate [dict create \
                    context.stack.child.status $childStatus \
                    context.stack.child.logs_root $childLogsRoot \
                    context.stack.child.current_node $childCurrentNode \
                    context.stack.child.completed_nodes_count $childCompletedCount \
                    context.stack.child.cycle $cycle \
                    context.stack.child.reason $childReason]
                dict set cycleRecord context_updates $lastContextUpdate
                lappend cycles $cycleRecord

                if {$stopCondition ne ""} {
                    if {[catch {::attractor::__condition_matches $stopCondition $lastContextUpdate $childStatus ""} stopMatch]} {
                        set telemetry [dict create node_id $nodeId child_dotfile $childDotFile actions $actions max_cycles $maxCycles poll_interval_ms $pollMs cycles $cycles final_status failed failure_reason invalid_stop_condition]
                        ::attractor::__manager_loop_write_log $logsRoot $nodeId $telemetry
                        return [dict create status failed preferred_label "" suggested_next_ids {} context_updates $lastContextUpdate notes $stopMatch terminal 1 failure_reason invalid_stop_condition]
                    }
                    if {$stopMatch} {
                        set telemetry [dict create node_id $nodeId child_dotfile $childDotFile actions $actions max_cycles $maxCycles poll_interval_ms $pollMs cycles $cycles final_status success]
                        ::attractor::__manager_loop_write_log $logsRoot $nodeId $telemetry
                        return [dict create status success preferred_label "" suggested_next_ids {} context_updates $lastContextUpdate notes "manager_loop stop condition met" terminal 0]
                    }
                }

                if {$childStatus eq "success"} {
                    set telemetry [dict create node_id $nodeId child_dotfile $childDotFile actions $actions max_cycles $maxCycles poll_interval_ms $pollMs cycles $cycles final_status success]
                    ::attractor::__manager_loop_write_log $logsRoot $nodeId $telemetry
                    return [dict create status success preferred_label "" suggested_next_ids {} context_updates $lastContextUpdate notes "manager_loop child success" terminal 0]
                }
                if {$childStatus eq "failed"} {
                    if {$childReason eq ""} {
                        set childReason child_failed
                    }
                    set telemetry [dict create node_id $nodeId child_dotfile $childDotFile actions $actions max_cycles $maxCycles poll_interval_ms $pollMs cycles $cycles final_status failed failure_reason $childReason]
                    ::attractor::__manager_loop_write_log $logsRoot $nodeId $telemetry
                    return [dict create status failed preferred_label "" suggested_next_ids {} context_updates $lastContextUpdate notes "manager_loop child failed" terminal 1 failure_reason $childReason]
                }

                if {[lsearch -exact $actions wait] >= 0 && $pollMs > 0} {
                    after $pollMs
                }
            }

            set telemetry [dict create node_id $nodeId child_dotfile $childDotFile actions $actions max_cycles $maxCycles poll_interval_ms $pollMs cycles $cycles final_status failed failure_reason max_cycles_exceeded]
            ::attractor::__manager_loop_write_log $logsRoot $nodeId $telemetry
            return [dict create status failed preferred_label "" suggested_next_ids {} context_updates $lastContextUpdate notes "manager_loop max cycles exceeded" terminal 1 failure_reason max_cycles_exceeded]
        }
        default {
            return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes "unknown handler: $handler" terminal 1 failure_reason unknown_handler]
        }
    }
}

proc ::attractor::parse_stylesheet {payload} {
    set rules {}
    foreach stmt [::attractor::__split_statements $payload] {
        if {![regexp {^([^\{]+)\{(.*)\}$} $stmt -> selector attrsPayload]} {
            continue
        }
        set selector [string trim $selector]
        set attrs [::attractor::__parse_attrs "\[$attrsPayload\]"]

        set specificity 1
        if {[string first "#" $selector] == 0} {
            set specificity 100
        } elseif {[string first "." $selector] == 0} {
            set specificity 10
        }

        lappend rules [dict create selector $selector specificity $specificity attrs $attrs]
    }
    return $rules
}

proc ::attractor::__selector_matches {selector nodeId attrs} {
    if {[string first "#" $selector] == 0} {
        return [expr {$nodeId eq [string range $selector 1 end]}]
    }
    if {[string first "." $selector] == 0} {
        if {![dict exists $attrs class]} {
            return 0
        }
        return [expr {[lsearch -exact [split [dict get $attrs class] " "] [string range $selector 1 end]] >= 0}]
    }
    if {[regexp {^shape=(.+)$} $selector -> shape]} {
        return [expr {[dict exists $attrs shape] && [dict get $attrs shape] eq $shape}]
    }
    return 0
}

proc ::attractor::apply_stylesheet {graphDict rules} {
    set out $graphDict
    foreach nodeId [dict keys [dict get $graphDict nodes]] {
        set attrs [dict get $graphDict nodes $nodeId attrs]
        set matched {}
        foreach rule $rules {
            if {[::attractor::__selector_matches [dict get $rule selector] $nodeId $attrs]} {
                lappend matched $rule
            }
        }
        if {[llength $matched] == 0} {
            continue
        }
        set sortable {}
        foreach r $matched {
            lappend sortable [list [dict get $r selector] [dict get $r specificity] $r]
        }
        set sorted [lsort -integer -increasing -index 1 $sortable]
        foreach item $sorted {
            set attrs [dict merge $attrs [dict get [lindex $item 2] attrs]]
        }
        dict set out nodes $nodeId attrs $attrs
    }
    return $out
}

proc ::attractor::run {graphDict args} {
    array set opts {
        -backend ::attractor::default_codergen_backend
        -interviewer ::attractor::default_interviewer
        -logs_root ""
        -max_steps 200
        -resume 0
        -transforms {}
        -stylesheet ""
        -handlers {}
        -on_event ""
        -run_id ""
    }
    array set opts $args

    set graph $graphDict
    foreach transform $opts(-transforms) {
        set graph [{*}$transform $graph]
    }

    if {$opts(-stylesheet) ne ""} {
        set graph [::attractor::apply_stylesheet $graph [::attractor::parse_stylesheet $opts(-stylesheet)]]
    } elseif {[dict exists $graph graph_attrs model_stylesheet]} {
        set graph [::attractor::apply_stylesheet $graph [::attractor::parse_stylesheet [dict get $graph graph_attrs model_stylesheet]]]
    }

    set diagnostics [::attractor::validate $graph]
    if {[::attractor::__has_validation_errors $diagnostics]} {
        return -code error -errorcode [list ATTRACTOR VALIDATION] $diagnostics
    }

    if {$opts(-logs_root) eq ""} {
        set opts(-logs_root) [file join .scratch runs attractor [clock seconds]]
    }
    set runId $opts(-run_id)
    if {$runId eq ""} {
        set runId [file tail $opts(-logs_root)]
    }

    file mkdir [file join $opts(-logs_root) artifacts]
    ::attractor::__write_json_file [file join $opts(-logs_root) manifest.json] [dict create graph_id [dict get $graph id] started_at [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]]

    set checkpointPath [file join $opts(-logs_root) checkpoint.json]

    set current [::attractor::__find_start $graph]
    set completed {}
    set context [dict get $graph graph_attrs]
    set retries {}

    if {$opts(-resume) && [file exists $checkpointPath]} {
        set fh [open $checkpointPath r]
        set checkpoint [::attractor_core::json_decode [read $fh]]
        close $fh
        set current [dict get $checkpoint current_node]
        set completed [dict get $checkpoint completed_nodes]
        set context [dict get $checkpoint context_values]
        set retries [dict get $checkpoint node_retries]
    }

    set exitNode [::attractor::__find_exit $graph]
    set nodes [dict get $graph nodes]
    set edges [dict get $graph edges]

    set customHandlers $::attractor::custom_handlers
    if {[catch {dict size $opts(-handlers)}] == 0} {
        set customHandlers [dict merge $customHandlers $opts(-handlers)]
    }

    set steps 0
    set eventSeq 0
    ::attractor::__emit_event $opts(-on_event) $runId eventSeq PipelineStarted
    while {$steps < $opts(-max_steps)} {
        if {$current eq ""} {
            return -code error "no current node"
        }
        if {![dict exists $nodes $current]} {
            return -code error "unknown node: $current"
        }

        set node [dict get $nodes $current]
        set attrs [dict get $node attrs]
        set handler [::attractor::__handler_from_node $current $attrs [::attractor::__find_start $graph] $exitNode]

        set outgoing {}
        foreach edge $edges {
            if {[dict get $edge from] eq $current} {
                lappend outgoing $edge
            }
        }

        ::attractor::__emit_event $opts(-on_event) $runId eventSeq StageStarted node_id $current handler $handler
        set outcome [::attractor::__execute_handler $handler $current $attrs $context $opts(-backend) $opts(-interviewer) $outgoing $opts(-logs_root) $customHandlers]

        if {[dict exists $attrs goal_key] && [dict exists $attrs goal_value]} {
            set goalKey [dict get $attrs goal_key]
            set goalValue [dict get $attrs goal_value]
            if {![dict exists $context $goalKey] || [dict get $context $goalKey] ne $goalValue} {
                dict set outcome status failed
                dict set outcome preferred_label retry
                dict set outcome notes "goal gate not satisfied"
            }
        }

        if {[dict exists $outcome context_updates]} {
            set context [dict merge $context [dict get $outcome context_updates]]
        }

        set nodeDir [file join $opts(-logs_root) $current]
        set preferred ""
        if {[dict exists $outcome preferred_label]} {
            set preferred [dict get $outcome preferred_label]
        }
        ::attractor::__write_json_file [file join $nodeDir status.json] [dict create \
            node_id $current \
            handler $handler \
            status [dict get $outcome status] \
            preferred_next_label $preferred \
            notes [expr {[dict exists $outcome notes] ? [dict get $outcome notes] : ""}]]

        if {[dict exists $outcome prompt]} {
            ::attractor::__write_text_file [file join $nodeDir prompt.md] [dict get $outcome prompt]
        }
        if {[dict exists $outcome response_text]} {
            ::attractor::__write_text_file [file join $nodeDir response.md] [dict get $outcome response_text]
        }

        ::attractor::__emit_event $opts(-on_event) $runId eventSeq StageCompleted \
            node_id $current \
            handler $handler \
            status [dict get $outcome status] \
            preferred_next_label $preferred

        lappend completed $current

        ::attractor::__write_json_file $checkpointPath [dict create \
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1] \
            current_node $current \
            completed_nodes $completed \
            node_retries $retries \
            context_values $context]
        ::attractor::__emit_event $opts(-on_event) $runId eventSeq CheckpointSaved node_id $current

        if {[dict exists $outcome terminal] && [dict get $outcome terminal]} {
            if {[dict get $outcome status] eq "success"} {
                ::attractor::__emit_event $opts(-on_event) $runId eventSeq PipelineCompleted status success current_node $current
                return [dict create status success current_node $current completed_nodes $completed context $context logs_root $opts(-logs_root) diagnostics $diagnostics]
            }
            set failureReason [expr {[dict exists $outcome failure_reason] ? [dict get $outcome failure_reason] : "handler_failed"}]
            ::attractor::__emit_event $opts(-on_event) $runId eventSeq PipelineCompleted status failed current_node $current reason $failureReason
            return [dict create status failed reason $failureReason current_node $current completed_nodes $completed context $context logs_root $opts(-logs_root) diagnostics $diagnostics]
        }

        set nextEdge [::attractor::__select_next_edge $outgoing $outcome $context]
        if {[llength $nextEdge] == 0} {
            ::attractor::__emit_event $opts(-on_event) $runId eventSeq PipelineCompleted status failed current_node $current reason no_next_edge
            return [dict create status failed reason no_next_edge current_node $current logs_root $opts(-logs_root) diagnostics $diagnostics]
        }

        set current [dict get $nextEdge to]
        incr steps
    }

    ::attractor::__emit_event $opts(-on_event) $runId eventSeq PipelineCompleted status failed current_node $current reason max_steps_exceeded
    return [dict create status failed reason max_steps_exceeded current_node $current logs_root $opts(-logs_root) diagnostics $diagnostics]
}

proc ::attractor::runner {subcommand args} {
    switch -- $subcommand {
        new {
            return [::attractor::runner_new {*}$args]
        }
        default {
            return -code error "unknown runner subcommand: $subcommand"
        }
    }
}

proc ::attractor::runner_new {graphDict args} {
    variable runner_seq
    variable runners

    incr runner_seq
    set id $runner_seq
    set cmd ::attractor::runner::$id

    set state [dict create graph $graphDict options $args subscribers {}]
    dict set runners $id $state
    interp alias {} $cmd {} ::attractor::__runner_dispatch $id
    return $cmd
}

proc ::attractor::__runner_dispatch {id method args} {
    variable runners
    if {![dict exists $runners $id]} {
        return -code error "unknown runner: $id"
    }

    switch -- $method {
        run {
            set graph [dict get $runners $id graph]
            set options [dict get $runners $id options]
            return [::attractor::run $graph {*}$options]
        }
        subscribe {
            if {[llength $args] != 1} {
                return -code error "usage: \$runner subscribe cmdPrefix"
            }
            set state [dict get $runners $id]
            set subscribers [dict get $state subscribers]
            lappend subscribers [lindex $args 0]
            dict set state subscribers $subscribers
            dict set runners $id $state
            return {}
        }
        close {
            rename ::attractor::runner::$id {}
            dict unset runners $id
            return {}
        }
        default {
            return -code error "unknown runner method: $method"
        }
    }
}

proc ::attractor::interviewer::autoapprove {request} {
    set choices {}
    if {[dict exists $request choices]} {
        set choices [dict get $request choices]
    }
    if {[llength $choices] > 0} {
        return [dict create approved 1 chosen_label [dict get [lindex $choices 0] label]]
    }
    return [dict create approved 1]
}

proc ::attractor::interviewer::queue_new {answers} {
    variable queue_seq
    variable queues

    incr queue_seq
    set id $queue_seq
    set cmd ::attractor::interviewer::queue::$id

    dict set queues $id [dict create answers $answers]
    interp alias {} $cmd {} ::attractor::interviewer::__queue_dispatch $id
    return $cmd
}

proc ::attractor::interviewer::__queue_dispatch {id request} {
    variable queues
    if {![dict exists $queues $id]} {
        return -code error "unknown interviewer queue id: $id"
    }
    set state [dict get $queues $id]
    set answers [dict get $state answers]
    if {[llength $answers] == 0} {
        return [::attractor::interviewer::autoapprove $request]
    }
    set answer [lindex $answers 0]
    set answers [lrange $answers 1 end]
    dict set state answers $answers
    dict set queues $id $state
    return [dict create approved 1 chosen_label $answer]
}

proc ::attractor::interviewer::callback_new {cmdPrefix} {
    return [list ::attractor::interviewer::__callback_dispatch $cmdPrefix]
}

proc ::attractor::interviewer::__callback_dispatch {cmdPrefix request} {
    return [{*}$cmdPrefix $request]
}

proc ::attractor::interviewer::console {request} {
    puts "[dict get $request question]"
    if {[dict exists $request choices]} {
        set idx 1
        foreach choice [dict get $request choices] {
            puts "$idx. [dict get $choice label]"
            incr idx
        }
        flush stdout
        gets stdin selected
        if {[string is integer -strict $selected]} {
            set selected [expr {$selected - 1}]
            if {$selected >= 0 && $selected < [llength [dict get $request choices]]} {
                return [dict create approved 1 chosen_label [dict get [lindex [dict get $request choices] $selected] label]]
            }
        }
    }
    return [dict create approved 1]
}

package provide attractor $::attractor::version
