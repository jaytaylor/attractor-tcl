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

proc ::unified_llm::adapters::anthropic::__dict_get_or {payload default args} {
    if {[catch {dict get $payload {*}$args} value]} {
        return $default
    }
    return $value
}

proc ::unified_llm::adapters::anthropic::__event_type {sseEvent chunk} {
    if {[dict exists $chunk type] && [dict get $chunk type] ne ""} {
        return [dict get $chunk type]
    }
    if {[dict exists $sseEvent event]} {
        return [dict get $sseEvent event]
    }
    return message
}

proc ::unified_llm::adapters::anthropic::__usage_from_payload {usage payload} {
    set merged $usage
    foreach field {input_tokens output_tokens reasoning_tokens cache_read_tokens cache_read_input_tokens cache_creation_input_tokens} {
        if {[dict exists $payload $field]} {
            switch -- $field {
                cache_read_input_tokens {
                    dict set merged cache_read_tokens [dict get $payload $field]
                }
                cache_creation_input_tokens {
                    dict set merged cache_write_tokens [dict get $payload $field]
                }
                default {
                    dict set merged $field [dict get $payload $field]
                }
            }
        }
    }
    return $merged
}

proc ::unified_llm::adapters::anthropic::stream {state request} {
    set endpoint "/v1/messages"
    set payload [::unified_llm::adapters::anthropic::translate_request $request]
    dict set payload stream true

    set headers [dict create Content-Type application/json Accept text/event-stream anthropic-version "2023-06-01"]
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
    set parsedEvents [::attractor_core::parse_sse [dict get $transport body]]

    set responseId anthropic-response-1
    set usage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0 cache_write_tokens 0]
    set metadata [dict create]
    if {[dict exists $transport headers]} {
        set h [dict get $transport headers]
        foreach key {request-id anthropic-ratelimit-remaining-requests anthropic-ratelimit-remaining-tokens} {
            if {[dict exists $h $key]} {
                dict set metadata $key [dict get $h $key]
            }
        }
    }

    array set textStarted {}
    array set textEnded {}
    array set textBuffer {}
    set textOrder {}

    array set reasoningStarted {}
    array set reasoningEnded {}

    array set blockKind {}
    array set textIdByIndex {}
    array set toolIdByIndex {}
    array set reasoningIdByIndex {}

    array set toolStarted {}
    array set toolEnded {}
    array set toolRaw {}
    array set toolName {}
    array set toolInput {}
    set toolOrder {}
    set finalizedToolCalls {}

    set translated {}
    set rawEvents {}
    set finalRaw {}
    set streamFailed 0

    foreach sseEvent $parsedEvents {
        if {$streamFailed} {
            break
        }

        set data [::unified_llm::adapters::anthropic::__dict_get_or $sseEvent "" data]
        if {$data eq "" || $data eq "\[DONE\]"} {
            continue
        }

        if {[catch {::attractor_core::json_decode $data} chunk]} {
            lappend translated [::unified_llm::__stream_event ERROR error [dict create code STREAM_INVALID_JSON provider anthropic message "invalid JSON frame in Anthropic stream" raw $data]]
            set streamFailed 1
            continue
        }

        lappend rawEvents $chunk
        set eventType [::unified_llm::adapters::anthropic::__event_type $sseEvent $chunk]
        switch -- $eventType {
            message_start {
                set responseId [::unified_llm::adapters::anthropic::__dict_get_or $chunk $responseId message id]
                set messageUsage [::unified_llm::adapters::anthropic::__dict_get_or $chunk {} message usage]
                if {$messageUsage ne {} && $messageUsage ne ""} {
                    set usage [::unified_llm::adapters::anthropic::__usage_from_payload $usage $messageUsage]
                }
            }
            content_block_start {
                set index [::unified_llm::adapters::anthropic::__dict_get_or $chunk 0 index]
                set block [::unified_llm::adapters::anthropic::__dict_get_or $chunk {} content_block]
                set blockType [::unified_llm::adapters::anthropic::__dict_get_or $block "" type]
                if {$blockType eq "text"} {
                    set textId [::unified_llm::adapters::anthropic::__dict_get_or $block "anthropic-text-$index" id]
                    set blockKind($index) text
                    set textIdByIndex($index) $textId
                    if {![info exists textStarted($textId)]} {
                        set textStarted($textId) 1
                        set textEnded($textId) 0
                        set textBuffer($textId) ""
                        lappend textOrder $textId
                        lappend translated [::unified_llm::__stream_event TEXT_START text_id $textId]
                    }
                    set initialText [::unified_llm::adapters::anthropic::__dict_get_or $block "" text]
                    if {$initialText ne ""} {
                        append textBuffer($textId) $initialText
                        lappend translated [::unified_llm::__stream_event TEXT_DELTA text_id $textId delta $initialText]
                    }
                } elseif {$blockType eq "tool_use"} {
                    set toolId [::unified_llm::adapters::anthropic::__dict_get_or $block "anthropic-tool-$index" id]
                    set blockKind($index) tool_use
                    set toolIdByIndex($index) $toolId
                    if {![info exists toolStarted($toolId)]} {
                        set toolStarted($toolId) 1
                        set toolEnded($toolId) 0
                        set toolRaw($toolId) ""
                        set toolName($toolId) [::unified_llm::adapters::anthropic::__dict_get_or $block "" name]
                        set toolInput($toolId) [::unified_llm::adapters::anthropic::__dict_get_or $block {} input]
                        lappend toolOrder $toolId
                        lappend translated [::unified_llm::__stream_event TOOL_CALL_START tool_call [dict create id $toolId name $toolName($toolId)]]
                    }
                } elseif {$blockType eq "thinking"} {
                    set reasoningId [::unified_llm::adapters::anthropic::__dict_get_or $block "anthropic-thinking-$index" id]
                    set blockKind($index) thinking
                    set reasoningIdByIndex($index) $reasoningId
                    if {![info exists reasoningStarted($reasoningId)]} {
                        set reasoningStarted($reasoningId) 1
                        set reasoningEnded($reasoningId) 0
                        lappend translated [::unified_llm::__stream_event REASONING_START text_id $reasoningId]
                    }
                } else {
                    lappend translated [::unified_llm::__stream_event PROVIDER_EVENT raw $chunk]
                }
            }
            content_block_delta {
                set index [::unified_llm::adapters::anthropic::__dict_get_or $chunk 0 index]
                set delta [::unified_llm::adapters::anthropic::__dict_get_or $chunk {} delta]
                set deltaType [::unified_llm::adapters::anthropic::__dict_get_or $delta "" type]
                if {$deltaType eq "text_delta"} {
                    set textId "anthropic-text-$index"
                    if {[info exists textIdByIndex($index)]} {
                        set textId $textIdByIndex($index)
                    }
                    set textValue [::unified_llm::adapters::anthropic::__dict_get_or $delta "" text]
                    if {![info exists textStarted($textId)]} {
                        set textStarted($textId) 1
                        set textEnded($textId) 0
                        set textBuffer($textId) ""
                        lappend textOrder $textId
                        lappend translated [::unified_llm::__stream_event TEXT_START text_id $textId]
                    }
                    append textBuffer($textId) $textValue
                    lappend translated [::unified_llm::__stream_event TEXT_DELTA text_id $textId delta $textValue]
                } elseif {$deltaType eq "input_json_delta"} {
                    set toolId "anthropic-tool-$index"
                    if {[info exists toolIdByIndex($index)]} {
                        set toolId $toolIdByIndex($index)
                    }
                    if {![info exists toolStarted($toolId)]} {
                        set toolStarted($toolId) 1
                        set toolEnded($toolId) 0
                        set toolRaw($toolId) ""
                        set toolName($toolId) ""
                        set toolInput($toolId) {}
                        lappend toolOrder $toolId
                        lappend translated [::unified_llm::__stream_event TOOL_CALL_START tool_call [dict create id $toolId name ""]]
                    }
                    set partial [::unified_llm::adapters::anthropic::__dict_get_or $delta "" partial_json]
                    append toolRaw($toolId) $partial
                    lappend translated [::unified_llm::__stream_event TOOL_CALL_DELTA tool_call [dict create id $toolId name $toolName($toolId) arguments_json $toolRaw($toolId)]]
                } elseif {$deltaType eq "thinking_delta"} {
                    set reasoningId "anthropic-thinking-$index"
                    if {[info exists reasoningIdByIndex($index)]} {
                        set reasoningId $reasoningIdByIndex($index)
                    }
                    if {![info exists reasoningStarted($reasoningId)]} {
                        set reasoningStarted($reasoningId) 1
                        set reasoningEnded($reasoningId) 0
                        lappend translated [::unified_llm::__stream_event REASONING_START text_id $reasoningId]
                    }
                    set thinkingValue [::unified_llm::adapters::anthropic::__dict_get_or $delta "" thinking]
                    if {$thinkingValue eq ""} {
                        set thinkingValue [::unified_llm::adapters::anthropic::__dict_get_or $delta "" text]
                    }
                    lappend translated [::unified_llm::__stream_event REASONING_DELTA reasoning_delta $thinkingValue]
                } else {
                    lappend translated [::unified_llm::__stream_event PROVIDER_EVENT raw $chunk]
                }
            }
            content_block_stop {
                set index [::unified_llm::adapters::anthropic::__dict_get_or $chunk 0 index]
                if {[info exists blockKind($index)] && $blockKind($index) eq "text"} {
                    set textId "anthropic-text-$index"
                    if {[info exists textIdByIndex($index)]} {
                        set textId $textIdByIndex($index)
                    }
                    if {[info exists textStarted($textId)] && !$textEnded($textId)} {
                        set textEnded($textId) 1
                        lappend translated [::unified_llm::__stream_event TEXT_END text_id $textId]
                    }
                } elseif {[info exists blockKind($index)] && $blockKind($index) eq "tool_use"} {
                    set toolId "anthropic-tool-$index"
                    if {[info exists toolIdByIndex($index)]} {
                        set toolId $toolIdByIndex($index)
                    }
                    if {[info exists toolStarted($toolId)] && !$toolEnded($toolId)} {
                        set toolEnded($toolId) 1
                        set args {}
                        if {[info exists toolRaw($toolId)] && [string length $toolRaw($toolId)] > 0} {
                            if {[catch {::attractor_core::json_decode $toolRaw($toolId)} args]} {
                                lappend translated [::unified_llm::__stream_event ERROR error [dict create code STREAM_INVALID_TOOL_ARGS provider anthropic message "invalid Anthropic tool-call arguments JSON" raw $toolRaw($toolId)]]
                                set streamFailed 1
                                continue
                            }
                        } elseif {[info exists toolInput($toolId)]} {
                            set args $toolInput($toolId)
                        }
                        set finalized [dict create id $toolId name $toolName($toolId) arguments $args]
                        lappend finalizedToolCalls $finalized
                        lappend translated [::unified_llm::__stream_event TOOL_CALL_END tool_call $finalized]
                    }
                } elseif {[info exists blockKind($index)] && $blockKind($index) eq "thinking"} {
                    set reasoningId "anthropic-thinking-$index"
                    if {[info exists reasoningIdByIndex($index)]} {
                        set reasoningId $reasoningIdByIndex($index)
                    }
                    if {[info exists reasoningStarted($reasoningId)] && !$reasoningEnded($reasoningId)} {
                        set reasoningEnded($reasoningId) 1
                        lappend translated [::unified_llm::__stream_event REASONING_END text_id $reasoningId]
                    }
                }
            }
            message_delta {
                set messageUsage [::unified_llm::adapters::anthropic::__dict_get_or $chunk {} usage]
                if {$messageUsage ne {} && $messageUsage ne ""} {
                    set usage [::unified_llm::adapters::anthropic::__usage_from_payload $usage $messageUsage]
                }
            }
            message_stop {
                set finalRaw $chunk
            }
            error {
                set errPayload [::unified_llm::adapters::anthropic::__dict_get_or $chunk {} error]
                if {$errPayload eq "" || $errPayload eq {}} {
                    set errPayload [dict create message "provider emitted stream error event" raw $chunk]
                }
                lappend translated [::unified_llm::__stream_event ERROR error [dict merge [dict create code STREAM_PROVIDER_ERROR provider anthropic] $errPayload]]
                set streamFailed 1
            }
            default {
                lappend translated [::unified_llm::__stream_event PROVIDER_EVENT raw $chunk]
            }
        }
    }

    set text ""
    foreach textId $textOrder {
        if {[info exists textBuffer($textId)]} {
            append text $textBuffer($textId)
            if {!$streamFailed && [info exists textEnded($textId)] && !$textEnded($textId)} {
                set textEnded($textId) 1
                lappend translated [::unified_llm::__stream_event TEXT_END text_id $textId]
            }
        }
    }

    set responseRaw $finalRaw
    if {$responseRaw eq {} || $responseRaw eq ""} {
        set responseRaw $rawEvents
    }

    set response [dict create \
        provider anthropic \
        response_id $responseId \
        text $text \
        tool_calls $finalizedToolCalls \
        usage $usage \
        metadata $metadata \
        raw $responseRaw \
        request [dict create endpoint $endpoint payload $payload headers [::unified_llm::adapters::__redact_headers $headers]]]

    set events [list [::unified_llm::__stream_event STREAM_START provider anthropic response_id $responseId]]
    foreach event $translated {
        lappend events $event
    }
    if {!$streamFailed} {
        lappend events [::unified_llm::__stream_event FINISH response $response usage $usage]
    }

    return [dict create events $events response $response]
}
