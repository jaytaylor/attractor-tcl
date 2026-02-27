namespace eval ::unified_llm {
    variable version 0.1.0
    variable default_client ""
    variable client_seq 0
    variable clients {}
    variable package_dir [file dirname [info script]]
}

package require Tcl 8.5
package require json
package require attractor_core

source [file join $::unified_llm::package_dir adapters openai.tcl]
source [file join $::unified_llm::package_dir adapters anthropic.tcl]
source [file join $::unified_llm::package_dir adapters gemini.tcl]
source [file join $::unified_llm::package_dir transports https_json.tcl]

proc ::unified_llm::set_default_client {client_cmd} {
    variable default_client
    set default_client $client_cmd
    return $default_client
}

proc ::unified_llm::default_client {} {
    variable default_client
    if {$default_client eq ""} {
        set default_client [::unified_llm::from_env]
    }
    return $default_client
}

proc ::unified_llm::from_env {} {
    if {[info exists ::env(UNIFIED_LLM_PROVIDER)]} {
        set provider [string tolower [string trim $::env(UNIFIED_LLM_PROVIDER)]]
        if {$provider ni {openai anthropic gemini mock}} {
            return -code error -errorcode [list UNIFIED_LLM CONFIG UNKNOWN_PROVIDER] "unsupported provider in UNIFIED_LLM_PROVIDER: $provider"
        }
        return [::unified_llm::client_new -provider $provider]
    }

    set candidates {}
    if {[info exists ::env(OPENAI_API_KEY)] && $::env(OPENAI_API_KEY) ne ""} {
        lappend candidates openai
    }
    if {[info exists ::env(ANTHROPIC_API_KEY)] && $::env(ANTHROPIC_API_KEY) ne ""} {
        lappend candidates anthropic
    }
    if {[info exists ::env(GEMINI_API_KEY)] && $::env(GEMINI_API_KEY) ne ""} {
        lappend candidates gemini
    }

    if {[llength $candidates] > 1} {
        return -code error -errorcode [list UNIFIED_LLM CONFIG AMBIGUOUS_PROVIDER] "multiple provider API keys present; set UNIFIED_LLM_PROVIDER explicitly"
    }
    if {[llength $candidates] == 1} {
        return [::unified_llm::client_new -provider [lindex $candidates 0]]
    }

    return -code error -errorcode [list UNIFIED_LLM CONFIG MISSING_PROVIDER] "no provider configured; set UNIFIED_LLM_PROVIDER or one provider API key"
}

proc ::unified_llm::client_new {args} {
    variable client_seq
    variable clients

    array set opts {
        -provider mock
        -api_key ""
        -base_url ""
        -transport ""
        -middlewares {}
        -provider_options {}
    }
    array set opts $args

    incr client_seq
    set id $client_seq
    set cmd ::unified_llm::client::$id

    set state [dict create \
        provider $opts(-provider) \
        api_key $opts(-api_key) \
        base_url $opts(-base_url) \
        transport $opts(-transport) \
        middlewares $opts(-middlewares) \
        provider_options $opts(-provider_options) \
        closed 0]

    dict set clients $id $state
    interp alias {} $cmd {} ::unified_llm::__client_dispatch $id
    return $cmd
}

proc ::unified_llm::__client_dispatch {id method args} {
    variable clients

    if {![dict exists $clients $id]} {
        return -code error "unknown client: $id"
    }

    switch -- $method {
        complete {
            if {[llength $args] != 1} {
                return -code error "usage: \$client complete requestDict"
            }
            return [::unified_llm::__client_complete $id [lindex $args 0]]
        }
        stream {
            if {[llength $args] < 1} {
                return -code error "usage: \$client stream requestDict ?-on_event cmdPrefix?"
            }
            set request [lindex $args 0]
            set rest [lrange $args 1 end]
            return [::unified_llm::__client_stream $id $request {*}$rest]
        }
        add_middleware {
            if {[llength $args] != 1} {
                return -code error "usage: \$client add_middleware cmdPrefix"
            }
            dict lappend clients $id middlewares [lindex $args 0]
            return {}
        }
        config {
            if {[llength $args] != 0} {
                return -code error "usage: \$client config"
            }
            return [dict get $clients $id]
        }
        close {
            rename ::unified_llm::client::$id {}
            dict unset clients $id
            return {}
        }
        default {
            return -code error "unknown client method: $method"
        }
    }
}

