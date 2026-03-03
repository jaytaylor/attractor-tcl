namespace eval ::unified_llm::adapters::gemini {}

package require Tcl 8.5
package require attractor_core

proc ::unified_llm::adapters::gemini::__translate_part {part} {
    set type [dict get $part type]
    switch -- $type {
        text - thinking {
            return [dict create text [dict get $part text]]
        }
        redacted_thinking {
            set marker {[redacted thinking]}
            if {[dict exists $part data] && [dict get $part data] ne ""} {
                set marker [dict get $part data]
            }
            return [dict create text $marker]
        }
        image_url {
            return [dict create file_data [dict create file_uri [dict get $part url]]]
        }
        image_base64 {
            return [dict create inline_data [dict create mime_type [dict get $part mime_type] data [dict get $part data]]]
        }
        image_path {
            return [dict create inline_data [dict create mime_type [dict get $part mime_type] data [dict get $part base64]]]
        }
        tool_result {
            return [dict create function_response [dict create name [dict get $part name] response [dict create output [dict get $part output] is_error [dict get $part is_error] call_id [dict get $part id]]]]
        }
        default {
            return -code error -errorcode [list UNIFIED_LLM INPUT PART UNSUPPORTED] "unsupported content part for gemini: $type"
        }
    }
}

proc ::unified_llm::adapters::gemini::__translate_tools {tools} {
    set functionDecls {}
    foreach name [dict keys $tools] {
        set desc [dict get $tools $name]
        set schema [dict create type object properties {}]
        if {[dict exists $desc schema]} {
            set schema [dict get $desc schema]
        }
        lappend functionDecls [dict create name $name parameters $schema]
    }
    if {[llength $functionDecls] == 0} {
        return {}
    }
    return [list [dict create function_declarations $functionDecls]]
}

proc ::unified_llm::adapters::gemini::translate_request {request} {
    set contents {}
    set systemParts {}
    foreach message [dict get $request messages] {
        if {![dict exists $message content_parts]} {
            set message [::unified_llm::__normalize_message $message]
        }
        set parts {}
        foreach part [dict get $message content_parts] {
            lappend parts [::unified_llm::adapters::gemini::__translate_part $part]
        }
        set role [dict get $message role]
        if {$role eq "system"} {
            foreach translated $parts {
                lappend systemParts $translated
            }
            continue
        }
        if {$role eq "assistant"} {
            set role model
        }
        if {$role ni {user model}} {
            set role user
        }
        lappend contents [dict create role $role parts $parts]
    }

    set out [dict create contents $contents]
    if {[llength $systemParts] > 0} {
        dict set out systemInstruction [dict create parts $systemParts]
    }
    if {[dict exists $request tools] && [dict size [dict get $request tools]] > 0} {
        dict set out tools [::unified_llm::adapters::gemini::__translate_tools [dict get $request tools]]
    }
    if {[dict exists $request provider_options safety_settings]} {
        dict set out safetySettings [dict get $request provider_options safety_settings]
    }
    return $out
}

proc ::unified_llm::adapters::gemini::__translate_usage {decoded} {
    set usage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0 cache_write_tokens 0]

    if {[dict exists $decoded usageMetadata promptTokenCount]} {
        dict set usage input_tokens [dict get $decoded usageMetadata promptTokenCount]
    }
    if {[dict exists $decoded usageMetadata candidatesTokenCount]} {
        dict set usage output_tokens [dict get $decoded usageMetadata candidatesTokenCount]
    }
    if {[dict exists $decoded usageMetadata thoughtsTokenCount]} {
        dict set usage reasoning_tokens [dict get $decoded usageMetadata thoughtsTokenCount]
    }
    if {[dict exists $decoded usageMetadata cache_read_tokens]} {
        dict set usage cache_read_tokens [dict get $decoded usageMetadata cache_read_tokens]
    }
    if {[dict exists $decoded usageMetadata cacheTokensDetails cachedContentTokenCount]} {
        dict set usage cache_read_tokens [dict get $decoded usageMetadata cacheTokensDetails cachedContentTokenCount]
    }
    if {[dict exists $decoded usageMetadata cacheWriteTokenCount]} {
        dict set usage cache_write_tokens [dict get $decoded usageMetadata cacheWriteTokenCount]
    }

    return $usage
}

