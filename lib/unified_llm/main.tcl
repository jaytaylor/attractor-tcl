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

proc ::unified_llm::from_env {args} {
    array set opts {
        -transport ""
    }
    array set opts $args

    set providers {}
    set discoveredProviders {}

    if {[info exists ::env(OPENAI_API_KEY)] && [string trim $::env(OPENAI_API_KEY)] ne ""} {
        dict set providers openai [dict create \
            api_key [string trim $::env(OPENAI_API_KEY)] \
            base_url [expr {[info exists ::env(OPENAI_BASE_URL)] ? [string trim $::env(OPENAI_BASE_URL)] : ""}] \
            transport $opts(-transport) \
            provider_options {}]
        lappend discoveredProviders openai
    }
    if {[info exists ::env(ANTHROPIC_API_KEY)] && [string trim $::env(ANTHROPIC_API_KEY)] ne ""} {
        dict set providers anthropic [dict create \
            api_key [string trim $::env(ANTHROPIC_API_KEY)] \
            base_url [expr {[info exists ::env(ANTHROPIC_BASE_URL)] ? [string trim $::env(ANTHROPIC_BASE_URL)] : ""}] \
            transport $opts(-transport) \
            provider_options {}]
        lappend discoveredProviders anthropic
    }

    set geminiKey ""
    if {[info exists ::env(GEMINI_API_KEY)] && [string trim $::env(GEMINI_API_KEY)] ne ""} {
        set geminiKey [string trim $::env(GEMINI_API_KEY)]
    } elseif {[info exists ::env(GOOGLE_API_KEY)] && [string trim $::env(GOOGLE_API_KEY)] ne ""} {
        set geminiKey [string trim $::env(GOOGLE_API_KEY)]
    }
    if {$geminiKey ne ""} {
        dict set providers gemini [dict create \
            api_key $geminiKey \
            base_url [expr {[info exists ::env(GEMINI_BASE_URL)] ? [string trim $::env(GEMINI_BASE_URL)] : ""}] \
            transport $opts(-transport) \
            provider_options {}]
        lappend discoveredProviders gemini
    }

    if {[dict size $providers] == 0} {
        return -code error -errorcode [list UNIFIED_LLM CONFIG MISSING_PROVIDER] "no provider configured; set provider API key environment variables"
    }

    set defaultProvider [lindex $discoveredProviders 0]
    if {[info exists ::env(UNIFIED_LLM_PROVIDER)] && [string trim $::env(UNIFIED_LLM_PROVIDER)] ne ""} {
        set override [string tolower [string trim $::env(UNIFIED_LLM_PROVIDER)]]
        if {$override ni {openai anthropic gemini mock}} {
            return -code error -errorcode [list UNIFIED_LLM CONFIG UNKNOWN_PROVIDER] "unsupported provider in UNIFIED_LLM_PROVIDER: $override"
        }
        if {![dict exists $providers $override]} {
            return -code error -errorcode [list UNIFIED_LLM CONFIG UNREGISTERED_PROVIDER] "provider override $override is not configured in environment"
        }
        set defaultProvider $override
    }

    return [::unified_llm::client_new -providers $providers -default_provider $defaultProvider]
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
        -providers {}
        -default_provider ""
    }
    array set opts $args

    incr client_seq
    set id $client_seq
    set cmd ::unified_llm::client::$id

    set providers {}
    if {[catch {dict size $opts(-providers)}] == 0 && [dict size $opts(-providers)] > 0} {
        foreach name [dict keys $opts(-providers)] {
            set raw [dict get $opts(-providers) $name]
            if {[catch {dict size $raw}]} {
                set raw {}
            }
            dict set providers $name [dict create \
                api_key [expr {[dict exists $raw api_key] ? [dict get $raw api_key] : ""}] \
                base_url [expr {[dict exists $raw base_url] ? [dict get $raw base_url] : ""}] \
                transport [expr {[dict exists $raw transport] ? [dict get $raw transport] : ""}] \
                provider_options [expr {[dict exists $raw provider_options] ? [dict get $raw provider_options] : {}}]]
        }
    } else {
        dict set providers $opts(-provider) [dict create \
            api_key $opts(-api_key) \
            base_url $opts(-base_url) \
            transport $opts(-transport) \
            provider_options $opts(-provider_options)]
    }

    set defaultProvider $opts(-default_provider)
    if {$defaultProvider eq ""} {
        if {[dict exists $providers $opts(-provider)]} {
            set defaultProvider $opts(-provider)
        } else {
            set defaultProvider [lindex [dict keys $providers] 0]
        }
    }
    if {![dict exists $providers $defaultProvider]} {
        return -code error -errorcode [list UNIFIED_LLM CONFIG UNREGISTERED_PROVIDER] "default provider is not registered: $defaultProvider"
    }

    set defaultEntry [dict get $providers $defaultProvider]

    set state [dict create \
        provider $defaultProvider \
        default_provider $defaultProvider \
        providers $providers \
        api_key [dict get $defaultEntry api_key] \
        base_url [dict get $defaultEntry base_url] \
        transport [dict get $defaultEntry transport] \
        middlewares $opts(-middlewares) \
        provider_options [dict get $defaultEntry provider_options] \
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
    set provider [expr {[dict exists $state default_provider] ? [dict get $state default_provider] : [dict get $state provider]}]
    if {[dict exists $request provider] && [dict get $request provider] ne ""} {
        set provider [string tolower [dict get $request provider]]
    }
    return $provider
}

