namespace eval ::attractor_web {
    variable version 0.1.0
    variable server_seq 0
    variable run_seq 0
    variable servers {}
    variable root [file normalize [file join [file dirname [info script]] .. ..]]
}

package require Tcl 8.5
package require attractor
package require attractor_core

proc ::attractor_web::__json_quote {value} {
    return "\"[string map [list "\\" "\\\\" "\"" "\\\"" "\n" "\\n" "\r" "\\r" "\t" "\\t"] $value]\""
}

proc ::attractor_web::__json_read_raw {path fallback} {
    if {![file exists $path]} {
        return $fallback
    }
    if {[catch {set raw [::attractor_web::__read_file $path]}]} {
        return $fallback
    }
    if {[catch {::attractor_core::json_decode $raw}]} {
        return $fallback
    }
    return $raw
}

proc ::attractor_web::__iso8601_now {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]
}

proc ::attractor_web::__millis_now {} {
    if {[catch {set ms [clock clicks -milliseconds]}]} {
        set ms [expr {[clock seconds] * 1000}]
    }
    return $ms
}

proc ::attractor_web::__http_reason {status} {
    switch -- $status {
        200 { return "OK" }
        201 { return "Created" }
        400 { return "Bad Request" }
        404 { return "Not Found" }
        413 { return "Payload Too Large" }
        500 { return "Internal Server Error" }
        default { return "Status" }
    }
}

proc ::attractor_web::__json_error {message code} {
    return [dict create error $message code $code]
}

proc ::attractor_web::__read_file {path} {
    set fh [open $path r]
    set payload [read $fh]
    close $fh
    return $payload
}

proc ::attractor_web::__read_json_file {path} {
    if {![file exists $path]} {
        return {}
    }
    if {[catch {set payload [::attractor_web::__read_file $path]} err]} {
        return {}
    }
    if {[catch {set decoded [::attractor_core::json_decode $payload]}]} {
        return {}
    }
    return $decoded
}

proc ::attractor_web::__write_text_file {path payload} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts -nonewline $fh $payload
    close $fh
}

proc ::attractor_web::__write_json_file {path payload} {
    ::attractor_web::__write_text_file $path [::attractor_core::json_encode $payload]
}

proc ::attractor_web::__sha256_hex {payload} {
    if {[catch {package require sha256}]} {
        return ""
    }
    if {[catch {set digest [::sha2::sha256 -hex $payload]}]} {
        return ""
    }
    return $digest
}

proc ::attractor_web::__decode_component {value} {
    set value [string map [list + " "] $value]
    set out ""
    set i 0
    set n [string length $value]
    while {$i < $n} {
        set ch [string index $value $i]
        if {$ch eq "%" && $i + 2 < $n} {
            set hx [string range $value [expr {$i + 1}] [expr {$i + 2}]]
            if {[regexp {^[0-9A-Fa-f]{2}$} $hx]} {
                scan $hx %x code
                append out [format %c $code]
                incr i 3
                continue
            }
        }
        append out $ch
        incr i
    }
    return $out
}

proc ::attractor_web::__parse_query {queryText} {
    set out {}
    if {$queryText eq ""} {
        return $out
    }
    foreach pair [split $queryText &] {
        if {$pair eq ""} {
            continue
        }
        set eqIdx [string first = $pair]
        if {$eqIdx < 0} {
            set key [::attractor_web::__decode_component $pair]
            set value ""
        } else {
            set key [::attractor_web::__decode_component [string range $pair 0 [expr {$eqIdx - 1}]]]
            set value [::attractor_web::__decode_component [string range $pair [expr {$eqIdx + 1}] end]]
        }
        dict set out $key $value
    }
    return $out
}

proc ::attractor_web::__split_path_query {pathWithQuery} {
    set qidx [string first ? $pathWithQuery]
    if {$qidx < 0} {
        return [list $pathWithQuery {}]
    }
    set path [string range $pathWithQuery 0 [expr {$qidx - 1}]]
    set query [string range $pathWithQuery [expr {$qidx + 1}] end]
    return [list $path [::attractor_web::__parse_query $query]]
}

proc ::attractor_web::__run_id_valid {runId} {
    return [expr {[regexp {^[A-Za-z0-9][A-Za-z0-9_.-]*$} $runId] && [string first ".." $runId] < 0}]
}

proc ::attractor_web::__node_id_valid {nodeId} {
    return [regexp {^[A-Za-z_][A-Za-z0-9_]*$} $nodeId]
}

proc ::attractor_web::__qid_valid {qid} {
    return [regexp {^q-[0-9]+$} $qid]
}

proc ::attractor_web::__filename_valid {name} {
    if {[string trim $name] eq ""} {
        return 0
    }
    if {[string first ".." $name] >= 0} {
        return 0
    }
    if {[regexp {[/\\]} $name]} {
        return 0
    }
    return 1
}

proc ::attractor_web::normalize_dot_source {dotSource} {
    set trimmed [string trim $dotSource]
    if {[regexp {(?s)^```[ \t]*([A-Za-z0-9_-]+)?[ \t]*\n(.*)\n```[ \t]*$} $trimmed -> _ body]} {
        set trimmed [string trim $body]
    }
    return $trimmed
}

