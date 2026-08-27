---
name: digest
description: >-
  Use when someone wants an update on recorded Paper agent activity in their
  org — "what happened in the org today", "give me a digest", "weekly update",
  "what has the team been working on", "activity summary". Builds a digest for
  today, the past 7 days, or the past 30 days from `paperctl sessions list`
  rollups.
---

# Digest

## Overview

A digest tells the user what has been going on in their Paper org: the recorded
agent sessions of today, the past 7 days, or the past 30 days — who ran what,
where, on which harness, at what cost, and which sessions stand out.

**A digest reads the covers, not the books.** Build it from the session rollups
that `paperctl sessions list --json` returns — every number the report needs
(status, cost, tokens, turns, models) is already on each list item. That keeps
the digest fast and leaves teammates' transcripts unread. Drilling into what one
session contains is the `search` / `recall` skills' territory.

## Workflow

1. **Resolve the window.** Map the ask to `--since` in RFC3339 UTC: today
   (current UTC date at `00:00:00Z`), 7 days (the default when unspecified), or
   30 days. For asks beyond 30 days, offer the 30-day digest — the platform's
   bulk horizon. Portable timestamp:
   ```
   python3 -c "from datetime import datetime,timedelta,timezone; \
   print((datetime.now(timezone.utc)-timedelta(days=7)).strftime('%Y-%m-%dT%H:%M:%SZ'))"
   ```
2. **Collect every page.**
   ```
   paperctl sessions list --since <t> --limit 200 --sort last_active --direction desc --json
   ```
   Each response is `{items, next_cursor}`. While `next_cursor` is non-empty,
   rerun with `--cursor <next_cursor>` and keep every page. The digest covers
   the window only when the final page returns an empty `next_cursor` — count
   pages and items, and state both totals in the report.
3. **Aggregate across all items.** The axes and the fields that feed them:

   | Axis | Field |
   |------|-------|
   | Total / live now | item count; `live == true` |
   | Authors | distinct `auth_subject` |
   | Harness | `harness_id` |
   | Status | `rollup.status`: `completed` / `failed` / `unknown` |
   | Project | `cwd` basename |
   | Spend / tokens | sum `rollup.usage.cost_usd`, `.input_tokens`, `.output_tokens` |
   | Turn volume | sum `rollup.turn_count` |
   | Models | `rollup.model_usage[].model` |

   Starter over saved pages — extend the same way for the other axes:
   ```
   jq -s '{sessions:(map(.items|length)|add),
     live:([.[].items[]|select(.live)]|length),
     cost:([.[].items[].rollup.usage.cost_usd]|add)}' page*.json
   ```
   Name the authors: your own `auth_subject` is `user_id` from
   `paperctl whoami --json`; for teammates derive a name from the `cwd` username
   (`/Users/<name>/…`) and label it a heuristic — there is no roster command.
4. **Pick highlights.** The top 3–5 sessions by `rollup.usage.cost_usd` or
   `rollup.turn_count`, every `failed` session, and notable `live` ones. Show
   each as its `display_title` (or `name`) linked to
   `https://console.papercompute.com/sessions/<id>`, where `<id>` is the item's
   `id` field. Highlights are done when every one carries its console link.
5. **Render the report**, scaled to the window — a today digest is the headline
   lines plus highlights; a 30-day digest earns the full template:
   ```
   ## Paper digest — past 7 days (2026-08-20 → 2026-08-27 UTC)
   **23 sessions** · 5 authors · 3 live now · $412 · 61M in / 1.2M out tokens · 480 turns
   Harness: claude 17 · codex 4 · pi 2   Status: 19 completed · 2 failed · 2 unknown
   Models: claude-fable-5, claude-opus-5

   **By project**
   - checkout-api — 11 sessions, $290 — ana, sam*
   - console-ui — 7 sessions, $84 — kai*

   **Highlights** (top by cost; titles show how each session opened)
   - [Fix flaky auth integration test](https://console.papercompute.com/sessions/<id>) — $142, 96 turns, sam*
   **Failed:** [<title>](<link>) — status `failed`, 3 turns
   **Live now:** [<title>](<link>) — 41 turns so far

   * names from the cwd-username heuristic
   ```

## Honesty rules

- `display_title` / `name` reflect how a session **opened**, not what it did.
  Present them as labels and describe activity as "worked on X" — a rollup
  digest carries no outcomes, so claims like "shipped X" stay out.
- A window with zero sessions: report zero plainly and offer a wider window.

## Quick reference

| Task | Command |
|------|---------|
| First page | `paperctl sessions list --since <RFC3339> --limit 200 --sort last_active --direction desc --json` |
| Next page | same command + `--cursor <next_cursor>` |
| Own identity | `paperctl whoami --json` — `user_id` is your `auth_subject` |
| Session link | `https://console.papercompute.com/sessions/<id>` (the item's `id`) |
| Another org | add `--org-slug <slug>` to any command |

## Common mistakes

| Mistake | Do instead |
|---------|-----------|
| Reaching for `sessions export` or `paperctl search` to enrich the digest | Rollups only — every digest number is already on the list items |
| Stopping after the first page | Follow `next_cursor` until it comes back empty; state pages and items collected |
| Linking `harness_session_id` | Console URLs take the tapes `id` field |
| Reporting titles as outcomes ("shipped the migration") | Titles are opening labels — say "worked on" and link the session |
| Presenting cwd-derived author names as fact | Label them a heuristic; only your own id is confirmed via `whoami` |
| Padding an empty window with older sessions | Report zero and offer a wider window |
| Building a digest past 30 days | Offer the 30-day digest — the platform's bulk horizon |

## Prerequisites

- `paperctl sessions list` talks to the org data plane and works even when the
  local daemon is down. Check auth and org with `paperctl status`.
- The digest covers the active org; scope one run to another org with
  `--org-slug <slug>`.
- Only harnesses launched through paperd (`paperctl start …`) are recorded — the
  digest reports recorded activity, and uncaptured runs stay invisible to it.
