---
name: tapes
description: Use when the user says "check the tapes", "search tapes", "tapes search", or wants to look up past agent sessions captured on this machine. Searches sessions semantically through tapesctl, drills into one, and reports what to start when the server is not up. Prefer pull-from-paper when the work was captured through Paper.
---

# Tapes

Look up agent sessions that tapes captured on this machine. Anything routed through the tapes proxy — an agent launched with `tapesctl start`, or any client pointed at the proxy — lands in an immutable raw-turn log, and a derive worker projects it into sessions, traces, and spans. This skill reads that projection back.

## Two binaries, and they are not interchangeable

| | `tapes` | `tapesctl` |
|---|---|---|
| Role | The server. Runs the services, owns the database | The client. Captures sessions and reads them back |
| Owns | `serve`, `local`, `status`, `config`, `auth` | `search`, `sessions`, `export`, `start`, `skill` |
| Install | `curl -fsSL https://download.tapes.dev/install \| bash` | `curl -sSfL https://download.tapes.dev/tapesctl/install \| bash` |

**Every command in this skill that reads data is `tapesctl`.** There is no `tapes search` — that is the single most common way to get this wrong, and it fails with `unknown command "search" for "tapes"`. A machine can easily have one binary and not the other.

## This is not the pull-from-paper skill

| | this skill | `pull-from-paper` |
|---|---|---|
| Store | The Postgres the local tapes server owns | Org session store behind the gateway |
| Binary | `tapesctl` | `paperctl` |
| Scope | Whatever this machine captured | The whole org, everyone in it |

If the user says "check the tapes" or points at a local server, use this skill. If they mention their org, a teammate, paperd, a gateway, or `paper start`, use that one.

## Preflight

```
tapes status
```

The output names the config dir, the provider, the storage, the `API target:` the client will use, and whether the API is reachable. `curl -sf http://localhost:8081/ping` is the bare equivalent — the health route is `/ping`, not `/health`.

Two failures matter:

- **`tapesctl` not installed.** `tapes status` says nothing about this, because it is the server's command. Confirm separately with `tapesctl version`.
- **API unreachable.** The server is not running. See below.

## Starting the server is the user's call

Bringing tapes up starts Docker containers, which is too much to do to a machine unprompted. Report what is needed rather than running it:

```
tapes local up   # Postgres + Ollama in Docker, once per machine
tapes serve      # proxy :8080, read API :8081, ingest :8082, derive + embed workers
```

If the user asks you to start it, `tapes serve` is a long-running process — run it with the Bash tool's `run_in_background` so it does not block the conversation. `tapes local up` returns on its own and can run in the foreground.

## Searching

```
tapesctl search "<query>" --top 5 --tapes-url http://localhost:8081
```

`--tapes-url` can be dropped once the user has run `tapesctl config set tapes-url http://localhost:8081`; passing it is safe either way.

- `-k`, `--top <N>` defaults to 5. Raise it for broad questions, lower it for narrow ones.
- `-q`, `--quiet` prints one bare session id per line, deduplicated in score order.

Phrase the query as the idea, not an exact string — this is semantic search over embedded spans, not grep.

**Each hit is a span, not a session.** A span is one main-conversation LLM call, carrying its session id, trace id, similarity score, model, timestamp, and a text snippet. Use the snippet to judge relevance and the session id to drill in.

Quiet output is a pipe format rather than a verbosity setting: it is the shape skill generation takes as positionals, so the two compose:

```
tapesctl skill generate $(tapesctl search "Charm CLI" --quiet --top 1) --name charm-patterns
```

## Drilling into a session

```
tapesctl sessions list                # --limit, --cursor, --sort, --direction, --since, --until
tapesctl sessions get <ID>
tapesctl sessions traces <ID>         # --payload for the message content
```

Read commands print the server's JSON pretty-printed and nothing else, so fields the server grows reach you without a client upgrade.

For the full transcript:

```
tapesctl export <ID> -o bundle.jsonl --detail traces
```

JSONL, one line per trace. `--detail` defaults to `spans`. Transcripts get large — write to a file and read only the parts you need rather than piping it all into the conversation.

## Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| `tapes search ...` | `unknown command "search" for "tapes"` | Search is on the client: `tapesctl search` |
| `tapes serve api --sqlite ~/.tapes/tapes.sqlite` | `unknown flag: --sqlite` | Storage is Postgres. `tapes local up` then `tapes serve` |
| Treating `~/.tapes/` as the store | It is the **config** directory | The data is in Postgres; `tapes status` names the storage |
| `curl .../health` | 404 | The health route is `/ping` |
| Expecting search to return sessions | Hits are spans | Take `session_id` from a hit, then `sessions get` |
| Starting Docker unprompted | Containers on a machine that did not ask | Report `tapes local up` and let the user run it |

## Workflow

1. `tapes status` to confirm the API is reachable, and `tapesctl version` to confirm the client exists. Resolve either before searching.
2. Search if the user described content; list if they described a time or a harness.
3. `sessions get` on the best hit for the summary. Export only when they want the actual back-and-forth.
4. Answer the question directly, then cite the session id so they can read it back themselves.

## When nothing comes back

An empty result set is not an error: `tapesctl search` prints `No results found.` and exits 0, and quiet output prints nothing and exits 0. Walk the chain in order — each step depends on the one before:

1. Sessions exist at all: `tapesctl sessions list`.
2. A session has derived spans: `tapesctl sessions traces <ID>`.
3. The embedding service is running; for Ollama, `curl http://localhost:11434/api/tags`.
4. `embedding.model` and `embedding.dimensions` match the pgvector table.

A configured but uninitialized search surface returns HTTP `503`, and the response body names the cause. If sessions exist but nothing matches, rephrase the query as the problem being solved rather than the words used.