proc ::attractor_web::__html_dashboard {} {
    return {<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Attractor Dashboard</title>
  <style>
    :root { color-scheme: light; }
    body { margin: 0; font-family: "IBM Plex Sans", "Helvetica Neue", sans-serif; background: linear-gradient(135deg, #f4f8ff, #eef7ec); color: #132a1f; }
    header { padding: 14px 18px; background: #113a2d; color: #f2fff2; display: flex; justify-content: space-between; align-items: center; }
    main { display: grid; grid-template-columns: 340px 1fr; min-height: calc(100vh - 56px); }
    aside { border-right: 1px solid #d5e4d7; padding: 14px; overflow: auto; }
    section { padding: 14px; overflow: auto; }
    textarea { width: 100%; min-height: 140px; }
    input, button, textarea { font: inherit; }
    button { cursor: pointer; }
    .run { border: 1px solid #cadccf; padding: 10px; border-radius: 10px; margin-bottom: 10px; background: #fff; }
    .run.active { border-color: #1b6c4e; box-shadow: 0 0 0 2px #d6ebdf; }
    .status { font-weight: 600; }
    pre { background: #0f1d17; color: #d9fbe9; padding: 12px; border-radius: 8px; overflow: auto; }
    .row { display: flex; gap: 8px; margin: 8px 0; }
    .grow { flex: 1; }
    .question { border: 1px solid #f5d06f; background: #fff9ea; padding: 10px; border-radius: 10px; margin: 8px 0; }
    .indicator { font-size: 12px; padding: 4px 8px; border-radius: 999px; background: #274e3f; }
    .indicator.offline { background: #712626; }
    .meta { color: #476155; font-size: 12px; }
  </style>
</head>
<body>
  <header>
    <div>Attractor Web Dashboard</div>
    <div id="conn" class="indicator offline">SSE offline</div>
  </header>
  <main>
    <aside>
      <h3>Start Run</h3>
      <div class="row">
        <input id="dotfile" class="grow" type="file" accept=".dot,text/plain">
      </div>
      <textarea id="dot" placeholder="Paste DOT source"></textarea>
      <div class="row">
        <button id="runBtn">Run</button>
        <button id="refreshBtn">Refresh</button>
      </div>
      <p id="runErr" style="color:#9f1f1f"></p>
      <h3>Runs</h3>
      <div id="runs"></div>
    </aside>
    <section>
      <h3 id="title">Select a run</h3>
      <div id="summary"></div>
      <div id="questions"></div>
      <h4>Rendered Graph</h4>
      <div id="graph"></div>
      <h4>Stage Artifact</h4>
      <pre id="stage">(none)</pre>
      <h4>Run Events</h4>
      <pre id="events">(none)</pre>
    </section>
  </main>
  <script>
    const state = { runs: [], selected: null, fileName: '', eventSource: null, runEventSource: null, runEvents: [] };

    function setConn(ok) {
      const el = document.getElementById('conn');
      el.classList.toggle('offline', !ok);
      el.textContent = ok ? 'SSE online' : 'SSE offline';
    }

    function showError(msg) {
      document.getElementById('runErr').textContent = msg || '';
    }

    async function api(path, opts) {
      const res = await fetch(path, opts);
      const ct = res.headers.get('content-type') || '';
      const body = ct.includes('application/json') ? await res.json() : await res.text();
      if (!res.ok) {
        const msg = body && body.error ? `${body.code || 'ERROR'}: ${body.error}` : `HTTP ${res.status}`;
        throw new Error(msg);
      }
      return body;
    }

    function renderRuns() {
      const wrap = document.getElementById('runs');
      wrap.innerHTML = '';
      for (const run of state.runs) {
        const el = document.createElement('div');
        el.className = `run${state.selected === run.id ? ' active' : ''}`;
        el.innerHTML = `<div><strong>${run.id}</strong></div><div class="status">${run.status}</div><div class="meta">node=${run.current_node || '-'} completed=${run.completed_nodes_count || 0}</div>`;
        el.onclick = () => selectRun(run.id);
        wrap.appendChild(el);
      }
    }

    async function refreshRuns() {
      state.runs = await api('/api/pipelines');
      renderRuns();
      if (state.selected && !state.runs.find(r => r.id === state.selected)) {
        state.selected = null;
      }
      if (state.selected) {
        await loadRun(state.selected);
      }
    }

    async function startRun() {
      showError('');
      try {
        const payload = { dotSource: document.getElementById('dot').value };
        if (state.fileName) payload.fileName = state.fileName;
        const out = await api('/api/run', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        await refreshRuns();
        await selectRun(out.id);
      } catch (err) {
        showError(err.message);
      }
    }

    async function loadRun(runId) {
      const run = await api(`/api/pipeline?id=${encodeURIComponent(runId)}`);
      document.getElementById('title').textContent = `Run ${run.id}`;
      document.getElementById('summary').textContent = JSON.stringify({ status: run.status, current_node: run.current_node, web: run.web }, null, 2);

      try {
        const rendered = await api('/api/render', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ dotSource: run.dotSource })
        });
        document.getElementById('graph').innerHTML = rendered.svg || '';
      } catch (err) {
        document.getElementById('graph').textContent = err.message;
      }

      const qWrap = document.getElementById('questions');
      qWrap.innerHTML = '';
      for (const q of (run.pending_questions || [])) {
        const node = document.createElement('div');
        node.className = 'question';
        node.innerHTML = `<div><strong>${q.question}</strong></div>`;
        const row = document.createElement('div');
        row.className = 'row';
        for (const choice of (q.choices || [])) {
          const b = document.createElement('button');
          b.textContent = choice.label;
          b.onclick = async () => {
            await api('/api/answer', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ id: run.id, qid: q.qid, chosen_label: choice.label })
            });
            await loadRun(run.id);
          };
          row.appendChild(b);
        }
        node.appendChild(row);
        qWrap.appendChild(node);
      }

      const nodeKeys = Object.keys(run.nodes || {});
      if (nodeKeys.length > 0) {
        const stage = await api(`/api/stage?id=${encodeURIComponent(run.id)}&node=${encodeURIComponent(nodeKeys[nodeKeys.length - 1])}`);
        document.getElementById('stage').textContent = JSON.stringify(stage, null, 2);
      } else {
        document.getElementById('stage').textContent = '(none)';
      }
    }

    async function selectRun(runId) {
      state.selected = runId;
      renderRuns();
      await loadRun(runId);
      if (state.runEventSource) state.runEventSource.close();
      state.runEvents = [];
      document.getElementById('events').textContent = '(waiting)';
      state.runEventSource = new EventSource(`/events/${encodeURIComponent(runId)}`);
      state.runEventSource.onmessage = (evt) => {
        state.runEvents.push(evt.data);
        if (state.runEvents.length > 80) state.runEvents.shift();
        document.getElementById('events').textContent = state.runEvents.join('\n');
      };
      state.runEventSource.onerror = () => {};
    }

    function connectGlobalSse() {
      if (state.eventSource) state.eventSource.close();
      const es = new EventSource('/events');
      state.eventSource = es;
      es.onopen = () => setConn(true);
      es.onerror = () => setConn(false);
      es.onmessage = async (evt) => {
        try {
          state.runs = JSON.parse(evt.data);
          renderRuns();
          if (state.selected) {
            await loadRun(state.selected);
          }
        } catch (_) {}
      };
    }

    document.getElementById('runBtn').onclick = startRun;
    document.getElementById('refreshBtn').onclick = refreshRuns;
    document.getElementById('dotfile').onchange = async (evt) => {
      const file = evt.target.files && evt.target.files[0];
      if (!file) return;
      state.fileName = file.name;
      document.getElementById('dot').value = await file.text();
    };

    refreshRuns().then(connectGlobalSse);
  </script>
</body>
</html>
}
}

proc ::attractor_web::__server_path_safe {base path} {
    set baseNorm [file normalize $base]
    set pathNorm [file normalize $path]
    if {$pathNorm eq $baseNorm} {
        return 1
    }
    return [expr {[string first "$baseNorm/" "$pathNorm/"] == 0}]
}

proc ::attractor_web::__run_dir {runsRoot runId} {
    return [file normalize [file join $runsRoot $runId]]
}

proc ::attractor_web::__run_ids {runsRoot} {
    set ids {}
    foreach path [lsort [glob -nocomplain -directory $runsRoot *]] {
        if {[file isdirectory $path]} {
            lappend ids [file tail $path]
        }
    }
    return $ids
}

proc ::attractor_web::__load_checkpoint_summary {runDir} {
    set checkpoint [::attractor_web::__read_json_file [file join $runDir checkpoint.json]]
    if {[dict size $checkpoint] == 0} {
        return [dict create current_node "" completed_nodes_count 0]
    }
    set current [expr {[dict exists $checkpoint current_node] ? [dict get $checkpoint current_node] : ""}]
    set count 0
    if {[dict exists $checkpoint completed_nodes]} {
        set count [llength [dict get $checkpoint completed_nodes]]
    }
    return [dict create current_node $current completed_nodes_count $count]
}

proc ::attractor_web::__load_run_status {runDir} {
    set status running
    set reason ""
    set worker [::attractor_web::__read_json_file [file join $runDir worker-result.json]]
    if {[dict size $worker] > 0 && [dict exists $worker status]} {
        set status [dict get $worker status]
        if {[dict exists $worker reason]} {
            set reason [dict get $worker reason]
        }
    }
    return [dict create status $status reason $reason]
}

proc ::attractor_web::__pipelines_snapshot {runsRoot} {
    set out {}
    foreach runId [::attractor_web::__run_ids $runsRoot] {
        if {![::attractor_web::__run_id_valid $runId]} {
            continue
        }
        set runDir [::attractor_web::__run_dir $runsRoot $runId]
        if {![::attractor_web::__server_path_safe $runsRoot $runDir]} {
            continue
        }
        set web [::attractor_web::__read_json_file [file join $runDir web.json]]
        set summary [::attractor_web::__load_checkpoint_summary $runDir]
        set statusInfo [::attractor_web::__load_run_status $runDir]
        set startedAt ""
        if {[dict size $web] > 0 && [dict exists $web created_at]} {
            set startedAt [dict get $web created_at]
        } else {
            set manifest [::attractor_web::__read_json_file [file join $runDir manifest.json]]
            if {[dict size $manifest] > 0 && [dict exists $manifest started_at]} {
                set startedAt [dict get $manifest started_at]
            }
        }
        if {$startedAt eq ""} {
            set startedAt "-"
        }
        set currentNode [dict get $summary current_node]
        if {$currentNode eq ""} {
            set currentNode "-"
        }
        lappend out [dict create \
            id $runId \
            started_at $startedAt \
            status [dict get $statusInfo status] \
            current_node $currentNode \
            completed_nodes_count [dict get $summary completed_nodes_count] \
            logs_root $runDir]
    }
    return $out
}

proc ::attractor_web::__events_lines {runDir} {
    set path [file join $runDir events.ndjson]
    if {![file exists $path]} {
        return {}
    }
    set payload [::attractor_web::__read_file $path]
    set out {}
    foreach line [split $payload "\n"] {
        set line [string trim $line]
        if {$line ne ""} {
            lappend out $line
        }
    }
    return $out
}

proc ::attractor_web::__pipelines_snapshot_json {runsRoot} {
    set items {}
    foreach row [::attractor_web::__pipelines_snapshot $runsRoot] {
        lappend items "{\"id\":[::attractor_web::__json_quote [dict get $row id]],\"started_at\":[::attractor_web::__json_quote [dict get $row started_at]],\"status\":[::attractor_web::__json_quote [dict get $row status]],\"current_node\":[::attractor_web::__json_quote [dict get $row current_node]],\"completed_nodes_count\":[dict get $row completed_nodes_count],\"logs_root\":[::attractor_web::__json_quote [dict get $row logs_root]]}"
    }
    return "\[[join $items ,]\]"
}

proc ::attractor_web::__pending_questions {runDir} {
    set out {}
    set qdir [file join $runDir questions]
    foreach pending [lsort [glob -nocomplain -directory $qdir *.pending.json]] {
        set qid [string range [file tail $pending] 0 end-13]
        set answer [file join $qdir "$qid.answer.json"]
        if {[file exists $answer]} {
            continue
        }
        set payload [::attractor_web::__read_json_file $pending]
        if {[dict size $payload] > 0} {
            lappend out $payload
        }
    }
    return $out
}

proc ::attractor_web::__pending_questions_json {runDir} {
    set items {}
    set qdir [file join $runDir questions]
    foreach pending [lsort [glob -nocomplain -directory $qdir *.pending.json]] {
        set qid [string range [file tail $pending] 0 end-13]
        set answer [file join $qdir "$qid.answer.json"]
        if {[file exists $answer]} {
            continue
        }
        lappend items [::attractor_web::__json_read_raw $pending "{}"]
    }
    return "\[[join $items ,]\]"
}

proc ::attractor_web::__nodes_json {runDir} {
    set items {}
    foreach p [lsort [glob -nocomplain -directory $runDir *]] {
        if {![file isdirectory $p]} {
            continue
        }
        set nodeId [file tail $p]
        if {![::attractor_web::__node_id_valid $nodeId]} {
            continue
        }
        set statusPath [file join $p status.json]
        if {![file exists $statusPath]} {
            continue
        }
        lappend items "[::attractor_web::__json_quote $nodeId]:[::attractor_web::__json_read_raw $statusPath "{}"]"
    }
    return "{[join $items ,]}"
}

proc ::attractor_web::__pipeline_detail_json {runsRoot runId} {
    if {![::attractor_web::__run_id_valid $runId]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_ID] "invalid run id"
    }
    set runDir [::attractor_web::__run_dir $runsRoot $runId]
    if {![::attractor_web::__server_path_safe $runsRoot $runDir] || ![file isdirectory $runDir]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "run not found"
    }

    set status running
    set currentNode "-"
    set completedCount 0
    foreach row [::attractor_web::__pipelines_snapshot $runsRoot] {
        if {[dict get $row id] eq $runId} {
            set status [dict get $row status]
            set currentNode [dict get $row current_node]
            set completedCount [dict get $row completed_nodes_count]
            break
        }
    }

    set dotSource ""
    set dotPath [file join $runDir pipeline.dot]
    if {[file exists $dotPath]} {
        set dotSource [::attractor_web::__read_file $dotPath]
    }

    set webJson [::attractor_web::__json_read_raw [file join $runDir web.json] "{}"]
    set manifestJson [::attractor_web::__json_read_raw [file join $runDir manifest.json] "{}"]
    set checkpointJson [::attractor_web::__json_read_raw [file join $runDir checkpoint.json] "{}"]
    set nodesJson [::attractor_web::__nodes_json $runDir]
    set questionsJson [::attractor_web::__pending_questions_json $runDir]

    return "{\"id\":[::attractor_web::__json_quote $runId],\"status\":[::attractor_web::__json_quote $status],\"current_node\":[::attractor_web::__json_quote $currentNode],\"completed_nodes_count\":$completedCount,\"dotSource\":[::attractor_web::__json_quote $dotSource],\"web\":$webJson,\"manifest\":$manifestJson,\"checkpoint\":$checkpointJson,\"nodes\":$nodesJson,\"pending_questions\":$questionsJson}"
}

proc ::attractor_web::__stage_detail_json {runsRoot runId nodeId} {
    if {![::attractor_web::__run_id_valid $runId] || ![::attractor_web::__node_id_valid $nodeId]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_ID] "invalid id"
    }
    set runDir [::attractor_web::__run_dir $runsRoot $runId]
    set nodeDir [file normalize [file join $runDir $nodeId]]
    if {![::attractor_web::__server_path_safe $runDir $nodeDir] || ![file isdirectory $nodeDir]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "stage not found"
    }

    set statusPath [file join $nodeDir status.json]
    if {![file exists $statusPath]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "stage not found"
    }

    set prompt ""
    set response ""
    set promptPath [file join $nodeDir prompt.md]
    set responsePath [file join $nodeDir response.md]
    if {[file exists $promptPath]} {
        set prompt [::attractor_web::__read_file $promptPath]
    }
    if {[file exists $responsePath]} {
        set response [::attractor_web::__read_file $responsePath]
    }

    set statusJson [::attractor_web::__json_read_raw $statusPath "{}"]
    return "{\"status\":$statusJson,\"prompt_md\":[::attractor_web::__json_quote $prompt],\"response_md\":[::attractor_web::__json_quote $response]}"
}

proc ::attractor_web::__node_artifacts {runDir} {
    set out {}
    foreach p [lsort [glob -nocomplain -directory $runDir *]] {
        if {![file isdirectory $p]} {
            continue
        }
        set nodeId [file tail $p]
        if {![::attractor_web::__node_id_valid $nodeId]} {
            continue
        }
        set status [::attractor_web::__read_json_file [file join $p status.json]]
        if {[dict size $status] == 0} {
            continue
        }
        dict set out $nodeId $status
    }
    return $out
}

proc ::attractor_web::__pipeline_detail {runsRoot runId} {
    if {![::attractor_web::__run_id_valid $runId]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_ID] "invalid run id"
    }
    set runDir [::attractor_web::__run_dir $runsRoot $runId]
    if {![::attractor_web::__server_path_safe $runsRoot $runDir] || ![file isdirectory $runDir]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "run not found"
    }

    set snapshot {}
    foreach row [::attractor_web::__pipelines_snapshot $runsRoot] {
        if {[dict get $row id] eq $runId} {
            set snapshot $row
            break
        }
    }
    if {$snapshot eq ""} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "run not found"
    }

    set dotSource ""
    set dotPath [file join $runDir pipeline.dot]
    if {[file exists $dotPath]} {
        set dotSource [::attractor_web::__read_file $dotPath]
    }

    return [dict create \
        id $runId \
        status [dict get $snapshot status] \
        current_node [dict get $snapshot current_node] \
        completed_nodes_count [dict get $snapshot completed_nodes_count] \
        dotSource $dotSource \
        web [::attractor_web::__read_json_file [file join $runDir web.json]] \
        manifest [::attractor_web::__read_json_file [file join $runDir manifest.json]] \
        checkpoint [::attractor_web::__read_json_file [file join $runDir checkpoint.json]] \
        nodes [::attractor_web::__node_artifacts $runDir] \
        pending_questions [::attractor_web::__pending_questions $runDir]]
}

proc ::attractor_web::__stage_detail {runsRoot runId nodeId} {
    if {![::attractor_web::__run_id_valid $runId] || ![::attractor_web::__node_id_valid $nodeId]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_ID] "invalid id"
    }
    set runDir [::attractor_web::__run_dir $runsRoot $runId]
    set nodeDir [file normalize [file join $runDir $nodeId]]
    if {![::attractor_web::__server_path_safe $runDir $nodeDir] || ![file isdirectory $nodeDir]} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "stage not found"
    }

    set status [::attractor_web::__read_json_file [file join $nodeDir status.json]]
    if {[dict size $status] == 0} {
        return -code error -errorcode [list ATTRACTOR_WEB NOT_FOUND] "stage not found"
    }

    set prompt ""
    set response ""
    set promptPath [file join $nodeDir prompt.md]
    set responsePath [file join $nodeDir response.md]
    if {[file exists $promptPath]} {
        set prompt [::attractor_web::__read_file $promptPath]
    }
    if {[file exists $responsePath]} {
        set response [::attractor_web::__read_file $responsePath]
    }

    return [dict create status $status prompt_md $prompt response_md $response]
}