proc ::unified_llm::__lreverse {items} {
    set out {}
    foreach item $items {
        set out [linsert $out 0 $item]
    }
    return $out
}

proc ::unified_llm::__resolve_provider {state request} {
    set provider [dict get $state provider]
    if {[dict exists $request provider] && [dict get $request provider] ne ""} {
        set provider [dict get $request provider]
    }
    return $provider
}

proc ::unified_llm::__merge_provider_options {state request} {
    set merged {}
    if {[dict exists $state provider_options]} {
        set merged [dict get $state provider_options]
    }
    if {[dict exists $request provider_options]} {
        if {$merged eq ""} {
            set merged [dict get $request provider_options]
        } else {
            set merged [dict merge $merged [dict get $request provider_options]]
        }
    }
    if {$merged eq ""} {
        return {}
    }
    return $merged
}

proc ::unified_llm::__validate_provider_options {provider options} {
    if {$options eq "" || [llength $options] == 0} {
        return
    }

    if {[catch {dict size $options}]} {
        return -code error -errorcode [list UNIFIED_LLM INPUT INVALID_PROVIDER_OPTIONS] "provider_options must be a dictionary"
    }

    if {[dict exists $options extra_headers] && [catch {dict size [dict get $options extra_headers]}]} {
        return -code error -errorcode [list UNIFIED_LLM INPUT INVALID_PROVIDER_OPTIONS] "provider_options.extra_headers must be a dictionary"
    }

    if {$provider eq "anthropic" && [dict exists $options beta_headers]} {
        set betaHeaders [dict get $options beta_headers]
        if {[catch {llength $betaHeaders}]} {
            return -code error -errorcode [list UNIFIED_LLM INPUT INVALID_PROVIDER_OPTIONS] "provider_options.beta_headers must be a list"
        }
        foreach header $betaHeaders {
            if {[string trim $header] eq ""} {
                return -code error -errorcode [list UNIFIED_LLM INPUT INVALID_PROVIDER_OPTIONS] "provider_options.beta_headers entries must be non-empty"
            }
        }
    }

    if {$provider eq "gemini" && [dict exists $options safety_settings] && [catch {llength [dict get $options safety_settings]}]} {
        return -code error -errorcode [list UNIFIED_LLM INPUT INVALID_PROVIDER_OPTIONS] "provider_options.safety_settings must be a list"
    }
}

proc ::unified_llm::__apply_response_middlewares {middlewares response} {
    set current $response
    foreach middleware [::unified_llm::__lreverse $middlewares] {
        if {[catch {{*}$middleware response $current} transformed]} {
            return -code error -errorcode [list UNIFIED_LLM MIDDLEWARE RESPONSE] $transformed
        }
        set current $transformed
    }
    return $current
}

proc ::unified_llm::__client_complete {id request} {
    variable clients

    set state [dict get $clients $id]
    set middlewares [dict get $state middlewares]

    set currentRequest $request
    foreach middleware $middlewares {
        if {[catch {{*}$middleware request $currentRequest} transformed]} {
            return -code error -errorcode [list UNIFIED_LLM MIDDLEWARE REQUEST] $transformed
        }
        set currentRequest $transformed
    }

    set provider [::unified_llm::__resolve_provider $state $currentRequest]
    if {$provider ni {openai anthropic gemini mock}} {
        return -code error -errorcode [list UNIFIED_LLM CONFIG UNKNOWN_PROVIDER] "unsupported provider: $provider"
    }

    dict set currentRequest provider $provider
    dict set currentRequest provider_options [::unified_llm::__merge_provider_options $state $currentRequest]
    ::unified_llm::__validate_provider_options $provider [dict get $currentRequest provider_options]

    switch -- $provider {
        openai {
            set response [::unified_llm::adapters::openai::complete $state $currentRequest]
        }
        anthropic {
            set response [::unified_llm::adapters::anthropic::complete $state $currentRequest]
        }
        gemini {
            set response [::unified_llm::adapters::gemini::complete $state $currentRequest]
        }
        mock {
            set response [::unified_llm::adapters::mock_complete $state $currentRequest]
        }
    }

    return [::unified_llm::__apply_response_middlewares $middlewares $response]
}

