namespace eval ::unified_llm {
    variable version 0.1.0
    variable default_client ""
    variable client_seq 0
    variable clients {}
}

package require Tcl 8.5
package require json
package require attractor_core

source [file join [file dirname [info script]] adapters openai.tcl]
source [file join [file dirname [info script]] adapters anthropic.tcl]
source [file join [file dirname [info script]] adapters gemini.tcl]

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
    set provider mock
    if {[info exists ::env(OPENAI_API_KEY)]} {
        set provider openai
    } elseif {[info exists ::env(ANTHROPIC_API_KEY)]} {
        set provider anthropic
    } elseif {[info exists ::env(GEMINI_API_KEY)]} {
        set provider gemini
    }

    return [::unified_llm::client_new -provider $provider]
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

    set provider [dict get $state provider]
    if {[dict exists $currentRequest provider]} {
        set provider [dict get $currentRequest provider]
    }

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
        default {
            return -code error -errorcode [list UNIFIED_LLM PROVIDER UNKNOWN] "unsupported provider: $provider"
        }
    }

    foreach middleware [::unified_llm::__lreverse $middlewares] {
        if {[catch {{*}$middleware response $response} transformed]} {
            return -code error -errorcode [list UNIFIED_LLM MIDDLEWARE RESPONSE] $transformed
        }
        set response $transformed
    }

    return $response
}

proc ::unified_llm::__client_stream {id request args} {
    array set opts {
        -on_event ""
    }
    array set opts $args

    if {$opts(-on_event) eq ""} {
        return -code error "-on_event is required"
    }

    set response [::unified_llm::__client_complete $id $request]
    {*}$opts(-on_event) [dict create type STREAM_START provider [dict get $response provider]]
    set text ""
    if {[dict exists $response text]} {
        set text [dict get $response text]
    }
    if {$text ne ""} {
        {*}$opts(-on_event) [dict create type TEXT_DELTA delta $text]
    }

    if {[dict exists $response tool_calls]} {
        foreach tc [dict get $response tool_calls] {
            {*}$opts(-on_event) [dict create type TOOL_CALL_END tool_call $tc]
        }
    }

    {*}$opts(-on_event) [dict create type FINISH response $response usage [dict get $response usage]]
    return [dict create handle stream-1 response $response]
}

proc ::unified_llm::__lreverse {items} {
    set out {}
    foreach item $items {
        set out [linsert $out 0 $item]
    }
    return $out
}

proc ::unified_llm::message {role content args} {
    set msg [dict create role $role content $content]
    foreach {k v} $args {
        dict set msg $k $v
    }
    return $msg
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

    if {$opts(-client) eq ""} {
        set client [::unified_llm::default_client]
    } else {
        set client $opts(-client)
    }

    if {$opts(-prompt) ne "" && [llength $opts(-messages)] > 0} {
        return -code error -errorcode [list UNIFIED_LLM INPUT] "provide either -prompt or -messages"
    }

    if {$opts(-prompt) ne ""} {
        set messages [list [::unified_llm::message user $opts(-prompt)]]
    } else {
        set messages $opts(-messages)
    }

    set request [dict create \
        model $opts(-model) \
        messages $messages \
        tools $opts(-tools) \
        provider_options $opts(-provider_options)]

    if {$opts(-provider) ne ""} {
        dict set request provider $opts(-provider)
    }

    set totalUsage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0]

    set response [$client complete $request]
    set totalUsage [::unified_llm::usage_add $totalUsage [dict get $response usage]]

    set round 0
    while {$opts(-max_tool_rounds) != 0 && $round < $opts(-max_tool_rounds)} {
        if {![dict exists $response tool_calls] || [llength [dict get $response tool_calls]] == 0} {
            break
        }

        set toolResults [::unified_llm::execute_tool_calls [dict get $response tool_calls] $opts(-tools)]
        dict set request tool_results $toolResults
        dict set request continuation_from [dict get $response response_id]

        set response [$client complete $request]
        set totalUsage [::unified_llm::usage_add $totalUsage [dict get $response usage]]
        incr round
    }

    dict set response usage $totalUsage
    return $response
}

proc ::unified_llm::stream {args} {
    array set opts {
        -client ""
        -on_event ""
    }
    array set opts $args

    if {$opts(-on_event) eq ""} {
        return -code error "-on_event is required"
    }

    set forwardArgs {}
    foreach {k v} $args {
        if {$k in {-on_event}} {
            continue
        }
        lappend forwardArgs $k $v
    }

    set response [::unified_llm::generate {*}$forwardArgs]
    {*}$opts(-on_event) [dict create type STREAM_START]
    if {[dict exists $response text]} {
        {*}$opts(-on_event) [dict create type TEXT_DELTA delta [dict get $response text]]
    }
    {*}$opts(-on_event) [dict create type FINISH response $response usage [dict get $response usage]]
    return [dict create handle stream-1 response $response]
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
        return -code error -errorcode [list UNIFIED_LLM NO_OBJECT_GENERATED] "response is not valid JSON"
    }

    set errors [::attractor_core::schema_validate $opts(-schema) $decoded]
    if {[llength $errors] > 0} {
        return -code error -errorcode [list UNIFIED_LLM NO_OBJECT_GENERATED] $errors
    }

    return [dict create object $decoded response $response]
}

proc ::unified_llm::stream_object {args} {
    array set opts {
        -on_object ""
    }
    array set opts $args

    if {$opts(-on_object) eq ""} {
        return -code error "-on_object is required"
    }

    set result [::unified_llm::generate_object {*}$args]
    {*}$opts(-on_object) [dict get $result object]
    return $result
}

proc ::unified_llm::usage_add {a b} {
    set merged [dict create]
    foreach key {input_tokens output_tokens reasoning_tokens cache_read_tokens} {
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
    foreach call $toolCalls {
        lappend results [::unified_llm::invoke_tool_call $call $toolDefinitions]
    }
    return $results
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

    set input {}
    if {[dict exists $toolCall arguments]} {
        set input [dict get $toolCall arguments]
    }

    set command [dict get $toolDefinitions $toolName]
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
    if {[llength $messages] > 0} {
        set last [dict get [lindex $messages end] content]
    }

    return [dict create \
        provider mock \
        response_id mock-response-1 \
        text "mock:$last" \
        tool_calls {} \
        usage [dict create input_tokens 1 output_tokens 1 reasoning_tokens 0 cache_read_tokens 0] \
        raw [dict create ok 1]]
}

proc ::unified_llm::__load_models {} {
    set path [file join [file dirname [info script]] models.json]
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