proc ::attractor_web::__request_json {requestVar} {
    upvar 1 $requestVar request
    set body [dict get $request body]
    if {[string trim $body] eq ""} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_JSON] "request body is required"
    }
    if {[catch {set decoded [::attractor_core::json_decode $body]} err]} {
        return -code error -errorcode [list ATTRACTOR_WEB INVALID_JSON] $err
    }
    return $decoded
}

proc ::attractor_web::__worker_script_path {} {
    variable root
    return [file join $root bin attractor-worker]
}

proc ::attractor_web::__spawn_worker {id runId runDir} {
    variable servers
    set state [dict get $servers $id]

    set workerScript [::attractor_web::__worker_script_path]
    set cmd [list [info nameofexecutable] $workerScript --run-id $runId --run-dir $runDir --max-question-wait-ms [dict get $state max_question_wait_ms]]
    set pipeline [linsert $cmd 0 |]

    if {[catch {set chan [open $pipeline r]} err]} {
        return -code error -errorcode [list ATTRACTOR_WEB WORKER_SPAWN_FAILED] $err
    }
    fconfigure $chan -blocking 0 -buffering none -translation binary -encoding utf-8
    set pid [lindex [pid $chan] 0]

    dict set state workers $chan [dict create run_id $runId pid $pid output ""]
    dict set servers $id $state

    fileevent $chan readable [list ::attractor_web::__worker_readable $id $chan]
    return $pid
}