proc ::unified_llm::__provider_entry {state provider} {
    if {[dict exists $state providers $provider]} {
        return [dict get $state providers $provider]
    }
    if {[dict exists $state provider] && [dict get $state provider] eq $provider} {
        return [dict create \
            api_key [expr {[dict exists $state api_key] ? [dict get $state api_key] : ""}] \
            base_url [expr {[dict exists $state base_url] ? [dict get $state base_url] : ""}] \
            transport [expr {[dict exists $state transport] ? [dict get $state transport] : ""}] \
            provider_options [expr {[dict exists $state provider_options] ? [dict get $state provider_options] : {}}]]
    }
    if {[dict exists $state providers]} {
        set fallback [dict get $state default_provider]
        if {[dict exists $state providers $fallback]} {
            return [dict get $state providers $fallback]
        }
    }
    return [dict create api_key "" base_url "" transport "" provider_options {}]
}

proc ::unified_llm::__state_for_provider {state provider} {
    set entry [::unified_llm::__provider_entry $state $provider]
    set resolved $state
    dict set resolved provider $provider
    dict set resolved api_key [dict get $entry api_key]
    dict set resolved base_url [dict get $entry base_url]
    dict set resolved transport [dict get $entry transport]
    dict set resolved provider_options [dict get $entry provider_options]
    return $resolved
}

proc ::unified_llm::__merge_provider_options {state provider request} {
    set merged {}
    set entry [::unified_llm::__provider_entry $state $provider]
    if {[dict exists $entry provider_options]} {
        set merged [dict get $entry provider_options]
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

proc ::unified_llm::__stream_event_required_keys {eventType} {
    switch -- $eventType {
        STREAM_START { return {provider response_id} }
        TEXT_START { return {text_id} }
        TEXT_DELTA { return {text_id delta} }
        TEXT_END { return {text_id} }
        REASONING_START { return {} }
        REASONING_DELTA { return {reasoning_delta} }
        REASONING_END { return {} }
        TOOL_CALL_START - TOOL_CALL_DELTA - TOOL_CALL_END { return {tool_call} }
        FINISH { return {response} }
        ERROR { return {error} }
        PROVIDER_EVENT { return {raw} }
        default { return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_TYPE] "unsupported stream event type: $eventType" }
    }
}

proc ::unified_llm::__stream_event {eventType args} {
    set allowedKeys {type provider response_id text_id delta reasoning_delta tool_call finish_reason usage response error raw}
    if {[expr {[llength $args] % 2}] != 0} {
        return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT] "stream event fields must be key/value pairs"
    }

    set event [dict create type $eventType]
    foreach {k v} $args {
        if {$k ni $allowedKeys} {
            return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT] "unsupported stream event key: $k"
        }
        dict set event $k $v
    }

    foreach key [::unified_llm::__stream_event_required_keys $eventType] {
        if {![dict exists $event $key]} {
            return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT] "stream event $eventType missing required key: $key"
        }
    }

    return $event
}

