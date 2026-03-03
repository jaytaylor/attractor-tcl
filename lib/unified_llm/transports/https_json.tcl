namespace eval ::unified_llm::transports {}
namespace eval ::unified_llm::transports::https_json {
    variable https_registered 0
    variable https_registration_state uninitialized
    variable https_registration_failure_mode ""
    variable https_registration_failure_reason ""
    variable tls_min_version "1.7.22"
    variable tls_require_impl [list ::unified_llm::transports::https_json::__tls_require_impl_default]
    variable tls_provide_impl [list ::unified_llm::transports::https_json::__tls_provide_impl_default]
    variable tls_register_impl [list ::unified_llm::transports::https_json::__tls_register_impl_default]
}

package require Tcl 8.5
package require http
package require attractor_core

proc ::unified_llm::transports::https_json::__default_base_url {provider} {
    switch -- $provider {
        openai { return "https://api.openai.com" }
        anthropic { return "https://api.anthropic.com" }
        gemini { return "https://generativelanguage.googleapis.com" }
        default { return "" }
    }
}

proc ::unified_llm::transports::https_json::__provider_base_url_env {provider} {
    switch -- $provider {
        openai { return OPENAI_BASE_URL }
        anthropic { return ANTHROPIC_BASE_URL }
        gemini { return GEMINI_BASE_URL }
        default { return "" }
    }
}

proc ::unified_llm::transports::https_json::__resolve_base_url {request} {
    set provider [dict get $request provider]

    if {[dict exists $request base_url] && [dict get $request base_url] ne ""} {
        return [dict get $request base_url]
    }

    set envVar [::unified_llm::transports::https_json::__provider_base_url_env $provider]
    if {$envVar ne "" && [info exists ::env($envVar)] && [string trim $::env($envVar)] ne ""} {
        return [string trim $::env($envVar)]
    }

    return [::unified_llm::transports::https_json::__default_base_url $provider]
}