proc ::unified_llm::__stream_from_response {provider response} {
    set events [list [dict create type STREAM_START provider $provider response_id [dict get $response response_id]]]
    set text ""
    if {[dict exists $response text]} {
        set text [dict get $response text]
    }
    foreach chunk [::unified_llm::adapters::__chunk_text $text 16] {
        lappend events [dict create type TEXT_DELTA delta $chunk]
    }
    if {[dict exists $response tool_calls]} {
        foreach tc [dict get $response tool_calls] {
            lappend events [dict create type TOOL_CALL_END tool_call $tc]
        }
    }
    lappend events [dict create type FINISH response $response usage [dict get $response usage]]
    return [dict create events $events response $response]
}

proc ::unified_llm::__client_stream {id request args} {
    variable clients

    array set opts {
        -on_event ""
    }
    array set opts $args

    if {$opts(-on_event) eq ""} {
        return -code error "-on_event is required"
    }

    set state [dict get $clients $id]
    set middlewares [dict get $state middlewares]

    set currentRequest $request
    foreach middleware $middlewares {
        if {[catch {{*}$middleware request $currentRequest} transformed]} {
            return -code error -errorcode [list UNIFIED_LLM MIDDLEWARE REQUEST] $transformed
        }
        set currentRequest $transformed
    }

    set provider [::unified_llm::__resolve_provider $state $currentRequest]
    if {$provider ni {openai anthropic gemini mock}} {
        return -code error -errorcode [list UNIFIED_LLM CONFIG UNKNOWN_PROVIDER] "unsupported provider: $provider"
    }

    dict set currentRequest provider $provider
    dict set currentRequest provider_options [::unified_llm::__merge_provider_options $state $currentRequest]
    ::unified_llm::__validate_provider_options $provider [dict get $currentRequest provider_options]

    switch -- $provider {
        openai {
            set streamResult [::unified_llm::adapters::openai::stream $state $currentRequest]
        }
        anthropic {
            set streamResult [::unified_llm::adapters::anthropic::stream $state $currentRequest]
        }
        gemini {
            set streamResult [::unified_llm::adapters::gemini::stream $state $currentRequest]
        }
        mock {
            set response [::unified_llm::adapters::mock_complete $state $currentRequest]
            set streamResult [::unified_llm::__stream_from_response $provider $response]
        }
    }

    set response [::unified_llm::__apply_response_middlewares $middlewares [dict get $streamResult response]]

    set emitted {}
    foreach event [dict get $streamResult events] {
        set currentEvent $event
        if {[dict get $currentEvent type] eq "FINISH"} {
            dict set currentEvent response $response
            dict set currentEvent usage [dict get $response usage]
        }
        foreach middleware $middlewares {
            if {[catch {{*}$middleware event $currentEvent} transformed]} {
                return -code error -errorcode [list UNIFIED_LLM MIDDLEWARE EVENT] $transformed
            }
            set currentEvent $transformed
        }
        lappend emitted $currentEvent
        {*}$opts(-on_event) $currentEvent
    }

    return [dict create handle stream-1 response $response events $emitted]
}

proc ::unified_llm::message {role content args} {
    set msg [dict create role $role content $content]
    foreach {k v} $args {
        dict set msg $k $v
    }
    return $msg
}

proc ::unified_llm::__infer_mime_type {path} {
    set ext [string tolower [file extension $path]]
    switch -- $ext {
        .png { return image/png }
        .jpg - .jpeg { return image/jpeg }
        .gif { return image/gif }
        .webp { return image/webp }
        default { return application/octet-stream }
    }
}

proc ::unified_llm::__base64_encode {bytes} {
    if {[llength [info commands ::base64::encode]] > 0} {
        return [string map [list "\n" ""] [::base64::encode $bytes]]
    }

    if {[catch {binary encode base64 $bytes} encoded] == 0} {
        return [string map [list "\n" ""] $encoded]
    }

    if {[catch {package require base64}] == 0} {
        return [string map [list "\n" ""] [::base64::encode $bytes]]
    }

    return -code error -errorcode [list UNIFIED_LLM INPUT BASE64_UNAVAILABLE] "base64 encoder unavailable"
}

