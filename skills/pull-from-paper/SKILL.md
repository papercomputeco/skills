---
name: pull-from-paper
description: Use when the user says "pull from paper", "pull up that session", or wants to look through sessions captured by paperd for their Paper org, their own or a teammate's. Covers past agent runs, what a run cost, turn counts, who ran what, and transcripts of earlier work, queried through paperctl. Applies whenever the user names a teammate whose sessions they want, or mentions paperd, a gateway, their org, or paper start. Prefer this over the tapes skill when the work was captured through Paper.
---

# Pull from paper

Look up sessions that paperd captured for the active Paper org. Every agent run launched through `paper start` proxies through paperd, and the gateway records it as a session with turns, token counts, cost, and the identity of whoever ran it. The store is org-wide: your sessions and your teammates' sessions live in the same place and every command here can see both.

## This is not the tapes skill

| | `tapes` skill | this skill |
|---|---|---|
| Store | Local SQLite at `~/.tapes/` | Org session store behind the gateway |
| Binary | `tapes` | `paperctl` |
| Scope | Whatever the local recorder captured | The whole org, everyone in it |

If the user mentions their org, a teammate, paperd, a gateway, or `paper start`, use this skill. If they say "check the tapes" or point at `~/.tapes`, use that one.

## Preflight

```
paperctl status
```

Healthy output names a running pid, `auth: healthy`, an org slug, and a gateway. Two failures matter:

- **Auth expired or missing.** Tokens are short-lived, so this is the common one. `paperctl login` runs an interactive device flow, so never run it in the background. Ask the user to run `! paperctl login` in the prompt, then continue.
- **paperd not running.** `paperctl doctor` checks and repairs the daemon, login, org, and route.

## Whose sessions: resolving a person to an auth subject

Sessions are attributed by `auth_subject`, a WorkOS id like `user_01ABC...`. There is no member roster command, and `--auth-subject` with an email **silently returns zero rows** instead of erroring. Never guess an id and never attribute sessions to a person based on their content.

**Your own id** comes from `paperctl whoami` (the `user_id` line).

**A teammate's id** comes from the session data itself. Each JSON row carries the `cwd` the agent ran in, and the home directory in that path names the person:

```
paperctl sessions list --limit 200 --json \
  | jq -r '.items[] | [.auth_subject, .cwd] | @tsv' \
  | awk -F'\t' '{split($2,p,"/"); print $1"\t"p[3]}' | sort -u
```

Output pairs each `user_...` id with a username like `bekahhw` or `jpmcb`. Pick the teammate's id, then scope any command with `--auth-subject <id>`. If the person has no recent sessions, widen the window with `--since` or page back with `--cursor`. Rows whose cwd is not a home path (`tmp`, blank) are ambiguous; ignore them if the same id also appears with a real username.

## Finding sessions

**They described content:** semantic search. It matches by meaning across the whole org, teammates included:

```
paperctl search "<query>" -k 8
```

Phrase the query as the idea, not an exact string. Each hit carries a `session_id` to drill into. `-k` raises or lowers the result count, `--json` for parsing.

**They described a person, time, cost, or size:** list.

```
paperctl sessions list --limit 20 --auth-subject <id>
```

- `--sort`: `last_active` | `started_at` | `turn_count` | `total_cost_usd` | `total_tokens` | `duration_ns` | `derived_status` | `auth_subject`
- `--direction asc|desc`, `--limit` (max 200), `--cursor <token>` from a prior response
- `--json` adds fields the table hides: `auth_subject`, `cwd`, `live`, and a `rollup` with status, preview, and per-model usage

JSON rows nest the numbers. The paths that matter when scripting totals:

```
.items[] | .id, .display_title, .auth_subject, .cwd,
           .rollup.turn_count, .rollup.usage.cost_usd, .rollup.status
```

There is no top-level `total_cost_usd` or `turn_count` on a row; those names are sort keys only.

## Time windows need RFC3339

`--since 24h` fails with HTTP 400. Compute a real timestamp:

```
/bin/date -u -v-7d +%Y-%m-%dT%H:%M:%SZ           # macOS
date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ      # GNU coreutils
```

Use `/bin/date` explicitly on macOS. A nix or Homebrew coreutils earlier in PATH shadows the system `date` and disagrees on the relative-time flag. `--until` takes the same format.

## Drilling into one session

```
paperctl sessions get <id>
```

Returns name, model, status, turn count, cost, token totals, start and last-active times, the auth subject who ran it, and a per-model usage breakdown. This answers most "what happened in that run" questions without the transcript.

For the actual content:

```
paperctl sessions export <id> --out /tmp/session.ndjson
```

Export requires a scope: one session id, a `--since`/`--until` window, or `--all` (server clamps to 30 days). `--detail traces` for span granularity instead of the per-turn default. Transcripts get large, so write to a file and read only the parts you need.

## Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| `--auth-subject` with an email | Zero rows, no error | Ids are WorkOS `user_...`. Map via the cwd recipe above |
| Guessing who ran a session from its content | Wrong attribution | Map `auth_subject` to a person via `cwd`, then filter |
| `--since 24h` or `--since 7d` | HTTP 400 | RFC3339 timestamp from `/bin/date` |
| Bare `date` on macOS | Flag coin flip vs coreutils | `/bin/date` for BSD, or spell out GNU syntax |
| Expecting a run started outside `paper start` | Never captured, never found | Only proxied runs appear, no matter the query |

## Workflow

1. `paperctl status`, resolve auth or daemon problems first.
2. If the question names a person, resolve them to an `auth_subject` id before anything else.
3. Search if they described content, list if they described a person, time, or cost.
4. `sessions get` on the match for the summary. Export only when they want the actual back-and-forth.
5. Answer the question directly, then give the session name, when it ran, cost, and turn count. Include the session id so they can go deeper.

## When nothing comes back

- Search matches meaning. Rephrase as the problem being solved rather than the words used.
- The session may live in another org. `paperctl org` lists them; `--org-slug <slug>` scopes one command without switching.
- The person may not be in the most recent page. Widen `--since` or follow `--cursor`.