proc ::attractor_web::__worker_readable {id chan} {
    variable servers
    if {![dict exists $servers $id]} {
        catch {close $chan}
        return
    }
    set state [dict get $servers $id]
    if {![dict exists $state workers $chan]} {
        catch {close $chan}
        return
    }

    set chunk [read $chan]
    if {$chunk ne ""} {
        set worker [dict get $state workers $chan]
        dict append worker output $chunk
        dict set state workers $chan $worker
    }

    if {[eof $chan]} {
        set worker [dict get $state workers $chan]
        set runId [dict get $worker run_id]
        set runsRoot [dict get $state runs_root]
        set runDir [::attractor_web::__run_dir $runsRoot $runId]

        set exitCode 0
        if {[catch {close $chan} closeErr closeOpts]} {
            set exitCode 1
            if {[dict exists $closeOpts -errorcode] && [lindex [dict get $closeOpts -errorcode] 0] eq "CHILDSTATUS"} {
                set exitCode [lindex [dict get $closeOpts -errorcode] 2]
            }
        }

        if {$exitCode != 0 && ![file exists [file join $runDir worker-result.json]]} {
            ::attractor_web::__write_json_file [file join $runDir worker-result.json] [dict create \
                run_id $runId \
                status failed \
                reason worker_failed \
                ended_at [::attractor_web::__iso8601_now]]
        }

        dict unset state workers $chan
        dict set servers $id $state
    } else {
        dict set servers $id $state
    }
}