proc ::unified_llm::adapters::gemini::__extract_tool_calls {decoded} {
    set toolCalls {}

    if {[dict exists $decoded tool_calls]} {
        set toolCalls [dict get $decoded tool_calls]
    } elseif {[dict exists $decoded candidates]} {
        foreach candidate [dict get $decoded candidates] {
            if {![dict exists $candidate content parts]} {
                continue
            }
            foreach part [dict get $candidate content parts] {
                if {![dict exists $part functionCall]} {
                    continue
                }
                set functionCall [dict get $part functionCall]
                set call [dict create \
                    name [dict get $functionCall name] \
                    arguments [expr {[dict exists $functionCall args] ? [dict get $functionCall args] : {}}]]
                if {[dict exists $functionCall id]} {
                    dict set call id [dict get $functionCall id]
                }
                lappend toolCalls $call
            }
        }
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

    return $normalized
}

proc ::unified_llm::adapters::gemini::complete {state request} {
    set model "gemini-1.5-pro"
    if {[dict exists $request model] && [dict get $request model] ne ""} {
        set model [dict get $request model]
    }

    set endpoint "/v1beta/models/${model}:generateContent"
    set payload [::unified_llm::adapters::gemini::translate_request $request]
    set headers [dict create Content-Type application/json]

    if {[dict get $state api_key] ne ""} {
        dict set headers x-goog-api-key [dict get $state api_key]
    }
    if {[dict exists $request provider_options extra_headers]} {
        foreach key [dict keys [dict get $request provider_options extra_headers]] {
            dict set headers $key [dict get $request provider_options extra_headers $key]
        }
    }

    set transport [::unified_llm::adapters::__invoke_transport $state gemini $endpoint $payload $headers]
    ::unified_llm::adapters::__raise_if_error gemini $transport

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

    set responseId "gemini-response-1"
    if {[dict exists $decoded id]} {
        set responseId [dict get $decoded id]
    }

    set metadata [dict create]
    if {[dict exists $transport headers]} {
        set h [dict get $transport headers]
        foreach key {x-request-id x-ratelimit-limit-requests} {
            if {[dict exists $h $key]} {
                dict set metadata $key [dict get $h $key]
            }
        }
    }

    return [dict create \
        provider gemini \
        response_id $responseId \
        text $text \
        tool_calls [::unified_llm::adapters::gemini::__extract_tool_calls $decoded] \
        usage [::unified_llm::adapters::gemini::__translate_usage $decoded] \
        metadata $metadata \
        raw $decoded \
        request [dict create endpoint $endpoint payload $payload headers [::unified_llm::adapters::__redact_headers $headers]]]
}

proc ::unified_llm::adapters::gemini::__dict_get_or {payload default args} {
    if {[catch {dict get $payload {*}$args} value]} {
        return $default
    }
    return $value
}

proc ::unified_llm::adapters::gemini::stream {state request} {
    set model "gemini-1.5-pro"
    if {[dict exists $request model] && [dict get $request model] ne ""} {
        set model [dict get $request model]
    }

    set endpoint "/v1beta/models/${model}:streamGenerateContent?alt=sse"
    set payload [::unified_llm::adapters::gemini::translate_request $request]

    set headers [dict create Content-Type application/json Accept text/event-stream]
    if {[dict get $state api_key] ne ""} {
        dict set headers x-goog-api-key [dict get $state api_key]
    }
    if {[dict exists $request provider_options extra_headers]} {
        foreach key [dict keys [dict get $request provider_options extra_headers]] {
            dict set headers $key [dict get $request provider_options extra_headers $key]
        }
    }

    set transport [::unified_llm::adapters::__invoke_transport $state gemini $endpoint $payload $headers]
    ::unified_llm::adapters::__raise_if_error gemini $transport
    set parsedEvents [::attractor_core::parse_sse [dict get $transport body]]

    set responseId gemini-response-1
    set usage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0 cache_write_tokens 0]
    set metadata [dict create]
    if {[dict exists $transport headers]} {
        set h [dict get $transport headers]
        foreach key {x-request-id x-ratelimit-limit-requests} {
            if {[dict exists $h $key]} {
                dict set metadata $key [dict get $h $key]
            }
        }
    }

    set textId text-1
    set textStarted 0
    set textEnded 0
    set text ""

    set toolSeq 0
    set finalizedToolCalls {}
    set translated {}
    set rawEvents {}
    set finalRaw {}
    set streamFailed 0

    foreach sseEvent $parsedEvents {
        if {$streamFailed} {
            break
        }

        set data [::unified_llm::adapters::gemini::__dict_get_or $sseEvent "" data]
        if {$data eq "" || $data eq "\[DONE\]"} {
            continue
        }

        if {[catch {::attractor_core::json_decode $data} chunk]} {
            lappend translated [::unified_llm::__stream_event ERROR error [dict create code STREAM_INVALID_JSON provider gemini message "invalid JSON frame in Gemini stream" raw $data]]
            set streamFailed 1
            continue
        }

        lappend rawEvents $chunk
        if {[dict exists $chunk usageMetadata]} {
            set usage [::unified_llm::adapters::gemini::__translate_usage $chunk]
        }
        if {[dict exists $chunk id]} {
            set responseId [dict get $chunk id]
        }
        if {[dict exists $chunk error]} {
            set errPayload [dict get $chunk error]
            lappend translated [::unified_llm::__stream_event ERROR error [dict merge [dict create code STREAM_PROVIDER_ERROR provider gemini] $errPayload]]
            set streamFailed 1
            continue
        }

        set recognized 0
        if {[dict exists $chunk candidates]} {
            foreach candidate [dict get $chunk candidates] {
                if {[dict exists $candidate content parts]} {
                    foreach part [dict get $candidate content parts] {
                        if {[dict exists $part text]} {
                            if {!$textStarted} {
                                set textStarted 1
                                lappend translated [::unified_llm::__stream_event TEXT_START text_id $textId]
                            }
                            set delta [dict get $part text]
                            append text $delta
                            lappend translated [::unified_llm::__stream_event TEXT_DELTA text_id $textId delta $delta]
                            set recognized 1
                        }
                        if {[dict exists $part functionCall]} {
                            set functionCall [dict get $part functionCall]
                            set toolId [::unified_llm::adapters::gemini::__dict_get_or $functionCall "" id]
                            if {$toolId eq ""} {
                                incr toolSeq
                                set toolId "gemini-tool-$toolSeq"
                            }
                            set toolName [::unified_llm::adapters::gemini::__dict_get_or $functionCall "" name]
                            set args [::unified_llm::adapters::gemini::__dict_get_or $functionCall {} args]
                            set toolCall [dict create id $toolId name $toolName arguments $args]
                            lappend finalizedToolCalls $toolCall
                            lappend translated [::unified_llm::__stream_event TOOL_CALL_START tool_call [dict create id $toolId name $toolName]]
                            lappend translated [::unified_llm::__stream_event TOOL_CALL_END tool_call $toolCall]
                            set recognized 1
                        }
                    }
                }
                if {[dict exists $candidate finishReason] && $textStarted && !$textEnded} {
                    set textEnded 1
                    lappend translated [::unified_llm::__stream_event TEXT_END text_id $textId]
                    set recognized 1
                }
            }
        }

        if {!$recognized} {
            lappend translated [::unified_llm::__stream_event PROVIDER_EVENT raw $chunk]
        }
        set finalRaw $chunk
    }

    if {!$streamFailed && $textStarted && !$textEnded} {
        set textEnded 1
        lappend translated [::unified_llm::__stream_event TEXT_END text_id $textId]
    }

    set responseRaw $finalRaw
    if {$responseRaw eq {} || $responseRaw eq ""} {
        set responseRaw $rawEvents
    }

    set response [dict create \
        provider gemini \
        response_id $responseId \
        text $text \
        tool_calls $finalizedToolCalls \
        usage $usage \
        metadata $metadata \
        raw $responseRaw \
        request [dict create endpoint $endpoint payload $payload headers [::unified_llm::adapters::__redact_headers $headers]]]

    set events [list [::unified_llm::__stream_event STREAM_START provider gemini response_id $responseId]]
    foreach event $translated {
        lappend events $event
    }
    if {!$streamFailed} {
        lappend events [::unified_llm::__stream_event FINISH response $response usage $usage]
    }

    return [dict create events $events response $response]
}
