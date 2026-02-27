namespace eval ::tests::http_fixture_server {
    variable seq 0
    variable states {}
    variable connections {}
}

proc ::tests::http_fixture_server::__reason_phrase {status} {
    switch -- $status {
        200 { return "OK" }
        201 { return "Created" }
        400 { return "Bad Request" }
        401 { return "Unauthorized" }
        403 { return "Forbidden" }
        404 { return "Not Found" }
        429 { return "Too Many Requests" }
        500 { return "Internal Server Error" }
        default { return "Status" }
    }
}

proc ::tests::http_fixture_server::new {responses} {
    variable seq
    variable states

    incr seq
    set id $seq
    set cmd ::tests::http_fixture_server::instance::$id

    set listener [socket -server [list ::tests::http_fixture_server::__accept $id] 0]
    set sockname [fconfigure $listener -sockname]
    set host [lindex $sockname 0]
    set port [lindex $sockname 2]
    if {$host eq "::" || $host eq ""} {
        set host 127.0.0.1
    }

    dict set states $id [dict create \
        listener $listener \
        host $host \
        port $port \
        responses $responses \
        requests {}]

    interp alias {} $cmd {} ::tests::http_fixture_server::__dispatch $id
    return $cmd
}

proc ::tests::http_fixture_server::__accept {id chan addr port} {
    variable connections

    fconfigure $chan -blocking 0 -buffering none -translation binary -encoding utf-8
    dict set connections $id,$chan [dict create \
        addr $addr \
        port $port \
        buffer "" \
        header_parsed 0 \
        method "" \
        path "" \
        version "" \
        headers {} \
        content_length 0 \
        body ""]

    fileevent $chan readable [list ::tests::http_fixture_server::__readable $id $chan]
}

proc ::tests::http_fixture_server::__parse_headers {headerText} {
    set lines [split $headerText "\n"]
    set requestLine [string trim [lindex $lines 0] "\r"]
    set method ""
    set path ""
    set version ""
    scan $requestLine "%s %s %s" method path version

    set headers {}
    for {set i 1} {$i < [llength $lines]} {incr i} {
        set line [string trim [lindex $lines $i] "\r"]
        if {$line eq ""} {
            continue
        }
        set idx [string first ":" $line]
        if {$idx < 0} {
            continue
        }
        set key [string trim [string range $line 0 [expr {$idx - 1}]]]
        set value [string trim [string range $line [expr {$idx + 1}] end]]
        dict set headers $key $value
    }

    return [dict create method $method path $path version $version headers $headers]
}

proc ::tests::http_fixture_server::__header_end_index {buffer} {
    set idx [string first "\r\n\r\n" $buffer]
    if {$idx >= 0} {
        return [dict create index $idx length 4]
    }

    set idx [string first "\n\n" $buffer]
    if {$idx >= 0} {
        return [dict create index $idx length 2]
    }

    return {}
}

proc ::tests::http_fixture_server::__maybe_consume {id chan} {
    variable connections
    variable states

    if {![dict exists $connections $id,$chan] || ![dict exists $states $id]} {
        return
    }

    set conn [dict get $connections $id,$chan]
    set buffer [dict get $conn buffer]

    if {![dict get $conn header_parsed]} {
        set headerEnd [::tests::http_fixture_server::__header_end_index $buffer]
        if {$headerEnd eq ""} {
            return
        }

        set idx [dict get $headerEnd index]
        set markerLen [dict get $headerEnd length]
        set headerText [string range $buffer 0 [expr {$idx - 1}]]
        set bodyRemainder [string range $buffer [expr {$idx + $markerLen}] end]
        set parsed [::tests::http_fixture_server::__parse_headers $headerText]

        dict set conn method [dict get $parsed method]
        dict set conn path [dict get $parsed path]
        dict set conn version [dict get $parsed version]
        dict set conn headers [dict get $parsed headers]
        dict set conn header_parsed 1
        dict set conn body $bodyRemainder

        set contentLength 0
        foreach key [dict keys [dict get $parsed headers]] {
            if {[string tolower $key] eq "content-length"} {
                set contentLength [dict get $parsed headers $key]
                break
            }
        }
        if {![string is integer -strict $contentLength]} {
            set contentLength 0
        }
        dict set conn content_length $contentLength
        dict set conn buffer ""
    }

    if {[string length [dict get $conn body]] < [dict get $conn content_length]} {
        dict set connections $id,$chan $conn
        return
    }

    set request [dict create \
        method [dict get $conn method] \
        path [dict get $conn path] \
        version [dict get $conn version] \
        headers [dict get $conn headers] \
        body [string range [dict get $conn body] 0 [expr {[dict get $conn content_length] - 1}]] \
        remote_addr [dict get $conn addr] \
        remote_port [dict get $conn port]]
    set allRequests [dict get $states $id requests]
    lappend allRequests [dict create {*}$request]
    dict set states $id requests $allRequests

    set response [dict create status_code 500 headers {} body "{}"]
    set scripted [dict get $states $id responses]
    if {[llength $scripted] > 0} {
        set response [lindex $scripted 0]
        dict set states $id responses [lrange $scripted 1 end]
    }

    set status [dict get $response status_code]
    set reason [::tests::http_fixture_server::__reason_phrase $status]
    set outBody [expr {[dict exists $response body] ? [dict get $response body] : ""}]
    set outHeaders {}
    if {[dict exists $response headers]} {
        set outHeaders [dict get $response headers]
    }
    if {![dict exists $outHeaders Content-Type]} {
        dict set outHeaders Content-Type application/json
    }
    dict set outHeaders Content-Length [string length $outBody]
    dict set outHeaders Connection close

    set payload "HTTP/1.1 $status $reason\r\n"
    foreach key [dict keys $outHeaders] {
        append payload "$key: [dict get $outHeaders $key]\r\n"
    }
    append payload "\r\n$outBody"
    puts -nonewline $chan $payload
    flush $chan
    catch {close $chan}
    dict unset connections $id,$chan
}

proc ::tests::http_fixture_server::__readable {id chan} {
    variable connections

    if {![dict exists $connections $id,$chan]} {
        catch {close $chan}
        return
    }

    set chunk [read $chan]
    if {$chunk ne ""} {
        set conn [dict get $connections $id,$chan]
        dict append conn buffer $chunk
        dict set connections $id,$chan $conn
    }

    if {[eof $chan] && $chunk eq ""} {
        catch {close $chan}
        dict unset connections $id,$chan
        return
    }

    ::tests::http_fixture_server::__maybe_consume $id $chan
}

proc ::tests::http_fixture_server::__dispatch {id method args} {
    variable states
    variable connections

    if {![dict exists $states $id]} {
        return -code error "unknown fixture server id: $id"
    }

    switch -- $method {
        url {
            return "http://[dict get $states $id host]:[dict get $states $id port]"
        }
        requests {
            return [dict get $states $id requests]
        }
        close {
            catch {close [dict get $states $id listener]}
            foreach key [dict keys $connections] {
                if {[string first "$id," $key] == 0} {
                    set chan [string range $key [expr {[string length "$id,"]}] end]
                    catch {close $chan}
                    dict unset connections $key
                }
            }
            rename ::tests::http_fixture_server::instance::$id {}
            dict unset states $id
            return {}
        }
        default {
            return -code error "unknown fixture server method: $method"
        }
    }
}
