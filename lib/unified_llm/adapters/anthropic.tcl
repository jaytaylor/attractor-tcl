namespace eval ::unified_llm::adapters::anthropic {}

package require Tcl 8.5
package require attractor_core

proc ::unified_llm::adapters::anthropic::__merge_same_role {messages} {
    set out {}
    foreach msg $messages {
        if {[llength $out] > 0 && [dict get [lindex $out end] role] eq [dict get $msg role]} {
            set merged [lindex $out end]
            set mergedParts [dict get $merged content_parts]
            foreach part [dict get $msg content_parts] {
                lappend mergedParts $part
            }
            dict set merged content_parts $mergedParts
            set out [lreplace $out end end $merged]
        } else {
            lappend out $msg
        }
    }
    return $out
}

proc ::unified_llm::adapters::anthropic::__translate_part {part} {
    set type [dict get $part type]
    switch -- $type {
        text - thinking {
            return [dict create type text text [dict get $part text]]
        }
        image_url {
            return [dict create type image source [dict create type url url [dict get $part url]]]
        }
        image_base64 {
            return [dict create type image source [dict create type base64 media_type [dict get $part mime_type] data [dict get $part data]]]
        }
        image_path {
            return [dict create type image source [dict create type base64 media_type [dict get $part mime_type] data [dict get $part base64]]]
        }
        tool_result {
            return [dict create type tool_result tool_use_id [dict get $part id] content [dict get $part output] is_error [dict get $part is_error]]
        }
        default {
            return -code error -errorcode [list UNIFIED_LLM INPUT PART UNSUPPORTED] "unsupported content part for anthropic: $type"
        }
    }
}

proc ::unified_llm::adapters::anthropic::__translate_tools {tools} {
    set toolsPayload {}
    foreach name [dict keys $tools] {
        set desc [dict get $tools $name]
        set schema [dict create type object properties {}]
        if {[dict exists $desc schema]} {
            set schema [dict get $desc schema]
        }
        lappend toolsPayload [dict create name $name input_schema $schema]
    }
    return $toolsPayload
}

proc ::unified_llm::adapters::anthropic::translate_request {request} {
    set normalizedMessages {}
    foreach msg [dict get $request messages] {
        if {[dict exists $msg content_parts]} {
            lappend normalizedMessages $msg
        } else {
            lappend normalizedMessages [::unified_llm::__normalize_message $msg]
        }
    }

    set merged [::unified_llm::adapters::anthropic::__merge_same_role $normalizedMessages]
    set anthropicMessages {}
    set systemParts {}

    foreach message $merged {
        set convertedParts {}
        foreach part [dict get $message content_parts] {
            lappend convertedParts [::unified_llm::adapters::anthropic::__translate_part $part]
        }
        set role [dict get $message role]
        if {$role eq "system"} {
            foreach converted $convertedParts {
                lappend systemParts $converted
            }
            continue
        }
        lappend anthropicMessages [dict create role $role content $convertedParts]
    }

    set out [dict create messages $anthropicMessages max_tokens 1024]
    if {[llength $systemParts] > 0} {
        dict set out system $systemParts
    }
    if {[dict exists $request model] && [dict get $request model] ne ""} {
        dict set out model [dict get $request model]
    }
    if {[dict exists $request tools] && [dict size [dict get $request tools]] > 0} {
        dict set out tools [::unified_llm::adapters::anthropic::__translate_tools [dict get $request tools]]
    }
    if {[dict exists $request continuation_from]} {
        dict set out continuation_from [dict get $request continuation_from]
    }

    return $out
}

proc ::unified_llm::adapters::anthropic::__translate_usage {decoded} {
    set usage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0 cache_write_tokens 0]
    if {![dict exists $decoded usage]} {
        return $usage
    }

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
    if {[dict exists $rawUsage cache_read_tokens]} {
        dict set usage cache_read_tokens [dict get $rawUsage cache_read_tokens]
    }
    if {[dict exists $rawUsage cache_read_input_tokens]} {
        dict set usage cache_read_tokens [dict get $rawUsage cache_read_input_tokens]
    }
    if {[dict exists $rawUsage cache_creation_input_tokens]} {
        dict set usage cache_write_tokens [dict get $rawUsage cache_creation_input_tokens]
    }

    return $usage
}

proc ::unified_llm::adapters::anthropic::__extract_tool_calls {decoded} {
    set calls {}

    if {[dict exists $decoded tool_calls]} {
        return [dict get $decoded tool_calls]
    }

    if {![dict exists $decoded content]} {
        return $calls
    }

    set idx 1
    foreach part [dict get $decoded content] {
        if {![dict exists $part type] || [dict get $part type] ne "tool_use"} {
            continue
        }
        set call [dict create name [dict get $part name] arguments [dict get $part input]]
        if {[dict exists $part id]} {
            dict set call id [dict get $part id]
        } else {
            dict set call id "anthropic-tool-$idx"
            incr idx
        }
        lappend calls $call
    }

    return $calls
}

proc ::unified_llm::adapters::anthropic::complete {state request} {
    set endpoint "/v1/messages"
    set payload [::unified_llm::adapters::anthropic::translate_request $request]

    set headers [dict create Content-Type application/json anthropic-version "2023-06-01"]
    if {[dict get $state api_key] ne ""} {
        dict set headers x-api-key [dict get $state api_key]
    }
    if {[dict exists $request provider_options beta_headers]} {
        dict set headers anthropic-beta [join [dict get $request provider_options beta_headers] ","]
    }
    if {[dict exists $request provider_options extra_headers]} {
        foreach key [dict keys [dict get $request provider_options extra_headers]] {
            dict set headers $key [dict get $request provider_options extra_headers $key]
        }
    }

    set transport [::unified_llm::adapters::__invoke_transport $state anthropic $endpoint $payload $headers]
    ::unified_llm::adapters::__raise_if_error anthropic $transport

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

    set responseId "anthropic-response-1"
    if {[dict exists $decoded id]} {
        set responseId [dict get $decoded id]
    }

    set metadata [dict create]
    if {[dict exists $transport headers]} {
        set h [dict get $transport headers]
        foreach key {request-id anthropic-ratelimit-remaining-requests anthropic-ratelimit-remaining-tokens} {
            if {[dict exists $h $key]} {
                dict set metadata $key [dict get $h $key]
            }
        }
    }

    return [dict create \
        provider anthropic \
        response_id $responseId \
        text $text \
        tool_calls [::unified_llm::adapters::anthropic::__extract_tool_calls $decoded] \
        usage [::unified_llm::adapters::anthropic::__translate_usage $decoded] \
        metadata $metadata \
        raw $decoded \
        request [dict create endpoint $endpoint payload $payload headers [::unified_llm::adapters::__redact_headers $headers]]]
}

proc ::unified_llm::adapters::anthropic::stream {state request} {
    set response [::unified_llm::adapters::anthropic::complete $state $request]
    set events [list [dict create type STREAM_START provider anthropic response_id [dict get $response response_id]]]
    foreach chunk [::unified_llm::adapters::__chunk_text [dict get $response text] 16] {
        lappend events [dict create type TEXT_DELTA delta $chunk]
    }
    foreach call [dict get $response tool_calls] {
        lappend events [dict create type TOOL_CALL_END tool_call $call]
    }
    lappend events [dict create type FINISH response $response usage [dict get $response usage]]
    return [dict create events $events response $response]
}