proc ::unified_llm::transports::https_json::__join_url {baseUrl endpoint} {
    set normalizedBase [string trim $baseUrl]
    if {$normalizedBase eq ""} {
        return $endpoint
    }

    # Preserve endpoint when it already includes the base path prefix.
    if {![regexp {^([a-z]+://[^/]+)(/.*)?$} $normalizedBase -> origin basePath]} {
        set normalizedBase [string trimright $normalizedBase "/"]
        return "${normalizedBase}${endpoint}"
    }

    if {$basePath eq "" || $basePath eq "/"} {
        return "${origin}${endpoint}"
    }

    set normalizedPath [string trimright $basePath "/"]
    if {$endpoint eq $normalizedPath || [string match "${normalizedPath}/*" $endpoint]} {
        return "${origin}${endpoint}"
    }

    return "${origin}${normalizedPath}${endpoint}"
}

proc ::unified_llm::transports::https_json::__headers_to_list {headers} {
    set out {}
    foreach key [dict keys $headers] {
        lappend out $key [dict get $headers $key]
    }
    return $out
}

proc ::unified_llm::transports::https_json::__split_content_type {headers} {
    set outHeaders {}
    set contentType application/json
    foreach key [dict keys $headers] {
        set value [dict get $headers $key]
        if {[string tolower $key] eq "content-type"} {
            if {[string trim $value] ne ""} {
                set contentType [string trim $value]
            }
            continue
        }
        dict set outHeaders $key $value
    }
    return [dict create content_type $contentType headers $outHeaders]
}

proc ::unified_llm::transports::https_json::__normalize_headers {meta} {
    set out {}
    foreach {k v} $meta {
        dict set out [string tolower $k] $v
    }
    return $out
}

proc ::unified_llm::transports::https_json::__summarize_body {body} {
    set compact [string trim [string map [list "\n" " " "\r" " " "\t" " "] $body]]
    if {$compact eq ""} {
        return ""
    }
    if {[string length $compact] > 512} {
        return "[string range $compact 0 511]..."
    }
    return $compact
}

proc ::unified_llm::transports::https_json::__tls_require_impl_default {} {
    return [package require tls]
}

proc ::unified_llm::transports::https_json::__tls_provide_impl_default {} {
    return [package provide tls]
}

proc ::unified_llm::transports::https_json::__tls_register_impl_default {} {
    return [::http::register https 443 ::tls::socket]
}

proc ::unified_llm::transports::https_json::__invoke_impl {scriptList} {
    return [{*}$scriptList]
}

proc ::unified_llm::transports::https_json::__tls_require_package {} {
    variable tls_require_impl
    return [::unified_llm::transports::https_json::__invoke_impl $tls_require_impl]
}

proc ::unified_llm::transports::https_json::__tls_provided_version {} {
    variable tls_provide_impl
    return [::unified_llm::transports::https_json::__invoke_impl $tls_provide_impl]
}

proc ::unified_llm::transports::https_json::__tls_register_https {} {
    variable tls_register_impl
    return [::unified_llm::transports::https_json::__invoke_impl $tls_register_impl]
}

proc ::unified_llm::transports::https_json::__tls_runtime_probe {} {
    variable tls_min_version

    set out [dict create \
        tcl_version [info patchlevel] \
        tls_min_version $tls_min_version \
        tls_available 0 \
        tls_supported 0]

    if {[catch {set requiredVersion [::unified_llm::transports::https_json::__tls_require_package]} requireErr]} {
        dict set out status error
        dict set out message "missing Tcl package tls (requires tls >= $tls_min_version). Install tcl-tls or set TCLSH to a runtime with newer tls."
        dict set out error_detail [::unified_llm::transports::https_json::__summarize_body $requireErr]
        return $out
    }

    if {[catch {set providedVersion [string trim [::unified_llm::transports::https_json::__tls_provided_version]]} provideErr]} {
        dict set out tls_available 1
        dict set out status error
        dict set out message "unable to determine tls runtime version (requires tls >= $tls_min_version). Install or upgrade tcl-tls."
        dict set out error_detail [::unified_llm::transports::https_json::__summarize_body $provideErr]
        return $out
    }
    if {$providedVersion eq ""} {
        set providedVersion [string trim $requiredVersion]
    }
    if {$providedVersion eq ""} {
        dict set out status error
        dict set out message "unable to determine tls runtime version (requires tls >= $tls_min_version). Install or upgrade tcl-tls."
        return $out
    }

    dict set out tls_available 1
    dict set out tls_version $providedVersion

    if {[catch {set comparison [package vcompare $providedVersion $tls_min_version]} compareErr]} {
        dict set out status error
        dict set out message "failed to compare tls runtime version $providedVersion with required minimum $tls_min_version. Install or upgrade tcl-tls."
        dict set out error_detail [::unified_llm::transports::https_json::__summarize_body $compareErr]
        return $out
    }

    if {$comparison < 0} {
        dict set out status error
        dict set out message "tls runtime $providedVersion is unsupported (requires tls >= $tls_min_version). Upgrade tcl-tls or set TCLSH to a runtime with newer tls."
        return $out
    }

    dict set out status ok
    dict set out tls_supported 1
    dict set out message "tls runtime $providedVersion satisfies minimum $tls_min_version"
    return $out
}

proc ::unified_llm::transports::https_json::__reset_https_registration_state {} {
    variable https_registered
    variable https_registration_state
    variable https_registration_failure_mode
    variable https_registration_failure_reason

    set https_registered 0
    set https_registration_state uninitialized
    set https_registration_failure_mode ""
    set https_registration_failure_reason ""
}

proc ::unified_llm::transports::https_json::__format_registration_failure {provider mode reason} {
    if {$mode eq "initialize"} {
        return "failed to initialize https transport for provider $provider: $reason"
    }
    return "https transport unavailable for provider $provider: $reason"
}

proc ::unified_llm::transports::https_json::__ensure_https_registered {provider} {
    variable https_registered
    variable https_registration_state
    variable https_registration_failure_mode
    variable https_registration_failure_reason

    if {$https_registration_state eq "ready"} {
        set https_registered 1
        return
    }

    if {$https_registration_state eq "failed"} {
        set message [::unified_llm::transports::https_json::__format_registration_failure $provider $https_registration_failure_mode $https_registration_failure_reason]
        return -code error -errorcode [list UNIFIED_LLM TRANSPORT NETWORK $provider] $message
    }

    set probe [::unified_llm::transports::https_json::__tls_runtime_probe]
    if {![dict get $probe tls_supported]} {
        set https_registration_state failed
        set https_registration_failure_mode unavailable
        set https_registration_failure_reason [dict get $probe message]
        set https_registered 0
        set message [::unified_llm::transports::https_json::__format_registration_failure $provider unavailable $https_registration_failure_reason]
        return -code error -errorcode [list UNIFIED_LLM TRANSPORT NETWORK $provider] $message
    }

    if {[catch {::unified_llm::transports::https_json::__tls_register_https} regErr]} {
        set summary [::unified_llm::transports::https_json::__summarize_body $regErr]
        set reason "failed to register ::tls::socket handler"
        if {$summary ne ""} {
            set reason "$reason: $summary"
        }
        set https_registration_state failed
        set https_registration_failure_mode initialize
        set https_registration_failure_reason $reason
        set https_registered 0
        set message [::unified_llm::transports::https_json::__format_registration_failure $provider initialize $reason]
        return -code error -errorcode [list UNIFIED_LLM TRANSPORT NETWORK $provider] $message
    }

    set https_registration_state ready
    set https_registration_failure_mode ""
    set https_registration_failure_reason ""
    set https_registered 1
}

proc ::unified_llm::transports::https_json::runtime_preflight {} {
    return [::unified_llm::transports::https_json::__tls_runtime_probe]
}

proc ::unified_llm::transports::https_json::call {request} {
    foreach key {provider endpoint payload headers} {
        if {![dict exists $request $key]} {
            return -code error -errorcode [list UNIFIED_LLM TRANSPORT INPUT MISSING_FIELD] "transport request missing required field: $key"
        }
    }

    set provider [dict get $request provider]
    set endpoint [dict get $request endpoint]
    if {![string match "/*" $endpoint]} {
        return -code error -errorcode [list UNIFIED_LLM TRANSPORT INPUT INVALID_ENDPOINT] "transport endpoint must start with /"
    }

    set baseUrl [::unified_llm::transports::https_json::__resolve_base_url $request]
    if {$baseUrl eq ""} {
        return -code error -errorcode [list UNIFIED_LLM TRANSPORT INPUT MISSING_BASE_URL $provider] "no base URL configured for provider $provider"
    }

    set url [::unified_llm::transports::https_json::__join_url $baseUrl $endpoint]
    if {[string match "https://*" [string tolower $url]]} {
        ::unified_llm::transports::https_json::__ensure_https_registered $provider
    }

    set timeoutMs 60000
    if {[dict exists $request timeout_ms] && [string is integer -strict [dict get $request timeout_ms]]} {
        set timeoutMs [dict get $request timeout_ms]
    }

    set headerParts [::unified_llm::transports::https_json::__split_content_type [dict get $request headers]]
    set contentType [dict get $headerParts content_type]
    set headerList [::unified_llm::transports::https_json::__headers_to_list [dict get $headerParts headers]]
    set payloadBody [::attractor_core::json_encode [dict get $request payload]]
    set token ""
    set status 0
    set responseBody ""
    set responseHeaders {}

    set code [catch {
        set token [::http::geturl $url \
            -method POST \
            -type $contentType \
            -headers $headerList \
            -query $payloadBody \
            -timeout $timeoutMs]
        set status [::http::ncode $token]
        set responseBody [::http::data $token]
        set responseHeaders [::unified_llm::transports::https_json::__normalize_headers [::http::meta $token]]
    } err opts]

    if {$token ne ""} {
        ::http::cleanup $token
    }

    if {$code} {
        set summary [::unified_llm::transports::https_json::__summarize_body $err]
        set detail ""
        if {$summary ne ""} {
            set detail ": $summary"
        }
        return -code error -errorcode [list UNIFIED_LLM TRANSPORT NETWORK $provider] "network request failed for provider $provider$detail"
    }

    if {$status < 200 || $status >= 300} {
        set summary [::unified_llm::transports::https_json::__summarize_body $responseBody]
        set detail ""
        if {$summary ne ""} {
            set detail " body=$summary"
        }
        return -code error -errorcode [list UNIFIED_LLM TRANSPORT HTTP $provider $status] "http request failed for provider $provider with status $status$detail"
    }

    return [dict create status_code $status headers $responseHeaders body $responseBody]
}