proc ::unified_llm::__normalize_content_part {part} {
    if {[catch {dict size $part}]} {
        return [dict create type text text "$part"]
    }
    if {![dict exists $part type]} {
        return -code error -errorcode [list UNIFIED_LLM INPUT PART MALFORMED] "content part requires type"
    }

    set type [dict get $part type]
    switch -- $type {
        text - thinking {
            if {![dict exists $part text]} {
                return -code error -errorcode [list UNIFIED_LLM INPUT PART MALFORMED] "$type part requires text"
            }
            return [dict create type $type text [dict get $part text]]
        }
        image_url {
            if {![dict exists $part url]} {
                return -code error -errorcode [list UNIFIED_LLM INPUT PART MALFORMED] "image_url part requires url"
            }
            return [dict create type image_url url [dict get $part url]]
        }
        image_base64 {
            if {![dict exists $part data]} {
                return -code error -errorcode [list UNIFIED_LLM INPUT PART MALFORMED] "image_base64 part requires data"
            }
            set mimeType image/png
            if {[dict exists $part mime_type] && [dict get $part mime_type] ne ""} {
                set mimeType [dict get $part mime_type]
            }
            return [dict create type image_base64 mime_type $mimeType data [dict get $part data]]
        }
        image_path {
            if {![dict exists $part path]} {
                return -code error -errorcode [list UNIFIED_LLM INPUT PART MALFORMED] "image_path part requires path"
            }
            set path [dict get $part path]
            if {![file exists $path]} {
                return -code error -errorcode [list UNIFIED_LLM INPUT IMAGE_PATH_MISSING] "image path does not exist: $path"
            }
            set fh [open $path r]
            fconfigure $fh -translation binary -encoding binary
            set bytes [read $fh]
            close $fh

            set encoded [::unified_llm::__base64_encode $bytes]
            set mimeType [::unified_llm::__infer_mime_type $path]
            if {[dict exists $part mime_type] && [dict get $part mime_type] ne ""} {
                set mimeType [dict get $part mime_type]
            }
            return [dict create type image_path path $path mime_type $mimeType base64 $encoded data_url "data:$mimeType;base64,$encoded"]
        }
        tool_call {
            return $part
        }
        tool_result {
            foreach key {id name output is_error} {
                if {![dict exists $part $key]} {
                    return -code error -errorcode [list UNIFIED_LLM INPUT PART MALFORMED] "tool_result part missing key: $key"
                }
            }
            return $part
        }
        default {
            return -code error -errorcode [list UNIFIED_LLM INPUT PART UNSUPPORTED] "unsupported content part type: $type"
        }
    }
}

proc ::unified_llm::__is_part_list {content} {
    if {[catch {llength $content}]} {
        return 0
    }
    if {[llength $content] == 0} {
        return 0
    }
    foreach item $content {
        if {[catch {dict size $item}] || ![dict exists $item type]} {
            return 0
        }
    }
    return 1
}

proc ::unified_llm::__normalize_message {message} {
    if {[catch {dict size $message}]} {
        return -code error -errorcode [list UNIFIED_LLM INPUT MESSAGE_MALFORMED] "message must be a dictionary"
    }
    if {![dict exists $message role]} {
        return -code error -errorcode [list UNIFIED_LLM INPUT MESSAGE_MALFORMED] "message.role is required"
    }

    set parts {}
    if {[dict exists $message content_parts]} {
        set rawParts [dict get $message content_parts]
    } elseif {[dict exists $message content]} {
        set raw [dict get $message content]
        if {[::unified_llm::__is_part_list $raw]} {
            set rawParts $raw
        } else {
            set rawParts [list [dict create type text text "$raw"]]
        }
    } else {
        set rawParts {}
    }

    foreach part $rawParts {
        lappend parts [::unified_llm::__normalize_content_part $part]
    }

    set normalized [dict create role [dict get $message role] content_parts $parts]
    foreach key [dict keys $message] {
        if {$key in {role content content_parts}} {
            continue
        }
        dict set normalized $key [dict get $message $key]
    }
    return $normalized
}

