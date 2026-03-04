namespace eval ::tests::http_client {}

package require http
package require json::write

proc ::tests::http_client::__encode_scalar {value} {
    if {[string is integer -strict $value] || [string is double -strict $value]} {
        return $value
    }
    if {$value in {true false null}} {
        return $value
    }
    return [::json::write string $value]
}

proc ::tests::http_client::__encode_object {payload} {
    set parts {}
    foreach key [dict keys $payload] {
        lappend parts "[::json::write string $key]:[::tests::http_client::__encode_scalar [dict get $payload $key]]"
    }
    return "{[join $parts ,]}"
}

proc ::tests::http_client::request {url args} {
    array set opts {
        -method GET
        -body ""
        -headers {}
        -type application/json
        -timeout 5000
    }
    array set opts $args

    set cmd [list ::http::geturl $url -method $opts(-method) -timeout $opts(-timeout)]
    if {$opts(-body) ne "" || $opts(-method) eq "POST"} {
        lappend cmd -type $opts(-type) -query $opts(-body)
    }
    if {[llength $opts(-headers)] > 0} {
        lappend cmd -headers $opts(-headers)
    }

    set token [{*}$cmd]
    set status [::http::ncode $token]
    set body [::http::data $token]
    set meta [::http::meta $token]
    ::http::cleanup $token
    return [dict create status $status body $body headers $meta]
}

proc ::tests::http_client::json_get {url} {
    set resp [::tests::http_client::request $url -method GET]
    set payload {}
    if {[dict get $resp body] ne ""} {
        set payload [::attractor_core::json_decode [dict get $resp body]]
    }
    return [dict create status [dict get $resp status] body $payload raw [dict get $resp body]]
}

proc ::tests::http_client::json_post {url payload} {
    set resp [::tests::http_client::request $url -method POST -body [::tests::http_client::__encode_object $payload] -headers [list Content-Type application/json]]
    set bodyPayload {}
    if {[dict get $resp body] ne ""} {
        set bodyPayload [::attractor_core::json_decode [dict get $resp body]]
    }
    return [dict create status [dict get $resp status] body $bodyPayload raw [dict get $resp body]]
}