proc ::attractor_web::__send_response {chan status contentType body {extraHeaders {}}} {
    set reason [::attractor_web::__http_reason $status]
    set headers [dict create \
        Content-Type $contentType \
        Content-Length [string length $body] \
        Connection close]
    foreach {k v} $extraHeaders {
        dict set headers $k $v
    }

    puts -nonewline $chan "HTTP/1.1 $status $reason\r\n"
    foreach key [dict keys $headers] {
        puts -nonewline $chan "$key: [dict get $headers $key]\r\n"
    }
    puts -nonewline $chan "\r\n$body"
    flush $chan
}

proc ::attractor_web::__send_json {chan status payload} {
    ::attractor_web::__send_response $chan $status application/json [::attractor_core::json_encode $payload]
}

proc ::attractor_web::__send_sse_headers {chan} {
    puts -nonewline $chan "HTTP/1.1 200 OK\r\n"
    puts -nonewline $chan "Content-Type: text/event-stream\r\n"
    puts -nonewline $chan "Cache-Control: no-cache\r\n"
    puts -nonewline $chan "Connection: keep-alive\r\n\r\n"
    flush $chan
}

proc ::attractor_web::__send_sse_data {chan payload} {
    foreach line [split $payload "\n"] {
        puts -nonewline $chan "data: $line\n"
    }
    puts -nonewline $chan "\n"
    flush $chan
}

proc ::attractor_web::__send_sse_comment {chan text} {
    puts -nonewline $chan ": $text\n\n"
    flush $chan
}

proc ::attractor_web::__remove_sse_client {id chan} {
    variable servers
    if {![dict exists $servers $id]} {
        catch {close $chan}
        return
    }
    set state [dict get $servers $id]
    if {[dict exists $state sse_clients $chan]} {
        dict unset state sse_clients $chan
        dict set servers $id $state
    }
    catch {close $chan}
}

proc ::attractor_web::__sse_readable {id chan} {
    if {[eof $chan]} {
        ::attractor_web::__remove_sse_client $id $chan
        return
    }
    read $chan
}

proc ::attractor_web::__sse_add_global {id chan} {
    variable servers
    set state [dict get $servers $id]
    set snapshotJson [::attractor_web::__pipelines_snapshot_json [dict get $state runs_root]]
    dict set state sse_clients $chan [dict create kind global last_payload $snapshotJson sent_count 0 run_id ""]
    dict set servers $id $state
    ::attractor_web::__send_sse_headers $chan
    ::attractor_web::__send_sse_data $chan $snapshotJson
    fileevent $chan readable [list ::attractor_web::__sse_readable $id $chan]
}

