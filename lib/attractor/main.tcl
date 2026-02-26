namespace eval ::attractor {
    variable version 0.1.0
    variable runner_seq 0
    variable runners {}
}

package require Tcl 8.5
package require attractor_core
package require unified_llm
package require coding_agent_loop

proc ::attractor::__strip_comments {source} {
    set source [regsub -all {(?m)//.*$} $source ""]
    set source [regsub -all {(?m)#.*$} $source ""]
    set source [regsub -all {(?s)/\*.*?\*/} $source ""]
    return $source
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
    foreach pair [split $text ","] {
        set pair [string trim $pair]
        if {$pair eq ""} {
            continue
        }
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

    set statements [split [string map [list "\n" " "] $body] ";"]
    foreach raw $statements {
        set stmt [string trim $raw]
        if {$stmt eq ""} {
            continue
        }

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

        if {[string first "->" $stmt] >= 0} {
            set attrs {}
            if {[regexp {(.*)(\[.*\])$} $stmt -> linkPart attrPart]} {
                set stmt [string trim $linkPart]
                set attrs [::attractor::__parse_attrs $attrPart]
            }
            set parts {}
            set edgeExpr [string map [list "->" "\u001f"] $stmt]
            foreach p [split $edgeExpr "\u001f"] {
                lappend parts [string trim $p]
            }
            for {set i 0} {$i < [expr {[llength $parts] - 1}]} {incr i} {
                set from [lindex $parts $i]
                set to [lindex $parts [expr {$i + 1}]]
                if {![dict exists $nodes $from]} {
                    dict set nodes $from [dict create id $from attrs $nodeDefaults]
                }
                if {![dict exists $nodes $to]} {
                    dict set nodes $to [dict create id $to attrs $nodeDefaults]
                }
                lappend edges [dict create from $from to $to attrs [dict merge $edgeDefaults $attrs]]
            }
            continue
        }

        if {[regexp {^([A-Za-z0-9_\.]+)[[:space:]]*(\[.*\])$} $stmt -> nodeId attrs]} {
            set nodeAttrs [dict merge $nodeDefaults [::attractor::__parse_attrs $attrs]]
            dict set nodes $nodeId [dict create id $nodeId attrs $nodeAttrs]
            continue
        }

        if {[regexp {^([A-Za-z0-9_\.]+)[[:space:]]*=[[:space:]]*(.+)$} $stmt -> key value]} {
            dict set graphAttrs $key [::attractor::__parse_scalar $value]
            continue
        }

        if {[regexp {^subgraph[[:space:]]+[^\{]+\{(.*)\}$} $stmt -> subBody]} {
            # Flatten subgraph content by recursive parse.
            set partial [::attractor::parse_dot "digraph ${graphId}_sub { $subBody }"]
            set nodes [dict merge $nodes [dict get $partial nodes]]
            set edges [concat $edges [dict get $partial edges]]
            continue
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

proc ::attractor::validate {graphDict} {
    set diagnostics {}
    set nodes [dict get $graphDict nodes]
    set edges [dict get $graphDict edges]

    set starts {}
    set exits {}

    foreach nodeId [dict keys $nodes] {
        set attrs [dict get $nodes $nodeId attrs]
        if {$nodeId eq "start" || ([dict exists $attrs shape] && [dict get $attrs shape] eq "start")} {
            lappend starts $nodeId
        }
        if {$nodeId eq "exit" || ([dict exists $attrs shape] && [dict get $attrs shape] in {doublecircle exit})} {
            lappend exits $nodeId
        }
    }

    if {[llength $starts] == 0} {
        lappend diagnostics [dict create severity error code missing_start message "no start node found"]
    }
    if {[llength $starts] > 1} {
        lappend diagnostics [dict create severity error code multiple_start message "multiple start nodes found"]
    }
    if {[llength $exits] == 0} {
        lappend diagnostics [dict create severity error code missing_exit message "no exit node found"]
    }

    if {[llength $starts] == 1} {
        set start [lindex $starts 0]
        foreach edge $edges {
            if {[dict get $edge to] eq $start} {
                lappend diagnostics [dict create severity error code start_incoming message "start node must not have incoming edges"]
                break
            }
        }
    }

    if {[llength $exits] == 1} {
        set exitNode [lindex $exits 0]
        foreach edge $edges {
            if {[dict get $edge from] eq $exitNode} {
                lappend diagnostics [dict create severity error code exit_outgoing message "exit node must not have outgoing edges"]
                break
            }
        }
    }

    return $diagnostics
}

proc ::attractor::__find_start {graphDict} {
    set nodes [dict get $graphDict nodes]
    foreach nodeId [dict keys $nodes] {
        set attrs [dict get $nodes $nodeId attrs]
        if {$nodeId eq "start" || ([dict exists $attrs shape] && [dict get $attrs shape] eq "start")} {
            return $nodeId
        }
    }
    return ""
}

proc ::attractor::__find_exit {graphDict} {
    set nodes [dict get $graphDict nodes]
    foreach nodeId [dict keys $nodes] {
        set attrs [dict get $nodes $nodeId attrs]
        if {$nodeId eq "exit" || ([dict exists $attrs shape] && [dict get $attrs shape] in {doublecircle exit})} {
            return $nodeId
        }
    }
    return ""
}

proc ::attractor::__condition_matches {condition context} {
    set condition [string trim $condition]
    if {$condition eq ""} {
        return 1
    }
    if {$condition eq "true"} {
        return 1
    }
    if {$condition eq "false"} {
        return 0
    }

    if {[regexp {^([A-Za-z0-9_\.]+)[[:space:]]*==[[:space:]]*(.+)$} $condition -> key expected]} {
        set expected [string trim $expected "\" "]
        if {![dict exists $context $key]} {
            return 0
        }
        return [expr {[dict get $context $key] eq $expected}]
    }

    if {[regexp {^([A-Za-z0-9_\.]+)[[:space:]]*!=[[:space:]]*(.+)$} $condition -> key expected]} {
        set expected [string trim $expected "\" "]
        if {![dict exists $context $key]} {
            return 1
        }
        return [expr {[dict get $context $key] ne $expected}]
    }

    return 0
}

proc ::attractor::__select_next_edge {edges outcome context} {
    set candidates {}

    foreach edge $edges {
        set attrs [dict get $edge attrs]
        if {[dict exists $attrs condition]} {
            if {![::attractor::__condition_matches [dict get $attrs condition] $context]} {
                continue
            }
        }
        lappend candidates $edge
    }

    if {[llength $candidates] == 0} {
        return {}
    }

    if {[dict exists $outcome preferred_label]} {
        set preferred [dict get $outcome preferred_label]
        if {$preferred ne ""} {
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
        set attrs [dict get $edge attrs]
        set weight 0
        if {[dict exists $attrs weight] && [string is double -strict [dict get $attrs weight]]} {
            set weight [dict get $attrs weight]
        }
        lappend weighted [list $weight [dict get $edge to] $edge]
    }

    set sorted [lsort -decreasing -index 0 -real $weighted]
    set bestWeight [lindex [lindex $sorted 0] 0]
    set bestCandidates {}
    foreach item $sorted {
        if {[lindex $item 0] == $bestWeight} {
            lappend bestCandidates $item
        }
    }

    set lexical [lsort -index 1 -dictionary $bestCandidates]
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

proc ::attractor::default_interviewer {request} {
    return [dict create approved 1 response "approved"]
}

proc ::attractor::default_codergen_backend {request} {
    set prompt [dict get $request prompt]
    set response [::unified_llm::generate -prompt $prompt -provider mock]
    return [dict create text [dict get $response text] usage [dict get $response usage]]
}

proc ::attractor::__execute_handler {handler nodeId nodeAttrs context backend interviewer logsRoot} {
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
            set backendResponse [{*}$backend [dict create node_id $nodeId prompt $prompt context $context attrs $nodeAttrs]]
            set text ""
            if {[dict exists $backendResponse text]} {
                set text [dict get $backendResponse text]
            }
            return [dict create \
                status success \
                preferred_label [expr {[dict exists $backendResponse preferred_label] ? [dict get $backendResponse preferred_label] : ""}] \
                suggested_next_ids [expr {[dict exists $backendResponse suggested_next_ids] ? [dict get $backendResponse suggested_next_ids] : {}}] \
                context_updates {} \
                notes $text \
                prompt $prompt \
                response_text $text \
                terminal 0]
        }
        conditional {
            set condition [expr {[dict exists $nodeAttrs condition] ? [dict get $nodeAttrs condition] : "false"}]
            set outcome [expr {[::attractor::__condition_matches $condition $context] ? "true" : "false"}]
            return [dict create status success preferred_label $outcome suggested_next_ids {} context_updates {} notes $outcome terminal 0]
        }
        wait.human {
            set req [dict create node_id $nodeId question [expr {[dict exists $nodeAttrs question] ? [dict get $nodeAttrs question] : "Continue?"}]]
            set decision [{*}$interviewer $req]
            if {[dict exists $decision approved] && [dict get $decision approved]} {
                return [dict create status success preferred_label "approved" suggested_next_ids {} context_updates {} notes "approved" terminal 0]
            }
            return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes "rejected" terminal 1 failure_reason rejected]
        }
        parallel {
            set branches {}
            if {[dict exists $nodeAttrs branches]} {
                set branches [split [dict get $nodeAttrs branches] ","]
            }
            set suggested {}
            foreach branch $branches {
                lappend suggested [string trim $branch]
            }
            return [dict create status success preferred_label "" suggested_next_ids $suggested context_updates {} notes "parallel" terminal 0]
        }
        tool {
            if {![dict exists $nodeAttrs tool_command]} {
                return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes "missing tool_command" terminal 1 failure_reason missing_tool_command]
            }
            set cmd [dict get $nodeAttrs tool_command]
            set result [::attractor_core::exec_with_control -command [list sh -lc $cmd] -max_ms 60000]
            set out [dict get $result stdout]
            set status success
            if {[dict get $result exit_code] != 0} {
                set status failed
            }
            return [dict create status $status preferred_label "" suggested_next_ids {} context_updates {} notes $out terminal 0]
        }
        stack.manager_loop {
            return [dict create status success preferred_label "" suggested_next_ids {} context_updates {} notes "manager_loop" terminal 0]
        }
        default {
            return [dict create status failed preferred_label "" suggested_next_ids {} context_updates {} notes "unknown handler: $handler" terminal 1 failure_reason unknown_handler]
        }
    }
}

proc ::attractor::run {graphDict args} {
    array set opts {
        -backend ::attractor::default_codergen_backend
        -interviewer ::attractor::default_interviewer
        -logs_root ""
        -max_steps 200
        -resume 0
    }
    array set opts $args

    set diagnostics [::attractor::validate $graphDict]
    if {[llength $diagnostics] > 0} {
        return -code error -errorcode [list ATTRACTOR VALIDATION] $diagnostics
    }

    if {$opts(-logs_root) eq ""} {
        set opts(-logs_root) [file join .scratch runs attractor [clock seconds]]
    }

    file mkdir [file join $opts(-logs_root) artifacts]
    ::attractor::__write_json_file [file join $opts(-logs_root) manifest.json] [dict create graph_id [dict get $graphDict id] started_at [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]]

    set checkpointPath [file join $opts(-logs_root) checkpoint.json]

    set current [::attractor::__find_start $graphDict]
    set completed {}
    set context {}
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

    set exitNode [::attractor::__find_exit $graphDict]
    set nodes [dict get $graphDict nodes]
    set edges [dict get $graphDict edges]

    set steps 0
    while {$steps < $opts(-max_steps)} {
        if {$current eq ""} {
            return -code error "no current node"
        }

        if {![dict exists $nodes $current]} {
            return -code error "unknown node: $current"
        }

        set node [dict get $nodes $current]
        set attrs [dict get $node attrs]
        set handler codergen
        if {$current eq [::attractor::__find_start $graphDict]} {
            set handler start
        } elseif {$current eq $exitNode} {
            set handler exit
        } elseif {[dict exists $attrs handler]} {
            set handler [dict get $attrs handler]
        } elseif {[dict exists $attrs type]} {
            set handler [dict get $attrs type]
        }

        set outcome [::attractor::__execute_handler $handler $current $attrs $context $opts(-backend) $opts(-interviewer) $opts(-logs_root)]
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
            status [dict get $outcome status] \
            preferred_next_label $preferred \
            notes [expr {[dict exists $outcome notes] ? [dict get $outcome notes] : ""}]]

        if {[dict exists $outcome prompt]} {
            ::attractor::__write_text_file [file join $nodeDir prompt.md] [dict get $outcome prompt]
        }
        if {[dict exists $outcome response_text]} {
            ::attractor::__write_text_file [file join $nodeDir response.md] [dict get $outcome response_text]
        }

        lappend completed $current

        ::attractor::__write_json_file $checkpointPath [dict create \
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1] \
            current_node $current \
            completed_nodes $completed \
            node_retries $retries \
            context_values $context]

        if {[dict exists $outcome terminal] && [dict get $outcome terminal]} {
            return [dict create status success current_node $current completed_nodes $completed context $context logs_root $opts(-logs_root)]
        }

        set outgoing {}
        foreach edge $edges {
            if {[dict get $edge from] eq $current} {
                lappend outgoing $edge
            }
        }

        set nextEdge [::attractor::__select_next_edge $outgoing $outcome $context]
        if {[llength $nextEdge] == 0} {
            return [dict create status failed reason no_next_edge current_node $current logs_root $opts(-logs_root)]
        }

        set current [dict get $nextEdge to]
        incr steps
    }

    return [dict create status failed reason max_steps_exceeded current_node $current logs_root $opts(-logs_root)]
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

package provide attractor $::attractor::version
