namespace eval ::tests::e2e_live {
    variable root [file normalize [file join [file dirname [info script]] .. ..]]
    variable run_id ""
    variable artifact_root ""
    variable selected_providers {}
    variable skipped_providers {}
    variable provider_configs {}
    variable component_list {unified_llm coding_agent_loop attractor}
    variable loaded_key_values {}
}

proc ::tests::e2e_live::provider_specs {} {
    return [dict create \
        openai [dict create key_var OPENAI_API_KEY model_var OPENAI_MODEL model_default gpt-4o-mini base_url_var OPENAI_BASE_URL base_url_default https://api.openai.com] \
        anthropic [dict create key_var ANTHROPIC_API_KEY model_var ANTHROPIC_MODEL model_default claude-sonnet-4-5 base_url_var ANTHROPIC_BASE_URL base_url_default https://api.anthropic.com] \
        gemini [dict create key_var GEMINI_API_KEY model_var GEMINI_MODEL model_default gemini-1.5-pro base_url_var GEMINI_BASE_URL base_url_default https://generativelanguage.googleapis.com]]
}

proc ::tests::e2e_live::timestamp_utc {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]
}

proc ::tests::e2e_live::env_to_dict {} {
    set out {}
    foreach {k v} [array get ::env] {
        dict set out $k $v
    }
    return $out
}

proc ::tests::e2e_live::__env_get {envDict name} {
    if {[dict exists $envDict $name]} {
        return [dict get $envDict $name]
    }
    return ""
}

proc ::tests::e2e_live::__env_has_nonempty {envDict name} {
    return [expr {[dict exists $envDict $name] && [string trim [dict get $envDict $name]] ne ""}]
}

proc ::tests::e2e_live::parse_provider_allowlist {raw} {
    set trimmed [string trim $raw]
    if {$trimmed eq ""} {
        return {}
    }

    set out {}
    foreach token [split $trimmed ","] {
        set provider [string tolower [string trim $token]]
        if {$provider eq ""} {
            continue
        }
        if {[lsearch -exact $out $provider] < 0} {
            lappend out $provider
        }
    }
    return $out
}

proc ::tests::e2e_live::resolve_provider_selection {envDict} {
    set specs [::tests::e2e_live::provider_specs]
    set knownProviders [list openai anthropic gemini]
    set requested [::tests::e2e_live::parse_provider_allowlist [::tests::e2e_live::__env_get $envDict E2E_LIVE_PROVIDERS]]
    set explicitRequest [expr {[llength $requested] > 0}]

    foreach provider $requested {
        if {$provider ni $knownProviders} {
            return -code error -errorcode [list E2E_LIVE CONFIG UNKNOWN_PROVIDER $provider] "unknown provider in E2E_LIVE_PROVIDERS: $provider"
        }
    }

    set selected {}
    set skipped {}

    if {$explicitRequest} {
        foreach provider $requested {
            set keyVar [dict get $specs $provider key_var]
            if {![::tests::e2e_live::__env_has_nonempty $envDict $keyVar]} {
                return -code error -errorcode [list E2E_LIVE CONFIG MISSING_KEY $provider $keyVar] "provider $provider requested but missing required key $keyVar"
            }
            lappend selected $provider
        }
    } else {
        foreach provider $knownProviders {
            set keyVar [dict get $specs $provider key_var]
            if {[::tests::e2e_live::__env_has_nonempty $envDict $keyVar]} {
                lappend selected $provider
            } else {
                lappend skipped [dict create provider $provider reason "missing $keyVar"]
            }
        }
    }

    if {[llength $selected] == 0} {
        return -code error -errorcode [list E2E_LIVE CONFIG NO_PROVIDERS] "no providers selected; set provider API keys or E2E_LIVE_PROVIDERS with configured keys"
    }

    set configs {}
    set loadedKeyValues {}
    foreach provider $knownProviders {
        set keyVar [dict get $specs $provider key_var]
        if {[::tests::e2e_live::__env_has_nonempty $envDict $keyVar]} {
            lappend loadedKeyValues [dict get $envDict $keyVar]
        }
    }

    foreach provider $selected {
        set spec [dict get $specs $provider]
        set keyVar [dict get $spec key_var]
        set modelVar [dict get $spec model_var]
        set baseUrlVar [dict get $spec base_url_var]
        set model [dict get $spec model_default]
        if {[::tests::e2e_live::__env_has_nonempty $envDict $modelVar]} {
            set model [string trim [dict get $envDict $modelVar]]
        }
        set baseUrl ""
        if {[::tests::e2e_live::__env_has_nonempty $envDict $baseUrlVar]} {
            set baseUrl [string trim [dict get $envDict $baseUrlVar]]
        }
        dict set configs $provider [dict create \
            provider $provider \
            key_var $keyVar \
            model $model \
            base_url $baseUrl \
            base_url_var $baseUrlVar \
            base_url_default [dict get $spec base_url_default]]
    }

    return [dict create \
        selected $selected \
        skipped $skipped \
        explicit_request $explicitRequest \
        provider_configs $configs \
        loaded_key_values $loadedKeyValues]
}

proc ::tests::e2e_live::initialize_run_context {} {
    variable root
    variable run_id
    variable artifact_root
    variable selected_providers
    variable skipped_providers
    variable provider_configs
    variable loaded_key_values
    variable component_list

    set envDict [::tests::e2e_live::env_to_dict]
    set selection [::tests::e2e_live::resolve_provider_selection $envDict]
    set selected_providers [dict get $selection selected]
    set skipped_providers [dict get $selection skipped]
    set provider_configs [dict get $selection provider_configs]
    set loaded_key_values [dict get $selection loaded_key_values]

    if {[::tests::e2e_live::__env_has_nonempty $envDict E2E_LIVE_ARTIFACT_ROOT]} {
        set artifact_root [file normalize [dict get $envDict E2E_LIVE_ARTIFACT_ROOT]]
        set run_id [file tail $artifact_root]
    } else {
        set run_id "[clock seconds]-[pid]"
        set artifact_root [file normalize [file join $root .scratch verification SPRINT-004 live $run_id]]
    }
    file mkdir $artifact_root

    set providerSummaries {}
    foreach provider $selected_providers {
        set cfg [dict get $provider_configs $provider]
        lappend providerSummaries [dict create \
            provider $provider \
            model [dict get $cfg model] \
            key_var [dict get $cfg key_var] \
            base_url [expr {[dict get $cfg base_url] ne "" ? [dict get $cfg base_url] : [dict get $cfg base_url_default]}]]
    }

    ::tests::e2e_live::write_json_file [file join $artifact_root run.json] [dict create \
        run_id $run_id \
        started_at [::tests::e2e_live::timestamp_utc] \
        selected_components $component_list \
        selected_providers $providerSummaries \
        skipped_providers $skipped_providers]

    puts "live-e2e run_id=$run_id"
    puts "live-e2e artifacts=$artifact_root"
    puts "live-e2e providers=[join $selected_providers ,]"
    if {[llength $skipped_providers] > 0} {
        puts "live-e2e skipped=[join [lmap item $skipped_providers {dict get $item provider}] ,]"
    }
}

proc ::tests::e2e_live::finalize_run_context {status args} {
    variable artifact_root
    variable run_id
    variable selected_providers
    variable skipped_providers
    variable component_list
    variable provider_configs

    set providerSummaries {}
    foreach provider $selected_providers {
        set cfg [dict get $provider_configs $provider]
        lappend providerSummaries [dict create \
            provider $provider \
            model [dict get $cfg model] \
            key_var [dict get $cfg key_var] \
            base_url [expr {[dict get $cfg base_url] ne "" ? [dict get $cfg base_url] : [dict get $cfg base_url_default]}]]
    }

    set payload [dict create \
        run_id $run_id \
        finished_at [::tests::e2e_live::timestamp_utc] \
        status $status \
        selected_components $component_list \
        selected_providers $providerSummaries \
        skipped_providers $skipped_providers]
    foreach {k v} $args {
        dict set payload $k $v
    }
    ::tests::e2e_live::write_json_file [file join $artifact_root run.json] $payload
}

proc ::tests::e2e_live::selected_providers {} {
    variable selected_providers
    return $selected_providers
}

proc ::tests::e2e_live::provider_config {provider} {
    variable provider_configs
    return [dict get $provider_configs $provider]
}

proc ::tests::e2e_live::env_value {name} {
    if {[info exists ::env($name)]} {
        return $::env($name)
    }
    return ""
}

proc ::tests::e2e_live::artifact_path {component provider filename} {
    variable artifact_root
    set dir [file join $artifact_root $component $provider]
    file mkdir $dir
    return [file join $dir $filename]
}

proc ::tests::e2e_live::write_json_file {path payload} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts -nonewline $fh [::attractor_core::json_encode $payload]
    close $fh
}

proc ::tests::e2e_live::write_text_file {path payload} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts -nonewline $fh $payload
    close $fh
}

proc ::tests::e2e_live::new_client {provider {apiKeyOverride ""}} {
    set cfg [::tests::e2e_live::provider_config $provider]
    set apiKey ""
    if {$apiKeyOverride ne ""} {
        set apiKey $apiKeyOverride
    } else {
        set apiKey [::tests::e2e_live::env_value [dict get $cfg key_var]]
    }
    set baseUrl [dict get $cfg base_url]

    return [::unified_llm::client_new \
        -provider $provider \
        -api_key $apiKey \
        -base_url $baseUrl \
        -transport ::unified_llm::transports::https_json::call]
}

proc ::tests::e2e_live::with_default_client {client body} {
    set previous ""
    if {[info exists ::unified_llm::default_client]} {
        set previous $::unified_llm::default_client
    }

    ::unified_llm::set_default_client $client
    set code [catch {uplevel 1 $body} result opts]
    ::unified_llm::set_default_client $previous
    if {$code} {
        return -options $opts $result
    }
    return $result
}

proc ::tests::e2e_live::assert_true {condition message} {
    if {!$condition} {
        return -code error $message
    }
}

proc ::tests::e2e_live::assert_no_real_secret_in_text {provider text} {
    set cfg [::tests::e2e_live::provider_config $provider]
    set realKey [::tests::e2e_live::env_value [dict get $cfg key_var]]
    if {$realKey ne "" && [string first $realKey $text] >= 0} {
        return -code error "real API key leaked in output for provider $provider"
    }
}

proc ::tests::e2e_live::run_unified_llm_smoke {provider} {
    set cfg [::tests::e2e_live::provider_config $provider]
    set client [::tests::e2e_live::new_client $provider]
    set prompt "Say hello in one sentence."
    set code [catch {
        set response [::unified_llm::generate \
            -client $client \
            -provider $provider \
            -model [dict get $cfg model] \
            -prompt $prompt \
            -max_tool_rounds 0]

        ::tests::e2e_live::assert_true [expr {[string trim [dict get $response text]] ne ""}] "expected non-empty live response text"
        ::tests::e2e_live::assert_true [expr {[dict get $response usage input_tokens] > 0}] "expected usage.input_tokens > 0"
        ::tests::e2e_live::assert_true [expr {[dict get $response usage output_tokens] > 0}] "expected usage.output_tokens > 0"

        if {$provider in {openai anthropic}} {
            ::tests::e2e_live::assert_true [expr {[dict get $response response_id] ni {"openai-response-1" "anthropic-response-1"}}] "expected provider-generated response_id"
        }
        if {$provider eq "gemini"} {
            ::tests::e2e_live::assert_true [expr {[dict exists $response raw candidates]}] "expected gemini raw.candidates in live response"
        }
        if {[dict exists $response request headers]} {
            set requestHeaders [dict get $response request headers]
            foreach headerName {Authorization x-api-key x-goog-api-key} {
                if {[dict exists $requestHeaders $headerName]} {
                    ::tests::e2e_live::assert_true [expr {[dict get $requestHeaders $headerName] eq "<redacted>"}] "expected redacted header: $headerName"
                }
            }
        }

        set artifact [::tests::e2e_live::artifact_path unified_llm $provider response.json]
        ::tests::e2e_live::write_json_file $artifact [dict create provider $provider prompt $prompt model [dict get $cfg model] response $response]
        set result 1
    } err opts]
    catch {$client close}
    if {$code} {
        set errorArtifact [::tests::e2e_live::artifact_path unified_llm $provider failure.txt]
        ::tests::e2e_live::write_text_file $errorArtifact $err
        return -options $opts $err
    }
    return $result
}

proc ::tests::e2e_live::run_unified_llm_invalid_key {provider} {
    set client [::tests::e2e_live::new_client $provider "__e2e_invalid_key__"]
    set code [catch {
        ::unified_llm::generate -client $client -provider $provider -prompt "Say hello." -model [dict get [::tests::e2e_live::provider_config $provider] model] -max_tool_rounds 0
    } err opts]
    catch {$client close}

    set artifact [::tests::e2e_live::artifact_path unified_llm $provider invalid-key.json]
    ::tests::e2e_live::write_json_file $artifact [dict create provider $provider error $err errorcode [expr {$code ? [dict get $opts -errorcode] : {}}]]

    ::tests::e2e_live::assert_true $code "expected invalid-key request to fail"
    set ec [dict get $opts -errorcode]
    ::tests::e2e_live::assert_true [expr {[llength $ec] == 5}] "expected 5-part errorcode for transport HTTP failure"
    ::tests::e2e_live::assert_true [expr {[lindex $ec 0] eq "UNIFIED_LLM" && [lindex $ec 1] eq "TRANSPORT" && [lindex $ec 2] eq "HTTP" && [lindex $ec 3] eq $provider}] "unexpected invalid-key errorcode shape"
    ::tests::e2e_live::assert_no_real_secret_in_text $provider $err
    return 1
}

proc ::tests::e2e_live::run_coding_agent_loop_smoke {provider} {
    set cfg [::tests::e2e_live::provider_config $provider]
    set client [::tests::e2e_live::new_client $provider]
    set session ""
    set previous ""
    if {[info exists ::unified_llm::default_client]} {
        set previous $::unified_llm::default_client
    }
    set code [catch {
        ::unified_llm::set_default_client $client
        set session [::coding_agent_loop::session new -profile $provider]
        set response [$session submit "Reply with one short sentence saying hello."]
        set events [$session events]
        set required {SESSION_START USER_INPUT ASSISTANT_TEXT_END}
        set seen {}
        foreach event $events {
            lappend seen [dict get $event type]
        }
        foreach requiredType $required {
            ::tests::e2e_live::assert_true [expr {[lsearch -exact $seen $requiredType] >= 0}] "missing required event type: $requiredType"
        }
        ::tests::e2e_live::assert_true [expr {[string trim [dict get $response text]] ne ""}] "expected non-empty assistant text"

        set artifact [::tests::e2e_live::artifact_path coding_agent_loop $provider response.json]
        ::tests::e2e_live::write_json_file $artifact [dict create provider $provider model [dict get $cfg model] response $response events $events]
        set result 1
    } err opts]
    if {$session ne ""} {
        catch {$session close}
    }
    ::unified_llm::set_default_client $previous
    catch {$client close}

    if {$code} {
        set errorArtifact [::tests::e2e_live::artifact_path coding_agent_loop $provider failure.txt]
        ::tests::e2e_live::write_text_file $errorArtifact $err
        return -options $opts $err
    }
    return $result
}

proc ::tests::e2e_live::run_coding_agent_loop_invalid_key {provider} {
    set client [::tests::e2e_live::new_client $provider "__e2e_invalid_key__"]
    set session ""
    set previous ""
    if {[info exists ::unified_llm::default_client]} {
        set previous $::unified_llm::default_client
    }
    set code [catch {
        ::unified_llm::set_default_client $client
        set session [::coding_agent_loop::session new -profile $provider]
        $session submit "Say hello in one sentence."
    } err opts]
    if {$session ne ""} {
        catch {$session close}
    }
    ::unified_llm::set_default_client $previous
    catch {$client close}

    set artifact [::tests::e2e_live::artifact_path coding_agent_loop $provider invalid-key.json]
    ::tests::e2e_live::write_json_file $artifact [dict create provider $provider error $err errorcode [expr {$code ? [dict get $opts -errorcode] : {}}]]

    ::tests::e2e_live::assert_true $code "expected invalid-key coding_agent_loop run to fail"
    set ec [dict get $opts -errorcode]
    ::tests::e2e_live::assert_true [expr {[llength $ec] == 5}] "expected transport HTTP errorcode for invalid-key coding_agent_loop run"
    ::tests::e2e_live::assert_true [expr {[lindex $ec 0] eq "UNIFIED_LLM" && [lindex $ec 1] eq "TRANSPORT" && [lindex $ec 2] eq "HTTP" && [lindex $ec 3] eq $provider}] "unexpected coding_agent_loop invalid-key errorcode"
    ::tests::e2e_live::assert_no_real_secret_in_text $provider $err
    return 1
}

proc ::tests::e2e_live::attractor_live_backend {provider request} {
    set cfg [::tests::e2e_live::provider_config $provider]
    set client [::tests::e2e_live::new_client $provider]
    set code [catch {
        set response [::unified_llm::generate \
            -client $client \
            -provider $provider \
            -prompt [dict get $request prompt] \
            -model [dict get $cfg model] \
            -max_tool_rounds 0]
        set text [dict get $response text]
        set usage [dict get $response usage]
    } err opts]
    catch {$client close}
    if {$code} {
        return -options $opts $err
    }
    return [dict create text $text usage $usage preferred_label success]
}

proc ::tests::e2e_live::attractor_invalid_key_backend {provider request} {
    set cfg [::tests::e2e_live::provider_config $provider]
    set client [::tests::e2e_live::new_client $provider "__e2e_invalid_key__"]
    set code [catch {
        ::unified_llm::generate \
            -client $client \
            -provider $provider \
            -prompt [dict get $request prompt] \
            -model [dict get $cfg model] \
            -max_tool_rounds 0
    } err opts]
    catch {$client close}
    if {$code} {
        return -options $opts $err
    }
    return [dict create text "unexpected-success" usage [dict create input_tokens 0 output_tokens 0 reasoning_tokens 0 cache_read_tokens 0 cache_write_tokens 0] preferred_label success]
}

proc ::tests::e2e_live::run_attractor_smoke {provider} {
    variable artifact_root
    set logsRoot [file join $artifact_root attractor $provider]
    file delete -force $logsRoot
    file mkdir $logsRoot

    set graph [::attractor::parse_dot {
        digraph live_smoke {
            start [shape=Mdiamond];
            build [handler=codergen, prompt="Say hello in one sentence."];
            exit [shape=Msquare];
            start -> build;
            build -> exit [label=success, weight=1];
        }
    }]

    set result [::attractor::run $graph -backend [list ::tests::e2e_live::attractor_live_backend $provider] -logs_root $logsRoot]
    ::tests::e2e_live::assert_true [expr {[dict get $result status] eq "success"}] "expected attractor live run success"
    ::tests::e2e_live::assert_true [file exists [file join $logsRoot checkpoint.json]] "expected attractor checkpoint.json"
    ::tests::e2e_live::assert_true [file exists [file join $logsRoot build status.json]] "expected build status.json"
    ::tests::e2e_live::assert_true [file exists [file join $logsRoot build prompt.md]] "expected build prompt.md"
    ::tests::e2e_live::assert_true [file exists [file join $logsRoot build response.md]] "expected build response.md"

    ::tests::e2e_live::write_json_file [file join $logsRoot summary.json] [dict create provider $provider result $result]
    return 1
}

proc ::tests::e2e_live::run_attractor_invalid_key {provider} {
    variable artifact_root
    set logsRoot [file join $artifact_root attractor $provider]
    file mkdir $logsRoot

    set graph [::attractor::parse_dot {
        digraph live_smoke_invalid {
            start [shape=Mdiamond];
            build [handler=codergen, prompt="Say hello in one sentence."];
            exit [shape=Msquare];
            start -> build;
            build -> exit [label=success, weight=1];
        }
    }]

    set code [catch {
        ::attractor::run $graph -backend [list ::tests::e2e_live::attractor_invalid_key_backend $provider] -logs_root $logsRoot
    } err opts]
    ::tests::e2e_live::write_json_file [file join $logsRoot invalid-key-failure.json] [dict create provider $provider error $err errorcode [expr {$code ? [dict get $opts -errorcode] : {}}]]

    ::tests::e2e_live::assert_true $code "expected attractor invalid-key run to fail"
    set ec [dict get $opts -errorcode]
    ::tests::e2e_live::assert_true [expr {[llength $ec] == 5}] "expected transport HTTP errorcode for attractor invalid-key run"
    ::tests::e2e_live::assert_true [expr {[lindex $ec 0] eq "UNIFIED_LLM" && [lindex $ec 1] eq "TRANSPORT" && [lindex $ec 2] eq "HTTP" && [lindex $ec 3] eq $provider}] "unexpected attractor invalid-key errorcode"
    ::tests::e2e_live::assert_no_real_secret_in_text $provider $err
    return 1
}

proc ::tests::e2e_live::__collect_files {rootDir} {
    set out {}
    foreach path [glob -nocomplain -directory $rootDir *] {
        if {[file isdirectory $path]} {
            set nested [::tests::e2e_live::__collect_files $path]
            foreach f $nested {
                lappend out $f
            }
        } else {
            lappend out $path
        }
    }
    return $out
}

proc ::tests::e2e_live::scan_artifacts_for_secret_leaks {} {
    variable artifact_root
    variable loaded_key_values

    set leaks {}
    foreach filePath [::tests::e2e_live::__collect_files $artifact_root] {
        if {![file exists $filePath]} {
            continue
        }
        if {[catch {
            set fh [open $filePath r]
            fconfigure $fh -translation binary -encoding binary
            set payload [read $fh]
            close $fh
        }]} {
            continue
        }

        foreach secret $loaded_key_values {
            if {$secret eq ""} {
                continue
            }
            if {[string first $secret $payload] >= 0} {
                lappend leaks $filePath
                break
            }
        }
    }
    return [lsort -unique $leaks]
}
