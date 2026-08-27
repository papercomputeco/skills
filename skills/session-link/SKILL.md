---
name: session-link
description: >-
  Use when an agent must identify or link the Paper recording of its own
  running session, or link a known session or matched turn — "what's my
  session id", "link to this session", "share this session", "is this being
  recorded", "open this run in the console", "paper session link". Resolves
  the tapes session id with `paperctl sessions` and builds the console URL.
---

# Session Link

## Overview

Every session recorded in Paper has a page in the org console. This skill turns
"this session" — the one the agent is running in right now — into that page's
URL, and does the same for any other session or turn an id is in hand for.
Finding sessions by *topic* is the `search` skill's job; this skill starts from
identity: the running session, or an id someone already has.

## The trap: two ids

Every session record carries two UUID-shaped ids that look interchangeable and
are not:

- **`harness_session_id`** — the harness's own id (e.g. Claude Code's session
  UUID, the value in `CLAUDE_CODE_SESSION_ID`). Useful only as a lookup key.
- **`id`** — the tapes session id: the one `paperctl sessions get`,
  `paperctl skill generate`, and console URLs take.

A console link built from the harness id is a dead link — plausible-looking,
and broken for whoever opens it. The rule that makes this checkable: **a link
is only done when the id inside it was printed by a `paperctl sessions`
command in this run** — never assembled from memory, a transcript, or the
harness's own id.

## Workflow: link the running session

1. **Resolve the tapes id.** Take the first rung of this ladder that applies:
   - **Claude Code**: `CLAUDE_CODE_SESSION_ID` equals the recorded
     `harness_session_id`, so one paired lookup lands the record:
     ```
     paperctl sessions list --harness-session-id "$CLAUDE_CODE_SESSION_ID" \
       --harness-id claude --json
     ```
     The tapes id is `items[0].id`. (The two flags are accepted only as a
     pair — pass both.)
   - **Any other harness** (codex, pi, …): list recent sessions and match the
     agent's own footprint client-side:
     ```
     paperctl sessions list --json --limit 50
     ```
     Keep items where `cwd` equals the current working directory and
     `live == true`; take the newest `last_seen_at`. Narrow further with
     `harness_id` and the agent's own `auth_subject` (`paperctl whoami --json`
     → `user_id`). More than one candidate left: show them (title,
     `started_at`, `harness_id`) and let the user pick. Zero candidates: the
     session is probably not running through paperd — recording happens only
     when the agent is launched via `paperctl start <agent>`. Say that
     instead of guessing.
2. **Verify the id resolves:** `paperctl sessions get <id>` confirms the link
   target exists and prints `Auth subj:` (the owner) — the sanity check before
   handing a link to anyone.
3. **Build the link:**
   ```
   https://console.papercompute.com/sessions/<id>
   ```

## Linking a specific turn

A matched turn in hand carries a `trace_id` (e.g. from `paperctl search --json`
hits). Deep-link that turn by appending it:

```
https://console.papercompute.com/sessions/<session_id>?trace=<trace_id>
```

## Relaying a session that isn't the agent's own

Report alongside the link what `sessions get` showed: the title, `live` (still
running or ended), and the owner (`Auth subj:`), so the recipient knows what
they are opening. Session records also carry `parent_session_id` when the
session was forked from another — fork lineage in one field, empty otherwise.

## "Is this being recorded?"

Same resolution as the workflow above. The record exists with `live: true` —
yes: answer with the link as proof. Nothing matches — the harness is running
bare; a session is captured only when launched through paperd
(`paperctl start <agent>`).

## Quick reference

| Task | Command / URL |
|------|---------------|
| Own tapes id (Claude Code) | `paperctl sessions list --harness-session-id "$CLAUDE_CODE_SESSION_ID" --harness-id claude --json` → `items[0].id` |
| Own tapes id (any harness) | `paperctl sessions list --json --limit 50`, keep `cwd == $PWD && live == true`, newest `last_seen_at` |
| Own `auth_subject` | `paperctl whoami --json` → `user_id` |
| Verify an id + owner | `paperctl sessions get <id>` (shows `Auth subj:`) |
| Session link | `https://console.papercompute.com/sessions/<id>` |
| One turn | append `?trace=<trace_id>` |

## Common mistakes

| Mistake | Do instead |
|---------|-----------|
| Building the URL from `harness_session_id` / `CLAUDE_CODE_SESSION_ID` | Use the record's `id`; the harness id is only the lookup key |
| Passing `--harness-session-id` without `--harness-id` | The flags are accepted only as a pair |
| Assembling a link from a remembered or transcript id | Take the id from a `paperctl sessions` command run now, then `sessions get` it |
| Picking silently among several live candidates | Show them and let the user pick |
| Treating "no session found" as an error to retry | Explain: recording requires launching through paperd (`paperctl start <agent>`) |
| Reaching for this skill to find a session by topic | That is the `search` skill; this one starts from identity |

## Prerequisites

- `paperctl sessions` talks to the org data plane and works even when the local
  daemon is down (active org and gateway configured).
- Commands operate on the active org; override per-invocation with
  `--org-slug <slug>` when the session lives elsewhere.
- The console shows the org chosen at login; the org is not part of the URL.