proc ::unified_llm::__normalize_messages {prompt messages} {
    if {$prompt ne "" && [llength $messages] > 0} {
        return -code error -errorcode [list UNIFIED_LLM INPUT] "provide either -prompt or -messages"
    }

    set out {}
    if {$prompt ne ""} {
        lappend out [::unified_llm::__normalize_message [dict create role user content [list [dict create type text text $prompt]]]]
        return $out
    }

    if {[llength $messages] == 0} {
        return -code error -errorcode [list UNIFIED_LLM INPUT] "-prompt or -messages is required"
    }

    foreach msg $messages {
        lappend out [::unified_llm::__normalize_message $msg]
    }
    return $out
}

proc ::unified_llm::__normalize_tool_definitions {tools} {
    if {[llength $tools] == 0} {
        return {}
    }
    if {[catch {dict size $tools}]} {
        return -code error -errorcode [list UNIFIED_LLM INPUT TOOLS_MALFORMED] "-tools must be a dictionary"
    }

    set normalized {}
    foreach name [dict keys $tools] {
        set raw [dict get $tools $name]

        set descriptor [dict create name $name mode active schema [dict create type object properties {}] command ""]
        if {![catch {dict size $raw}] && ([dict exists $raw command] || [dict exists $raw mode] || [dict exists $raw schema])} {
            if {[dict exists $raw mode]} {
                set mode [dict get $raw mode]
                if {$mode ni {active passive}} {
                    return -code error -errorcode [list UNIFIED_LLM INPUT TOOLS_MALFORMED] "tool $name has invalid mode: $mode"
                }
                dict set descriptor mode $mode
            }
            if {[dict exists $raw schema]} {
                dict set descriptor schema [dict get $raw schema]
            }
            if {[dict exists $raw command]} {
                dict set descriptor command [dict get $raw command]
            }
        } else {
            dict set descriptor command $raw
        }

        if {[dict get $descriptor mode] eq "active" && [dict get $descriptor command] eq ""} {
            return -code error -errorcode [list UNIFIED_LLM INPUT TOOLS_MALFORMED] "active tool $name requires command"
        }

        dict set normalized $name $descriptor
    }

    return $normalized
}

proc ::unified_llm::__resolve_client {argsVar tempClientVar} {
    upvar 1 $argsVar opts
    upvar 1 $tempClientVar tempClient

    set tempClient 0
    if {$opts(-client) ne ""} {
        return $opts(-client)
    }

    variable default_client
    if {$default_client ne "" && [llength [info commands $default_client]] > 0} {
        return $default_client
    }

    if {$default_client ne ""} {
        set default_client ""
    }

    if {$opts(-provider) ne ""} {
        set tempClient 1
        return [::unified_llm::client_new -provider $opts(-provider)]
    }

    return [::unified_llm::default_client]
}

proc ::unified_llm::generate {args} {
    array set opts {
        -client ""
        -prompt ""
        -messages {}
        -model ""
        -tools {}
        -provider ""
        -provider_options {}
        -max_tool_rounds 4
    }
    array set opts $args

    set client [::unified_llm::__resolve_client opts tempClient]

    set code [catch {
        set messages [::unified_llm::__normalize_messages $opts(-prompt) $opts(-messages)]
        set tools [::unified_llm::__normalize_tool_definitions $opts(-tools)]

        set request [dict create \
            model $opts(-model) \
            messages $messages \
            tools $tools \
            provider_options $opts(-provider_options)]

        if {$opts(-provider) ne ""} {
            dict set request provider $opts(-provider)
        }

        set totalUsage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0 cache_write_tokens 0]

        set response [$client complete $request]
        set totalUsage [::unified_llm::usage_add $totalUsage [dict get $response usage]]

        set round 0
        while {[dict exists $response tool_calls] && [llength [dict get $response tool_calls]] > 0} {
            if {$opts(-max_tool_rounds) == 0} {
                break
            }
            if {$round >= $opts(-max_tool_rounds)} {
                return -code error -errorcode [list UNIFIED_LLM TOOL MAX_ROUNDS] "tool round limit reached"
            }

            set execution [::unified_llm::execute_tool_calls [dict get $response tool_calls] $tools]
            set toolResults [dict get $execution results]
            set passiveCalls [dict get $execution passive_calls]

            if {[llength $passiveCalls] > 0} {
                dict set response pending_tool_calls $passiveCalls
                break
            }

            dict set request tool_results $toolResults
            dict set request continuation_from [dict get $response response_id]

            set response [$client complete $request]
            set totalUsage [::unified_llm::usage_add $totalUsage [dict get $response usage]]
            incr round
        }

        dict set response usage $totalUsage
        set finalResponse $response
    } err optsDict]

    if {$tempClient} {
        catch {$client close}
    }
    if {$code} {
        return -options $optsDict $err
    }
    return $finalResponse
}

