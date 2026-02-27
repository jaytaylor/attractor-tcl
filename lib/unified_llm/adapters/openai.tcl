namespace eval ::unified_llm::adapters {}
namespace eval ::unified_llm::adapters::openai {}

package require Tcl 8.5
package require json
package require attractor_core

proc ::unified_llm::adapters::__default_base_url {provider} {
    switch -- $provider {
        openai { return "https://api.openai.com" }
        anthropic { return "https://api.anthropic.com" }
        gemini { return "https://generativelanguage.googleapis.com" }
        default { return "" }
    }
}

proc ::unified_llm::adapters::__offline_response {provider} {
    return [dict create \
        status_code 200 \
        headers {} \
        body [::attractor_core::json_encode [dict create output_text "offline-$provider" usage [dict create input_tokens 1 output_tokens 1 reasoning_tokens 0 cache_read_tokens 0 cache_write_tokens 0]]]]
}

proc ::unified_llm::adapters::__provider_error_type {status} {
    if {$status in {401 403}} {
        return AUTH
    }
    if {$status in {408 409 425 429}} {
        return RETRYABLE
    }
    if {$status >= 500} {
        return RETRYABLE
    }
    if {$status == 0} {
        return TRANSPORT
    }
    return REQUEST
}

proc ::unified_llm::adapters::__raise_if_error {provider response} {
    set status 0
    if {[dict exists $response status_code]} {
        set status [dict get $response status_code]
    }
    if {$status < 400} {
        return
    }

    set body ""
    if {[dict exists $response body]} {
        set body [dict get $response body]
    }
    set errorType [::unified_llm::adapters::__provider_error_type $status]
    return -code error -errorcode [list UNIFIED_LLM PROVIDER [string toupper $provider] $errorType $status] "provider $provider request failed: status=$status body=$body"
}

proc ::unified_llm::adapters::__http_invoke {state provider endpoint payload headers} {
    package require http

    set baseUrl ""
    if {[dict exists $state base_url] && [dict get $state base_url] ne ""} {
        set baseUrl [dict get $state base_url]
    } else {
        set baseUrl [::unified_llm::adapters::__default_base_url $provider]
    }

    if {$baseUrl eq ""} {
        return [::unified_llm::adapters::__offline_response $provider]
    }

    set url "$baseUrl$endpoint"
    set headerList {}
    foreach key [dict keys $headers] {
        lappend headerList $key [dict get $headers $key]
    }

    set body [::attractor_core::json_encode $payload]
    set token ""
    set responseBody ""
    set status 0
    set responseHeaders {}

    set code [catch {
        set token [::http::geturl $url -method POST -type "application/json" -headers $headerList -query $body -timeout 60000]
        set responseBody [::http::data $token]
        set status [::http::ncode $token]
        foreach {k v} [::http::meta $token] {
            dict set responseHeaders [string tolower $k] $v
        }
    } err errOpts]

    if {$token ne ""} {
        ::http::cleanup $token
    }

    if {$code} {
        return [dict create status_code 0 headers {} body $err]
    }

    return [dict create status_code $status headers $responseHeaders body $responseBody]
}

proc ::unified_llm::adapters::__invoke_transport {state provider endpoint payload headers} {
    if {[dict exists $state transport] && [dict get $state transport] ne ""} {
        set cmd [dict get $state transport]
        return [{*}$cmd [dict create \
            provider $provider \
            endpoint $endpoint \
            payload $payload \
            headers $headers]]
    }

    if {(![dict exists $state api_key] || [dict get $state api_key] eq "") && (![dict exists $state base_url] || [dict get $state base_url] eq "")} {
        return [::unified_llm::adapters::__offline_response $provider]
    }

    return [::unified_llm::adapters::__http_invoke $state $provider $endpoint $payload $headers]
}

proc ::unified_llm::adapters::__chunk_text {text chunkSize} {
    if {$text eq ""} {
        return {}
    }

    if {$chunkSize < 1} {
        set chunkSize 1
    }

    set out {}
    set idx 0
    set max [string length $text]
    while {$idx < $max} {
        lappend out [string range $text $idx [expr {$idx + $chunkSize - 1}]]
        incr idx $chunkSize
    }
    return $out
}