proc ::attractor_web::__sse_add_run {id chan runId} {
    variable servers
    set state [dict get $servers $id]
    set runDir [::attractor_web::__run_dir [dict get $state runs_root] $runId]
    if {![file isdirectory $runDir]} {
        ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error "run not found" NOT_FOUND]
        catch {close $chan}
        return
    }
    set lines [::attractor_web::__events_lines $runDir]
    dict set state sse_clients $chan [dict create kind run run_id $runId sent_count 0 last_payload ""]
    dict set servers $id $state
    ::attractor_web::__send_sse_headers $chan
    foreach line $lines {
        ::attractor_web::__send_sse_data $chan $line
    }
    set state [dict get $servers $id]
    if {[dict exists $state sse_clients $chan]} {
        dict set state sse_clients $chan sent_count [llength $lines]
        dict set servers $id $state
    }
    fileevent $chan readable [list ::attractor_web::__sse_readable $id $chan]
}

proc ::attractor_web::__collect_http_request {buffer maxBodyBytes} {
    set markerIdx [string first "\r\n\r\n" $buffer]
    set markerLen 4
    if {$markerIdx < 0} {
        set markerIdx [string first "\n\n" $buffer]
        set markerLen 2
    }
    if {$markerIdx < 0} {
        return [dict create ready 0]
    }

    set headerText [string range $buffer 0 [expr {$markerIdx - 1}]]
    set bodyText [string range $buffer [expr {$markerIdx + $markerLen}] end]
    set lines [split [string map [list "\r\n" "\n" "\r" "\n"] $headerText] "\n"]
    set requestLine [lindex $lines 0]
    if {![regexp {^([A-Z]+) ([^ ]+) (HTTP/[0-9.]+)$} $requestLine -> method path version]} {
        return [dict create ready 1 error INVALID_HTTP]
    }

    set headers {}
    for {set i 1} {$i < [llength $lines]} {incr i} {
        set line [lindex $lines $i]
        if {$line eq ""} {
            continue
        }
        set sep [string first : $line]
        if {$sep < 0} {
            continue
        }
        set key [string trim [string range $line 0 [expr {$sep - 1}]]]
        set value [string trim [string range $line [expr {$sep + 1}] end]]
        dict set headers [string tolower $key] $value
    }

    set contentLength 0
    if {[dict exists $headers content-length]} {
        set contentLength [dict get $headers content-length]
        if {![string is integer -strict $contentLength] || $contentLength < 0} {
            return [dict create ready 1 error INVALID_HTTP]
        }
    }

    if {$contentLength > $maxBodyBytes} {
        return [dict create ready 1 error BODY_TOO_LARGE]
    }

    if {[string length $bodyText] < $contentLength} {
        return [dict create ready 0]
    }

    set body [string range $bodyText 0 [expr {$contentLength - 1}]]
    return [dict create \
        ready 1 \
        request [dict create method $method path $path version $version headers $headers body $body] \
        consumed [expr {$markerIdx + $markerLen + $contentLength}]]
}

