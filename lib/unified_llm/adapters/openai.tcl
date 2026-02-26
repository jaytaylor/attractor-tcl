namespace eval ::unified_llm::adapters::openai {}
namespace eval ::unified_llm::adapters {}

package require json
package require attractor_core

proc ::unified_llm::adapters::__invoke_transport {state provider endpoint payload headers} {
    if {[dict exists $state transport] && [dict get $state transport] ne ""} {
        set cmd [dict get $state transport]
        return [{*}$cmd [dict create \
            provider $provider \
            endpoint $endpoint \
            payload $payload \
            headers $headers]]
    }

    return [dict create \
        status_code 200 \
        headers {} \
        body [::attractor_core::json_encode [dict create output_text "offline-$provider" usage [dict create input_tokens 1 output_tokens 1 reasoning_tokens 0 cache_read_tokens 0]]]]
}

proc ::unified_llm::adapters::openai::translate_request {request} {
    set inputItems {}
    foreach message [dict get $request messages] {
        lappend inputItems [dict create role [dict get $message role] content [dict get $message content]]
    }

    set out [dict create \
        model [dict get $request model] \
        input $inputItems]

    if {[dict exists $request tool_results]} {
        dict set out tool_results [dict get $request tool_results]
    }

    return $out
}

proc ::unified_llm::adapters::openai::complete {state request} {
    set endpoint "/v1/responses"

    set payload [::unified_llm::adapters::openai::translate_request $request]
    set headers [dict create Content-Type application/json]
    if {[dict get $state api_key] ne ""} {
        dict set headers Authorization "Bearer [dict get $state api_key]"
    }

    set transport [::unified_llm::adapters::__invoke_transport $state openai $endpoint $payload $headers]
    set body [dict get $transport body]
    set decoded [::attractor_core::json_decode $body]

    set text ""
    if {[dict exists $decoded output_text]} {
        set text [dict get $decoded output_text]
    } elseif {[dict exists $decoded text]} {
        set text [dict get $decoded text]
    }

    set toolCalls {}
    if {[dict exists $decoded tool_calls]} {
        set toolCalls [dict get $decoded tool_calls]
    }

    set usage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0]
    if {[dict exists $decoded usage]} {
        set usage [::unified_llm::usage_add $usage [dict get $decoded usage]]
    }

    set responseId openai-response-1
    if {[dict exists $decoded id]} {
        set responseId [dict get $decoded id]
    }

    return [dict create \
        provider openai \
        response_id $responseId \
        text $text \
        tool_calls $toolCalls \
        usage $usage \
        raw $decoded \
        request [dict create endpoint $endpoint payload $payload headers $headers]]
}