proc ::unified_llm::adapters::openai::__translate_part {part} {
    set type [dict get $part type]
    switch -- $type {
        text {
            return [dict create type input_text text [dict get $part text]]
        }
        thinking {
            return [dict create type reasoning text [dict get $part text]]
        }
        image_url {
            return [dict create type input_image image_url [dict get $part url]]
        }
        image_base64 {
            return [dict create type input_image image_url "data:[dict get $part mime_type];base64,[dict get $part data]"]
        }
        image_path {
            return [dict create type input_image image_url [dict get $part data_url]]
        }
        tool_result {
            return [dict create type tool_result id [dict get $part id] name [dict get $part name] output [dict get $part output] is_error [dict get $part is_error]]
        }
        default {
            return -code error -errorcode [list UNIFIED_LLM INPUT PART UNSUPPORTED] "unsupported content part for openai: $type"
        }
    }
}

proc ::unified_llm::adapters::openai::__translate_tools {tools} {
    set out {}
    foreach name [dict keys $tools] {
        set desc [dict get $tools $name]
        set schema [dict create type object properties {}]
        if {[dict exists $desc schema]} {
            set schema [dict get $desc schema]
        }
        lappend out [dict create type function name $name parameters $schema]
    }
    return $out
}

proc ::unified_llm::adapters::openai::translate_request {request} {
    set inputItems {}
    foreach message [dict get $request messages] {
        if {![dict exists $message content_parts]} {
            set message [::unified_llm::__normalize_message $message]
        }
        set parts {}
        foreach part [dict get $message content_parts] {
            lappend parts [::unified_llm::adapters::openai::__translate_part $part]
        }
        lappend inputItems [dict create role [dict get $message role] content $parts]
    }

    set out [dict create input $inputItems]
    if {[dict exists $request model] && [dict get $request model] ne ""} {
        dict set out model [dict get $request model]
    }
    if {[dict exists $request tools] && [dict size [dict get $request tools]] > 0} {
        dict set out tools [::unified_llm::adapters::openai::__translate_tools [dict get $request tools]]
    }
    if {[dict exists $request tool_results]} {
        dict set out tool_results [dict get $request tool_results]
    }
    if {[dict exists $request continuation_from]} {
        dict set out previous_response_id [dict get $request continuation_from]
    }
    return $out
}

proc ::unified_llm::adapters::openai::__translate_usage {decoded} {
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
    if {[dict exists $rawUsage output_tokens_details reasoning_tokens]} {
        dict set usage reasoning_tokens [dict get $rawUsage output_tokens_details reasoning_tokens]
    }
    if {[dict exists $rawUsage cache_read_tokens]} {
        dict set usage cache_read_tokens [dict get $rawUsage cache_read_tokens]
    }
    if {[dict exists $rawUsage input_tokens_details cached_tokens]} {
        dict set usage cache_read_tokens [dict get $rawUsage input_tokens_details cached_tokens]
    }
    if {[dict exists $rawUsage cache_creation_tokens]} {
        dict set usage cache_write_tokens [dict get $rawUsage cache_creation_tokens]
    }

    return $usage
}

proc ::unified_llm::adapters::openai::complete {state request} {
    set endpoint "/v1/responses"
    set payload [::unified_llm::adapters::openai::translate_request $request]

    set headers [dict create Content-Type application/json]
    if {[dict get $state api_key] ne ""} {
        dict set headers Authorization "Bearer [dict get $state api_key]"
    }
    if {[dict exists $request provider_options extra_headers]} {
        foreach key [dict keys [dict get $request provider_options extra_headers]] {
            dict set headers $key [dict get $request provider_options extra_headers $key]
        }
    }

    set transport [::unified_llm::adapters::__invoke_transport $state openai $endpoint $payload $headers]
    ::unified_llm::adapters::__raise_if_error openai $transport

    set decoded [::attractor_core::json_decode [dict get $transport body]]

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

    set responseId "openai-response-1"
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
        usage [::unified_llm::adapters::openai::__translate_usage $decoded] \
        metadata $metadata \
        raw $decoded \
        request [dict create endpoint $endpoint payload $payload headers $headers]]
}

proc ::unified_llm::adapters::openai::stream {state request} {
    set response [::unified_llm::adapters::openai::complete $state $request]
    set events [list [dict create type STREAM_START provider openai response_id [dict get $response response_id]]]
    foreach chunk [::unified_llm::adapters::__chunk_text [dict get $response text] 16] {
        lappend events [dict create type TEXT_DELTA delta $chunk]
    }
    foreach call [dict get $response tool_calls] {
        lappend events [dict create type TOOL_CALL_END tool_call $call]
    }
    lappend events [dict create type FINISH response $response usage [dict get $response usage]]
    return [dict create events $events response $response]
}