proc ::unified_llm::__stream_validate_order {events} {
    if {[llength $events] == 0} {
        return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_ORDER] "stream emitted no events"
    }

    if {[dict get [lindex $events 0] type] ne "STREAM_START"} {
        return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_ORDER] "first stream event must be STREAM_START"
    }

    set terminalType ""
    set openText {}
    set sawText {}
    set openTool {}
    foreach event $events {
        set eventType [dict get $event type]
        if {$terminalType ne ""} {
            return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_ORDER] "events emitted after terminal stream event"
        }
        switch -- $eventType {
            TEXT_START {
                set textId [dict get $event text_id]
                dict set openText $textId 1
                dict set sawText $textId 1
            }
            TEXT_DELTA {
                set textId [dict get $event text_id]
                if {![dict exists $openText $textId]} {
                    return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_ORDER] "TEXT_DELTA emitted before TEXT_START for text_id=$textId"
                }
            }
            TEXT_END {
                set textId [dict get $event text_id]
                if {![dict exists $openText $textId]} {
                    return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_ORDER] "TEXT_END emitted before TEXT_START for text_id=$textId"
                }
                dict unset openText $textId
            }
            TOOL_CALL_START {
                set toolCall [dict get $event tool_call]
                set toolId [dict get $toolCall id]
                dict set openTool $toolId 1
            }
            TOOL_CALL_DELTA - TOOL_CALL_END {
                set toolCall [dict get $event tool_call]
                set toolId [dict get $toolCall id]
                if {![dict exists $openTool $toolId]} {
                    return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_ORDER] "$eventType emitted before TOOL_CALL_START for tool_call.id=$toolId"
                }
                if {$eventType eq "TOOL_CALL_END"} {
                    dict unset openTool $toolId
                }
            }
            FINISH {
                set terminalType FINISH
            }
            ERROR {
                set terminalType ERROR
            }
            default {
                # Other event types do not participate in strict ordering checks.
            }
        }
    }

    if {$terminalType eq ""} {
        return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_ORDER] "stream is missing terminal FINISH/ERROR event"
    }
    if {$terminalType eq "FINISH" && [dict size $openText] > 0} {
        return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_ORDER] "stream terminated with unclosed TEXT segment(s)"
    }
    if {$terminalType eq "FINISH" && [dict size $openTool] > 0} {
        return -code error -errorcode [list UNIFIED_LLM STREAM INVALID_EVENT_ORDER] "stream terminated with unclosed TOOL_CALL segment(s)"
    }
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

    set providerState [::unified_llm::__state_for_provider $state $provider]
    dict set currentRequest provider $provider
    dict set currentRequest provider_options [::unified_llm::__merge_provider_options $state $provider $currentRequest]
    ::unified_llm::__validate_provider_options $provider [dict get $currentRequest provider_options]

    switch -- $provider {
        openai {
            set response [::unified_llm::adapters::openai::complete $providerState $currentRequest]
        }
        anthropic {
            set response [::unified_llm::adapters::anthropic::complete $providerState $currentRequest]
        }
        gemini {
            set response [::unified_llm::adapters::gemini::complete $providerState $currentRequest]
        }
        mock {
            set response [::unified_llm::adapters::mock_complete $providerState $currentRequest]
        }
    }

    return [::unified_llm::__apply_response_middlewares $middlewares $response]
}

