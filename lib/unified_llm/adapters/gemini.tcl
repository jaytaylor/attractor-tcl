namespace eval ::unified_llm::adapters::gemini {}

package require attractor_core

proc ::unified_llm::adapters::gemini::translate_request {request} {
    set contents {}
    foreach message [dict get $request messages] {
        lappend contents [dict create role [dict get $message role] parts [list [dict create text [dict get $message content]]]]
    }

    return [dict create contents $contents]
}

proc ::unified_llm::adapters::gemini::complete {state request} {
    set model [dict get $request model]
    if {$model eq ""} {
        set model "gemini-1.5-pro"
    }

    set endpoint "/v1beta/models/${model}:generateContent"
    set payload [::unified_llm::adapters::gemini::translate_request $request]
    set headers [dict create Content-Type application/json]

    if {[dict get $state api_key] ne ""} {
        dict set headers x-goog-api-key [dict get $state api_key]
    }

    set transport [::unified_llm::adapters::__invoke_transport $state gemini $endpoint $payload $headers]
    set decoded [::attractor_core::json_decode [dict get $transport body]]

    set text ""
    if {[dict exists $decoded candidates]} {
        foreach candidate [dict get $decoded candidates] {
            if {[dict exists $candidate content parts]} {
                foreach part [dict get $candidate content parts] {
                    if {[dict exists $part text]} {
                        append text [dict get $part text]
                    }
                }
            }
        }
    } elseif {[dict exists $decoded text]} {
        set text [dict get $decoded text]
    }

    set usage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0]
    if {[dict exists $decoded usageMetadata promptTokenCount]} {
        dict set usage input_tokens [dict get $decoded usageMetadata promptTokenCount]
    }
    if {[dict exists $decoded usageMetadata candidatesTokenCount]} {
        dict set usage output_tokens [dict get $decoded usageMetadata candidatesTokenCount]
    }
    if {[dict exists $decoded usageMetadata thoughtsTokenCount]} {
        dict set usage reasoning_tokens [dict get $decoded usageMetadata thoughtsTokenCount]
    }

    set toolCalls {}
    if {[dict exists $decoded tool_calls]} {
        set toolCalls [dict get $decoded tool_calls]
    }

    set nextId 1
    set normalized {}
    foreach call $toolCalls {
        set current $call
        if {![dict exists $current id]} {
            dict set current id "gemini-tool-$nextId"
            incr nextId
        }
        lappend normalized $current
    }

    return [dict create \
        provider gemini \
        response_id gemini-response-1 \
        text $text \
        tool_calls $normalized \
        usage $usage \
        raw $decoded \
        request [dict create endpoint $endpoint payload $payload headers $headers]]
}