proc ::unified_llm::stream {args} {
    array set opts {
        -client ""
        -prompt ""
        -messages {}
        -model ""
        -provider ""
        -provider_options {}
        -tools {}
        -on_event ""
    }
    array set opts $args

    if {$opts(-on_event) eq ""} {
        return -code error "-on_event is required"
    }

    set client [::unified_llm::__resolve_client opts tempClient]

    set code [catch {
        set messages [::unified_llm::__normalize_messages $opts(-prompt) $opts(-messages)]
        set tools [::unified_llm::__normalize_tool_definitions $opts(-tools)]
        set request [dict create \
            model $opts(-model) \
            messages $messages \
            tools $tools \
            provider_options $opts(-provider_options)]
        if {$opts(-provider) ne ""} {
            dict set request provider $opts(-provider)
        }

        set result [$client stream $request -on_event $opts(-on_event)]
    } err optsDict]

    if {$tempClient} {
        catch {$client close}
    }
    if {$code} {
        return -options $optsDict $err
    }

    return $result
}

proc ::unified_llm::generate_object {args} {
    array set opts {
        -schema {}
    }
    array set opts $args

    if {[llength $opts(-schema)] == 0} {
        return -code error "-schema is required"
    }

    set response [::unified_llm::generate {*}$args]
    set text [dict get $response text]

    if {[catch {::attractor_core::json_decode $text} decoded]} {
        return -code error -errorcode [list UNIFIED_LLM OBJECT INVALID_JSON] "response is not valid JSON"
    }

    set errors [::attractor_core::schema_validate $opts(-schema) $decoded]
    if {[llength $errors] > 0} {
        return -code error -errorcode [list UNIFIED_LLM OBJECT SCHEMA_MISMATCH] $errors
    }

    return [dict create object $decoded response $response]
}

proc ::unified_llm::__stream_object_collect {token event} {
    variable stream_object_buffer
    variable stream_object_finished
    variable stream_object_response

    if {![info exists stream_object_buffer($token)]} {
        return
    }

    if {[dict get $event type] eq "TEXT_DELTA" && [dict exists $event delta]} {
        append stream_object_buffer($token) [dict get $event delta]
    }
    if {[dict get $event type] eq "FINISH" && [dict exists $event response]} {
        set stream_object_response($token) [dict get $event response]
        set stream_object_finished($token) 1
    }
}

proc ::unified_llm::stream_object {args} {
    array set opts {
        -on_object ""
    }
    array set opts $args

    if {$opts(-on_object) eq ""} {
        return -code error "-on_object is required"
    }

    variable stream_object_buffer
    variable stream_object_finished
    variable stream_object_response
    set token "stream-object-[clock clicks]"
    set stream_object_buffer($token) ""
    set stream_object_finished($token) 0
    set stream_object_response($token) {}

    set forwardArgs {}
    foreach {k v} $args {
        if {$k eq "-on_object"} {
            continue
        }
        lappend forwardArgs $k $v
    }

    set code [catch {
        ::unified_llm::stream {*}$forwardArgs -on_event [list ::unified_llm::__stream_object_collect $token]
    } err errOpts]
    if {$code} {
        unset -nocomplain stream_object_buffer($token) stream_object_finished($token) stream_object_response($token)
        return -options $errOpts $err
    }

    set buffered $stream_object_buffer($token)
    set gotFinish $stream_object_finished($token)
    set finalResponse $stream_object_response($token)
    unset -nocomplain stream_object_buffer($token) stream_object_finished($token) stream_object_response($token)

    if {!$gotFinish} {
        return -code error -errorcode [list UNIFIED_LLM OBJECT INVALID_STREAM] "stream finished without terminal event"
    }

    if {[catch {::attractor_core::json_decode $buffered} decoded]} {
        return -code error -errorcode [list UNIFIED_LLM OBJECT INVALID_JSON] "streamed response is not valid JSON"
    }

    set schema {}
    array set parsed $args
    if {[info exists parsed(-schema)]} {
        set schema $parsed(-schema)
    }
    if {[llength $schema] > 0} {
        set errors [::attractor_core::schema_validate $schema $decoded]
        if {[llength $errors] > 0} {
            return -code error -errorcode [list UNIFIED_LLM OBJECT SCHEMA_MISMATCH] $errors
        }
    }

    {*}$opts(-on_object) $decoded
    return [dict create object $decoded response $finalResponse]
}