proc ::unified_llm::__stream_from_response {provider response} {
    set events [list [::unified_llm::__stream_event STREAM_START provider $provider response_id [dict get $response response_id]]]
    set text ""
    if {[dict exists $response text]} {
        set text [dict get $response text]
    }
    if {$text ne ""} {
        set textId text-1
        lappend events [::unified_llm::__stream_event TEXT_START text_id $textId]
        foreach chunk [::unified_llm::adapters::__chunk_text $text 16] {
            lappend events [::unified_llm::__stream_event TEXT_DELTA text_id $textId delta $chunk]
        }
        lappend events [::unified_llm::__stream_event TEXT_END text_id $textId]
    }
    if {[dict exists $response tool_calls]} {
        foreach tc [dict get $response tool_calls] {
            lappend events [::unified_llm::__stream_event TOOL_CALL_START tool_call $tc]
            lappend events [::unified_llm::__stream_event TOOL_CALL_END tool_call $tc]
        }
    }
    lappend events [::unified_llm::__stream_event FINISH response $response usage [dict get $response usage]]
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

    set providerState [::unified_llm::__state_for_provider $state $provider]
    dict set currentRequest provider $provider
    dict set currentRequest provider_options [::unified_llm::__merge_provider_options $state $provider $currentRequest]
    ::unified_llm::__validate_provider_options $provider [dict get $currentRequest provider_options]

    switch -- $provider {
        openai {
            set streamResult [::unified_llm::adapters::openai::stream $providerState $currentRequest]
        }
        anthropic {
            set streamResult [::unified_llm::adapters::anthropic::stream $providerState $currentRequest]
        }
        gemini {
            set streamResult [::unified_llm::adapters::gemini::stream $providerState $currentRequest]
        }
        mock {
            set response [::unified_llm::adapters::mock_complete $providerState $currentRequest]
            set streamResult [::unified_llm::__stream_from_response $provider $response]
        }
    }

    set response [::unified_llm::__apply_response_middlewares $middlewares [dict get $streamResult response]]

    ::unified_llm::__stream_validate_order [dict get $streamResult events]

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

    set type [string tolower [dict get $part type]]
    switch -- $type {
        text {
            if {![dict exists $part text]} {
                return -code error -errorcode [list UNIFIED_LLM INPUT PART MALFORMED] "$type part requires text"
            }
            return [dict create type $type text [dict get $part text]]
        }
        thinking {
            if {![dict exists $part text]} {
                return -code error -errorcode [list UNIFIED_LLM INPUT PART MALFORMED] "thinking part requires text"
            }
            set normalized [dict create type thinking text [dict get $part text]]
            if {[dict exists $part signature] && [dict get $part signature] ne ""} {
                dict set normalized signature [dict get $part signature]
            }
            return $normalized
        }
        redacted_thinking {
            if {![dict exists $part data]} {
                return -code error -errorcode [list UNIFIED_LLM INPUT PART MALFORMED] "redacted_thinking part requires data"
            }
            return [dict create type redacted_thinking data [dict get $part data]]
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

proc ::unified_llm::__normalize_role {role} {
    set normalized [string tolower [string trim "$role"]]
    if {$normalized in {system user assistant tool developer}} {
        return $normalized
    }
    return -code error -errorcode [list UNIFIED_LLM INPUT ROLE_UNSUPPORTED] "unsupported message role: $role"
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

    set normalized [dict create role [::unified_llm::__normalize_role [dict get $message role]] content_parts $parts]
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
    variable stream_object_text_id
    variable stream_object_error

    if {![info exists stream_object_buffer($token)]} {
        return
    }

    set eventType [dict get $event type]
    if {$eventType eq "TEXT_START" && [dict exists $event text_id] && $stream_object_text_id($token) eq ""} {
        set stream_object_text_id($token) [dict get $event text_id]
    }
    if {$eventType eq "TEXT_DELTA" && [dict exists $event delta] && [dict exists $event text_id]} {
        if {$stream_object_text_id($token) eq ""} {
            set stream_object_text_id($token) [dict get $event text_id]
        }
        if {[dict get $event text_id] eq $stream_object_text_id($token)} {
            append stream_object_buffer($token) [dict get $event delta]
        }
    }
    if {$eventType eq "ERROR" && [dict exists $event error]} {
        set stream_object_error($token) [dict get $event error]
    }
    if {$eventType eq "FINISH" && [dict exists $event response]} {
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
    variable stream_object_text_id
    variable stream_object_error
    set token "stream-object-[clock clicks]"
    set stream_object_buffer($token) ""
    set stream_object_finished($token) 0
    set stream_object_response($token) {}
    set stream_object_text_id($token) ""
    set stream_object_error($token) {}

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
        unset -nocomplain stream_object_buffer($token) stream_object_finished($token) stream_object_response($token) stream_object_text_id($token) stream_object_error($token)
        return -options $errOpts $err
    }

    set buffered $stream_object_buffer($token)
    set gotFinish $stream_object_finished($token)
    set finalResponse $stream_object_response($token)
    set streamError $stream_object_error($token)
    unset -nocomplain stream_object_buffer($token) stream_object_finished($token) stream_object_response($token) stream_object_text_id($token) stream_object_error($token)

    if {!$gotFinish} {
        if {$streamError ne ""} {
            return -code error -errorcode [list UNIFIED_LLM OBJECT STREAM_ERROR] $streamError
        }
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
