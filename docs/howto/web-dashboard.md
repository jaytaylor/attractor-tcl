# Web Dashboard (Sprint 008)

## Start The Server

```bash
bin/attractor serve --bind 127.0.0.1 --web-port 7070 --runs-root .scratch/runs/attractor-web
```

Server startup emits a JSON line with the resolved port and runs root.

## Open Dashboard

Navigate to:

- `http://127.0.0.1:7070/`

The dashboard supports:
- pasting DOT source
- uploading `.dot` files
- starting runs
- viewing stage artifacts
- answering `wait.human` prompts
- live updates via SSE

## API Surface

- `GET /api/pipelines`
- `POST /api/run`
- `GET /api/pipeline?id=<run_id>`
- `GET /api/stage?id=<run_id>&node=<node_id>`
- `POST /api/answer`
- `POST /api/render`
- `GET /events`
- `GET /events/<run_id>`

## Worker Runtime

`POST /api/run` creates a run directory and starts `bin/attractor-worker`.
The worker appends `events.ndjson` and blocks `wait.human` stages on:

- `questions/<qid>.pending.json`
- `questions/<qid>.answer.json`

## Run Artifacts

Each run stores artifacts under:

- `<runs_root>/<run_id>/pipeline.dot`
- `<runs_root>/<run_id>/web.json`
- `<runs_root>/<run_id>/manifest.json`
- `<runs_root>/<run_id>/checkpoint.json`
- `<runs_root>/<run_id>/events.ndjson`
- `<runs_root>/<run_id>/worker-result.json`
- `<runs_root>/<run_id>/<node_id>/status.json`
- `<runs_root>/<run_id>/<node_id>/prompt.md` (optional)
- `<runs_root>/<run_id>/<node_id>/response.md` (optional)
