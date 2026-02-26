namespace eval ::tests::mock_http_server {
    variable seq 0
    variable states {}
}

proc ::tests::mock_http_server::new {scriptedResponses} {
    variable seq
    variable states

    incr seq
    set id $seq
    set cmd ::tests::mock_http_server::instance::$id

    dict set states $id [dict create responses $scriptedResponses requests {}]
    interp alias {} $cmd {} ::tests::mock_http_server::__dispatch $id
    return $cmd
}

proc ::tests::mock_http_server::__dispatch {id method args} {
    variable states

    switch -- $method {
        handle {
            if {[llength $args] != 1} {
                return -code error "usage: \$server handle requestDict"
            }
            set request [lindex $args 0]
            dict lappend states $id requests $request

            set responses [dict get $states $id responses]
            if {[llength $responses] == 0} {
                return [dict create status_code 500 headers {} body "{}"]
            }

            set next [lindex $responses 0]
            set remaining [lrange $responses 1 end]
            dict set states $id responses $remaining
            return $next
        }
        requests {
            return [dict get $states $id requests]
        }
        close {
            rename ::tests::mock_http_server::instance::$id {}
            dict unset states $id
            return {}
        }
        default {
            return -code error "unknown mock server method: $method"
        }
    }
}