proc ::attractor_web::__dispatch_route {id chan request} {
    variable servers
    set state [dict get $servers $id]
    lassign [::attractor_web::__split_path_query [dict get $request path]] path query
    set method [dict get $request method]
    set runsRoot [dict get $state runs_root]

    if {$method eq "GET" && $path eq "/"} {
        ::attractor_web::__send_response $chan 200 "text/html; charset=utf-8" [::attractor_web::__html_dashboard]
        return 0
    }

    if {$method eq "GET" && $path eq "/api/pipelines"} {
        ::attractor_web::__send_response $chan 200 application/json [::attractor_web::__pipelines_snapshot_json $runsRoot]
        return 0
    }

    if {$method eq "POST" && $path eq "/api/run"} {
        if {[catch {set payload [::attractor_web::__request_json request]} err opts]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_JSON]
            return 0
        }
        if {![dict exists $payload dotSource]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "dotSource is required" INVALID_DOT_SOURCE]
            return 0
        }

        set dotSource [::attractor_web::normalize_dot_source [dict get $payload dotSource]]
        if {[string trim $dotSource] eq ""} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "dotSource is empty after normalization" INVALID_DOT_SOURCE]
            return 0
        }

        set fileName ""
        if {[dict exists $payload fileName]} {
            set fileName [dict get $payload fileName]
            if {![::attractor_web::__filename_valid $fileName]} {
                ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "fileName must be a simple leaf name" INVALID_FILE_NAME]
                return 0
            }
        }

        if {[catch {set _graph [::attractor::parse_dot $dotSource]} parseErr]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $parseErr INVALID_DOT_SOURCE]
            return 0
        }
        set diagnostics [::attractor::validate $_graph]
        if {[::attractor::__has_validation_errors $diagnostics]} {
            ::attractor_web::__send_json $chan 400 [dict create error "validation failed" code INVALID_DOT_SOURCE diagnostics $diagnostics]
            return 0
        }

        variable run_seq
        incr run_seq
        set runId "run-[::attractor_web::__millis_now]-$run_seq"
        set runDir [::attractor_web::__run_dir $runsRoot $runId]
        file mkdir $runDir

        ::attractor_web::__write_text_file [file join $runDir pipeline.dot] $dotSource
        set webMeta [dict create \
            run_id $runId \
            file_name $fileName \
            created_at [::attractor_web::__iso8601_now] \
            dot_sha256 [::attractor_web::__sha256_hex $dotSource] \
            worker_pid ""]
        ::attractor_web::__write_json_file [file join $runDir web.json] $webMeta

        if {[catch {set pid [::attractor_web::__spawn_worker $id $runId $runDir]} spawnErr]} {
            ::attractor_web::__write_json_file [file join $runDir worker-result.json] [dict create run_id $runId status failed reason worker_spawn_failed error $spawnErr ended_at [::attractor_web::__iso8601_now]]
            ::attractor_web::__send_json $chan 500 [::attractor_web::__json_error $spawnErr WORKER_SPAWN_FAILED]
            return 0
        }

        dict set webMeta worker_pid $pid
        ::attractor_web::__write_json_file [file join $runDir web.json] $webMeta
        ::attractor_web::__send_json $chan 200 [dict create ok true id $runId]
        return 0
    }

    if {$method eq "GET" && $path eq "/api/pipeline"} {
        if {![dict exists $query id]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "id is required" INVALID_ID]
            return 0
        }
        set runId [dict get $query id]
        if {[catch {set detailJson [::attractor_web::__pipeline_detail_json $runsRoot $runId]} err opts]} {
            set code [expr {[dict exists $opts -errorcode] ? [lindex [dict get $opts -errorcode] end] : ""}]
            if {$code eq "NOT_FOUND"} {
                ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error $err NOT_FOUND]
            } else {
                ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_ID]
            }
            return 0
        }
        ::attractor_web::__send_response $chan 200 application/json $detailJson
        return 0
    }

    if {$method eq "GET" && $path eq "/api/stage"} {
        if {![dict exists $query id] || ![dict exists $query node]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "id and node are required" INVALID_ID]
            return 0
        }
        if {[catch {set detailJson [::attractor_web::__stage_detail_json $runsRoot [dict get $query id] [dict get $query node]]} err opts]} {
            set code [expr {[dict exists $opts -errorcode] ? [lindex [dict get $opts -errorcode] end] : ""}]
            if {$code eq "NOT_FOUND"} {
                ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error $err NOT_FOUND]
            } else {
                ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_ID]
            }
            return 0
        }
        ::attractor_web::__send_response $chan 200 application/json $detailJson
        return 0
    }

    if {$method eq "POST" && $path eq "/api/answer"} {
        if {[catch {set payload [::attractor_web::__request_json request]} err opts]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_JSON]
            return 0
        }
        foreach key {id qid chosen_label} {
            if {![dict exists $payload $key] || [string trim [dict get $payload $key]] eq ""} {
                ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "missing required field: $key" INVALID_ID]
                return 0
            }
        }

        set runId [dict get $payload id]
        set qid [dict get $payload qid]
        if {![::attractor_web::__run_id_valid $runId] || ![::attractor_web::__qid_valid $qid]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "invalid id" INVALID_ID]
            return 0
        }

        set runDir [::attractor_web::__run_dir $runsRoot $runId]
        if {![file isdirectory $runDir]} {
            ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error "run not found" NOT_FOUND]
            return 0
        }

        set pendingPath [file join $runDir questions "$qid.pending.json"]
        if {![file exists $pendingPath]} {
            ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error "question not found" NOT_FOUND]
            return 0
        }

        set pending [::attractor_web::__read_json_file $pendingPath]
        set chosen [dict get $payload chosen_label]
        set valid 0
        foreach choice [dict get $pending choices] {
            if {[dict get $choice label] eq $chosen} {
                set valid 1
                break
            }
        }
        if {!$valid} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "chosen_label is not valid for this question" INVALID_ID]
            return 0
        }

        ::attractor_web::__write_json_file [file join $runDir questions "$qid.answer.json"] [dict create qid $qid chosen_label $chosen answered_at [::attractor_web::__iso8601_now]]
        ::attractor_web::__send_json $chan 200 [dict create ok true id $runId qid $qid]
        return 0
    }

    if {$method eq "POST" && $path eq "/api/render"} {
        if {[catch {set payload [::attractor_web::__request_json request]} err opts]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error $err INVALID_JSON]
            return 0
        }
        if {![dict exists $payload dotSource]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "dotSource is required" INVALID_DOT_SOURCE]
            return 0
        }
        set dotSource [::attractor_web::normalize_dot_source [dict get $payload dotSource]]
        if {[string trim $dotSource] eq ""} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "dotSource is empty after normalization" INVALID_DOT_SOURCE]
            return 0
        }

        set dotCmd [dict get $state dot_bin]
        if {[auto_execok $dotCmd] eq ""} {
            ::attractor_web::__send_json $chan 500 [::attractor_web::__json_error "Graphviz dot binary not found" DOT_BINARY_MISSING]
            return 0
        }

        set tmpPath [file join [dict get $state runs_root] ".render-[pid]-[::attractor_web::__millis_now].dot"]
        ::attractor_web::__write_text_file $tmpPath $dotSource
        set code [catch {set svg [exec $dotCmd -Tsvg $tmpPath]} renderErr renderOpts]
        file delete -force $tmpPath
        if {$code != 0} {
            ::attractor_web::__send_json $chan 500 [::attractor_web::__json_error $renderErr DOT_RENDER_FAILED]
            return 0
        }

        ::attractor_web::__send_json $chan 200 [dict create ok true svg $svg]
        return 0
    }

    if {$method eq "GET" && $path eq "/events"} {
        ::attractor_web::__sse_add_global $id $chan
        return 1
    }

    if {$method eq "GET" && [string first "/events/" $path] == 0} {
        set runId [string range $path 8 end]
        if {![::attractor_web::__run_id_valid $runId]} {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "invalid id" INVALID_ID]
            return 0
        }
        ::attractor_web::__sse_add_run $id $chan $runId
        return 1
    }

    ::attractor_web::__send_json $chan 404 [::attractor_web::__json_error "not found" NOT_FOUND]
    return 0
}

proc ::attractor_web::__on_client_readable {id chan} {
    variable servers
    if {![dict exists $servers $id]} {
        catch {close $chan}
        return
    }
    set state [dict get $servers $id]
    if {![dict exists $state clients $chan]} {
        catch {close $chan}
        return
    }

    set data [read $chan]
    if {$data ne ""} {
        set conn [dict get $state clients $chan]
        dict append conn buffer $data
        dict set state clients $chan $conn
        dict set servers $id $state
    }

    set state [dict get $servers $id]
    if {![dict exists $state clients $chan]} {
        catch {close $chan}
        return
    }

    set conn [dict get $state clients $chan]
    set parsed [::attractor_web::__collect_http_request [dict get $conn buffer] [dict get $state max_body_bytes]]
    if {![dict get $parsed ready]} {
        if {[eof $chan] && $data eq ""} {
            dict unset state clients $chan
            dict set servers $id $state
            catch {close $chan}
        }
        return
    }

    if {[dict exists $parsed error]} {
        set code [dict get $parsed error]
        if {$code eq "BODY_TOO_LARGE"} {
            ::attractor_web::__send_json $chan 413 [::attractor_web::__json_error "request body exceeds limit" BODY_TOO_LARGE]
        } else {
            ::attractor_web::__send_json $chan 400 [::attractor_web::__json_error "malformed HTTP request" INVALID_JSON]
        }
        dict unset state clients $chan
        dict set servers $id $state
        catch {close $chan}
        return
    }

    set request [dict get $parsed request]
    dict unset state clients $chan
    dict set servers $id $state

    set keepOpen [::attractor_web::__dispatch_route $id $chan $request]
    if {!$keepOpen} {
        catch {close $chan}
    }
}