proc ::unified_llm::usage_add {a b} {
    set merged [dict create]
    foreach key {input_tokens output_tokens reasoning_tokens cache_read_tokens cache_write_tokens} {
        set va 0
        set vb 0
        if {[dict exists $a $key]} {
            set va [dict get $a $key]
        }
        if {[dict exists $b $key]} {
            set vb [dict get $b $key]
        }
        dict set merged $key [expr {$va + $vb}]
    }
    return $merged
}

proc ::unified_llm::execute_tool_calls {toolCalls toolDefinitions} {
    set results {}
    set passiveCalls {}
    foreach call $toolCalls {
        set result [::unified_llm::invoke_tool_call $call $toolDefinitions]
        if {[dict exists $result passive] && [dict get $result passive]} {
            lappend passiveCalls $call
        }
        lappend results $result
    }
    return [dict create results $results passive_calls $passiveCalls]
}

proc ::unified_llm::invoke_tool_call {toolCall toolDefinitions} {
    set toolName [dict get $toolCall name]
    set callId [dict get $toolCall id]

    if {![dict exists $toolDefinitions $toolName]} {
        return [dict create \
            id $callId \
            name $toolName \
            is_error 1 \
            output "unknown tool: $toolName"]
    }

    set descriptor [dict get $toolDefinitions $toolName]
    set mode [dict get $descriptor mode]
    if {$mode eq "passive"} {
        return [dict create \
            id $callId \
            name $toolName \
            is_error 0 \
            passive 1 \
            output "passive tool call pending external execution"]
    }

    set input {}
    if {[dict exists $toolCall arguments]} {
        set input [dict get $toolCall arguments]
    }

    set command [dict get $descriptor command]
    if {[catch {{*}$command $input $toolCall} outcome]} {
        return [dict create \
            id $callId \
            name $toolName \
            is_error 1 \
            output $outcome]
    }

    return [dict create \
        id $callId \
        name $toolName \
        is_error 0 \
        output $outcome]
}

proc ::unified_llm::adapters::mock_complete {state request} {
    if {[dict exists $request mock_response]} {
        return [dict get $request mock_response]
    }

    set messages [dict get $request messages]
    set last ""
    if {[llength $messages] > 0 && [llength [dict get [lindex $messages end] content_parts]] > 0} {
        set part [lindex [dict get [lindex $messages end] content_parts] 0]
        if {[dict exists $part text]} {
            set last [dict get $part text]
        }
    }

    return [dict create \
        provider mock \
        response_id mock-response-1 \
        text "mock:$last" \
        tool_calls {} \
        usage [dict create input_tokens 1 output_tokens 1 reasoning_tokens 0 cache_read_tokens 0 cache_write_tokens 0] \
        raw [dict create ok 1]]
}

proc ::unified_llm::__load_models {} {
    variable package_dir
    set path [file join $package_dir models.json]
    if {![file exists $path]} {
        return {}
    }
    set fh [open $path r]
    set payload [read $fh]
    close $fh
    return [::attractor_core::json_decode $payload]
}

proc ::unified_llm::list_models {{provider ""}} {
    set catalog [::unified_llm::__load_models]
    if {$provider eq ""} {
        return [dict keys $catalog]
    }
    if {![dict exists $catalog $provider models]} {
        return {}
    }
    return [dict get $catalog $provider models]
}

proc ::unified_llm::get_model_info {provider model} {
    set models [::unified_llm::list_models $provider]
    foreach info $models {
        if {[dict get $info id] eq $model} {
            return $info
        }
    }
    return {}
}

proc ::unified_llm::get_latest_model {provider} {
    set catalog [::unified_llm::__load_models]
    if {![dict exists $catalog $provider latest]} {
        return ""
    }
    return [dict get $catalog $provider latest]
}

package provide unified_llm $::unified_llm::version
