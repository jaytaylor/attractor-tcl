namespace eval ::unified_llm::adapters::anthropic {}

package require attractor_core

proc ::unified_llm::adapters::anthropic::__merge_same_role {messages} {
    set out {}
    foreach msg $messages {
        if {[llength $out] > 0 && [dict get [lindex $out end] role] eq [dict get $msg role]} {
            set merged [lindex $out end]
            dict set merged content "[dict get $merged content]\n[dict get $msg content]"
            set out [lreplace $out end end $merged]
        } else {
            lappend out $msg
        }
    }
    return $out
}

proc ::unified_llm::adapters::anthropic::translate_request {request} {
    set messages [::unified_llm::adapters::anthropic::__merge_same_role [dict get $request messages]]
    set anthropicMessages {}
    foreach message $messages {
        lappend anthropicMessages [dict create role [dict get $message role] content [list [dict create type text text [dict get $message content]]]]
    }

    set out [dict create \
        model [dict get $request model] \
        messages $anthropicMessages \
        max_tokens 1024]

    if {[dict exists $request tools] && [dict size [dict get $request tools]] > 0} {
        set toolsPayload {}
        foreach name [dict keys [dict get $request tools]] {
            lappend toolsPayload [dict create name $name input_schema [dict create type object properties {}]]
        }
        dict set out tools $toolsPayload
    }

    return $out
}

proc ::unified_llm::adapters::anthropic::complete {state request} {
    set endpoint "/v1/messages"
    set payload [::unified_llm::adapters::anthropic::translate_request $request]
    set headers [dict create Content-Type application/json anthropic-version "2023-06-01"]
    if {[dict get $state api_key] ne ""} {
        dict set headers x-api-key [dict get $state api_key]
    }

    set transport [::unified_llm::adapters::__invoke_transport $state anthropic $endpoint $payload $headers]
    set decoded [::attractor_core::json_decode [dict get $transport body]]

    set text ""
    if {[dict exists $decoded content]} {
        foreach part [dict get $decoded content] {
            if {[dict exists $part type] && [dict get $part type] eq "text" && [dict exists $part text]} {
                append text [dict get $part text]
            }
        }
    } elseif {[dict exists $decoded text]} {
        set text [dict get $decoded text]
    }

    set usage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0]
    if {[dict exists $decoded usage]} {
        set usage [::unified_llm::usage_add $usage [dict get $decoded usage]]
    }

    set responseId anthropic-response-1
    if {[dict exists $decoded id]} {
        set responseId [dict get $decoded id]
    }

    return [dict create \
        provider anthropic \
        response_id $responseId \
        text $text \
        tool_calls [expr {[dict exists $decoded tool_calls] ? [dict get $decoded tool_calls] : {}}] \
        usage $usage \
        raw $decoded \
        request [dict create endpoint $endpoint payload $payload headers $headers]]
}
