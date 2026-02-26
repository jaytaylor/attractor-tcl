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
    if {[dict exists $request provider_options]} {
        dict set out provider_options [dict get $request provider_options]
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
        set rawUsage [dict get $decoded usage]
        if {[dict exists $rawUsage input_tokens]} {
            dict set usage input_tokens [dict get $rawUsage input_tokens]
        }
        if {[dict exists $rawUsage output_tokens]} {
            dict set usage output_tokens [dict get $rawUsage output_tokens]
        }
        if {[dict exists $rawUsage reasoning_tokens]} {
            dict set usage reasoning_tokens [dict get $rawUsage reasoning_tokens]
        }
        if {[dict exists $rawUsage output_tokens_details reasoning_tokens]} {
            dict set usage reasoning_tokens [dict get $rawUsage output_tokens_details reasoning_tokens]
        }
        if {[dict exists $rawUsage cache_read_tokens]} {
            dict set usage cache_read_tokens [dict get $rawUsage cache_read_tokens]
        }
        if {[dict exists $rawUsage input_tokens_details cached_tokens]} {
            dict set usage cache_read_tokens [dict get $rawUsage input_tokens_details cached_tokens]
        }
    }

    set responseId openai-response-1
    if {[dict exists $decoded id]} {
        set responseId [dict get $decoded id]
    }

    set metadata [dict create]
    if {[dict exists $transport headers]} {
        set h [dict get $transport headers]
        foreach key {x-request-id openai-processing-ms openai-version} {
            if {[dict exists $h $key]} {
                dict set metadata $key [dict get $h $key]
            }
        }
    }

    return [dict create \
        provider openai \
        response_id $responseId \
        text $text \
        tool_calls $toolCalls \
        usage $usage \
        metadata $metadata \
        raw $decoded \
        request [dict create endpoint $endpoint payload $payload headers $headers]]
}