proc ::attractor_web::__on_accept {id chan addr port} {
    variable servers
    if {![dict exists $servers $id]} {
        catch {close $chan}
        return
    }

    fconfigure $chan -blocking 0 -buffering none -translation binary -encoding utf-8
    set state [dict get $servers $id]
    dict set state clients $chan [dict create addr $addr port $port buffer ""]
    dict set servers $id $state
    fileevent $chan readable [list ::attractor_web::__on_client_readable $id $chan]
}

proc ::attractor_web::__tick {id} {
    variable servers
    if {![dict exists $servers $id]} {
        return
    }
    set state [dict get $servers $id]

    set runsRoot [dict get $state runs_root]
    set snapshot [::attractor_web::__pipelines_snapshot $runsRoot]
    set snapshotJson [::attractor_web::__pipelines_snapshot_json $runsRoot]

    set ticks [expr {[dict exists $state tick_count] ? [dict get $state tick_count] : 0}]
    incr ticks
    dict set state tick_count $ticks

    foreach chan [dict keys [dict get $state sse_clients]] {
        set client [dict get $state sse_clients $chan]
        set kind [dict get $client kind]
        if {$kind eq "global"} {
            if {![dict exists $client last_payload] || [dict get $client last_payload] ne $snapshotJson} {
                if {[catch {::attractor_web::__send_sse_data $chan $snapshotJson}]} {
                    ::attractor_web::__remove_sse_client $id $chan
                    continue
                }
                dict set state sse_clients $chan last_payload $snapshotJson
            } elseif {($ticks % 20) == 0} {
                if {[catch {::attractor_web::__send_sse_comment $chan "heartbeat"}]} {
                    ::attractor_web::__remove_sse_client $id $chan
                    continue
                }
            }
        } else {
            set runId [dict get $client run_id]
            set runDir [::attractor_web::__run_dir $runsRoot $runId]
            set lines [::attractor_web::__events_lines $runDir]
            set sent [dict get $client sent_count]
            for {set i $sent} {$i < [llength $lines]} {incr i} {
                if {[catch {::attractor_web::__send_sse_data $chan [lindex $lines $i]}]} {
                    ::attractor_web::__remove_sse_client $id $chan
                    continue
                }
            }
            dict set state sse_clients $chan sent_count [llength $lines]
            if {($ticks % 20) == 0} {
                if {[catch {::attractor_web::__send_sse_comment $chan "heartbeat"}]} {
                    ::attractor_web::__remove_sse_client $id $chan
                    continue
                }
            }
        }
    }

    dict set servers $id $state
    set afterId [after 250 [list ::attractor_web::__tick $id]]
    set state [dict get $servers $id]
    dict set state tick_after $afterId
    dict set servers $id $state
}

proc ::attractor_web::server_new {args} {
    variable server_seq
    variable servers

    array set opts {
        -bind 127.0.0.1
        -web_port 7070
        -runs_root .scratch/runs/attractor-web
        -max_body_bytes 2097152
        -max_question_wait_ms 300000
        -dot_bin dot
    }
    array set opts $args

    if {![string is integer -strict $opts(-web_port)] || $opts(-web_port) < 0 || $opts(-web_port) > 65535} {
        return -code error "invalid -web_port: $opts(-web_port)"
    }

    set runsRoot [file normalize $opts(-runs_root)]
    file mkdir $runsRoot

    incr server_seq
    set id $server_seq
    set cmd ::attractor_web::server::$id

    set listener [socket -server [list ::attractor_web::__on_accept $id] -myaddr $opts(-bind) $opts(-web_port)]
    set sock [fconfigure $listener -sockname]
    set actualPort [lindex $sock 2]

    set state [dict create \
        listener $listener \
        bind $opts(-bind) \
        web_port $actualPort \
        runs_root $runsRoot \
        max_body_bytes $opts(-max_body_bytes) \
        max_question_wait_ms $opts(-max_question_wait_ms) \
        dot_bin $opts(-dot_bin) \
        clients {} \
        sse_clients {} \
        workers {} \
        tick_count 0]
    dict set servers $id $state

    set afterId [after 250 [list ::attractor_web::__tick $id]]
    set state [dict get $servers $id]
    dict set state tick_after $afterId
    dict set servers $id $state

    interp alias {} $cmd {} ::attractor_web::__server_dispatch $id
    return $cmd
}

proc ::attractor_web::__server_dispatch {id method args} {
    variable servers
    if {![dict exists $servers $id]} {
        return -code error "unknown server id: $id"
    }
    set state [dict get $servers $id]

    switch -- $method {
        port {
            return [dict get $state web_port]
        }
        url {
            set host [dict get $state bind]
            if {$host eq "0.0.0.0"} {
                set host 127.0.0.1
            }
            return "http://$host:[dict get $state web_port]"
        }
        close {
            catch {after cancel [dict get $state tick_after]}
            foreach chan [dict keys [dict get $state clients]] {
                catch {close $chan}
            }
            foreach chan [dict keys [dict get $state sse_clients]] {
                catch {close $chan}
            }
            foreach chan [dict keys [dict get $state workers]] {
                catch {close $chan}
            }
            catch {close [dict get $state listener]}
            dict unset servers $id
            rename ::attractor_web::server::$id {}
            return {}
        }
        default {
            return -code error "unknown server method: $method"
        }
    }
}

proc ::attractor_web::serve {args} {
    set server [::attractor_web::server_new {*}$args]
    set waitVar ::attractor_web::__serve_wait
    set $waitVar 0
    vwait $waitVar
    return $server
}

package provide attractor_web $::attractor_web::version
