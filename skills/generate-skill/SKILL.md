---
name: generate-skill
description: >-
  Use when someone wants to turn recorded Paper sessions into a reusable org
  skill, or install one from the org registry — "make a skill from this
  session", "turn that workflow into a skill", "generate a skill from the
  session where…", "save this as a skill", "sync the org skill". Covers
  `paperctl skill generate` (server-side generation from recorded sessions)
  and `paperctl skill sync` (local install).
---

# Generate Skill

## Overview

`paperctl skill generate` turns one or more recorded sessions into a reusable
org skill. Generation runs **server-side** in the org's tapes backend
(LLM-backed): the command sends session ids, the server reads the transcripts,
writes the skill, and publishes it to the org skill registry. `paperctl skill
sync` then installs any registry skill into a local skills directory.

This skill wraps the server-side generator; writing or editing a SKILL.md by
hand is ordinary file editing and takes none of it.

## The gate: generation publishes to the org

`skill generate` creates an org-visible skill and runs a server-side LLM over
the source transcripts. The go-ahead is therefore a hard workflow step: tell
the user exactly what will be generated — source session ids with titles, the
name (pinned or generator-chosen), the type — and proceed on an explicit yes
to that exact set. A yes to a different set of ids re-opens the step.

## Workflow

1. **Pick the source sessions.** Three entry paths:
   - *"This session"* — resolve the running session's paper id.
     - Claude Code (flags accepted only as a pair):
       ```
       paperctl sessions list --harness-session-id "$CLAUDE_CODE_SESSION_ID" --harness-id claude --json
       ```
       `items[0].id` is the paper session id.
     - Any other harness: `paperctl sessions list --json --limit 50`; keep items
       with `cwd` equal to the working directory and `live` true, newest
       `last_seen_at` first; disambiguate with `harness_id` / `auth_subject`
       (own id from `paperctl whoami`). More than one left → show them, let the user pick.
       (The `session-link` skill covers this resolution in depth.)
   - *A described past session* — `paperctl search "<what happened>" --json`
     and/or `paperctl sessions list`; every hit carries a `session_id`.
   - *Explicit ids* — use them as given.

   Whatever the path, run `paperctl sessions get <id>` on each chosen id and
   show the user its title, so the wrong session never becomes a skill. The
   step is done when the user recognizes every id.

2. **Gate — get the go-ahead.** State ids (with titles), name, and type; the
   user's explicit yes to that exact set completes this step (see the gate above).

3. **Generate.**
   ```
   paperctl skill generate <SESSION_ID>... [--name <n>] [--type <t>] [--json]
   ```
   All listed sessions feed one skill. Omit `--name` to let the generator name
   it from the transcripts. Pick `--type` by what the sessions contain: a
   repeatable procedure → `workflow` (the default); facts or conventions →
   `domain-knowledge`; a reusable prompt → `prompt-template`.

4. **Verify and hand over.**
   ```
   paperctl skill list --query <name-or-slug> --json
   ```
   The record carries camelCase fields — `id`, `slug`, `version`, … Give the
   user the console link built from the **id** (the route key; the slug is a
   display label): `https://console.papercompute.com/skills/<skill-id>`

5. **Install locally — on request.** `paperctl skill sync <slug-or-id>` writes
   the skill's rendered SKILL.md to a local skills directory. Slug matches
   exactly; id matches by prefix. Run `--dry-run` first and show the resolved
   target, then sync for real.

   | Flags | Target |
   |-------|--------|
   | none | `~/.agents/skills` |
   | `--claude` | `~/.claude/skills` |
   | `--local` | `./.agents/skills` |
   | `--claude --local` | `./.claude/skills` |

   Match the target to the harness in use: Claude Code → `--claude`; a
   repo-local install → add `--local`.

**Done when:** the skill appears in `paperctl skill list` output and the user
has its console link — plus the synced target path when an install was requested.

## Degraded mode: skills endpoint not deployed

`HTTP 404 from https://<org>.papercompute.run/default/tapes/v1/…` on a `skill`
command means the org's tapes deployment doesn't serve skills yet. Report that
and stop; `paperctl doctor` repairs local setup and cannot fix a server-side gap.

## Quick reference

| Task | Command |
|------|---------|
| Current session id (Claude Code) | `paperctl sessions list --harness-session-id "$CLAUDE_CODE_SESSION_ID" --harness-id claude --json` → `items[0].id` |
| Current session id (any harness) | `paperctl sessions list --json --limit 50` → keep `cwd == $PWD` and `live == true` |
| Find a described session | `paperctl search "<what happened>" --json` |
| Confirm a source id | `paperctl sessions get <session_id>` |
| Generate | `paperctl skill generate <SESSION_ID>... [--name <n>] [--type workflow\|domain-knowledge\|prompt-template] [--json]` |
| Verify the record | `paperctl skill list --query <name-or-slug> --json` |
| Console link | `https://console.papercompute.com/skills/<skill-id>` |
| Preview sync target | `paperctl skill sync <slug-or-id> --dry-run` |
| Install | `paperctl skill sync <slug-or-id> [--claude] [--local]` |

## Common mistakes

| Mistake | Do instead |
|---------|-----------|
| Running `skill generate` before the user's yes | State ids + titles + name + type first; the explicit yes is the gate |
| Feeding `harness_session_id` (or a harness env var) to `skill generate` | Generate from the tapes id (`items[].id` / the `id` from `sessions get`) |
| Building the console link from the slug | Build it from the skill `id`: `…/skills/<skill-id>` |
| Hand-authoring a SKILL.md through this skill | That is ordinary file editing; this skill wraps the server-side generator |
| Retrying or `doctor`-ing an HTTP 404 from the skills endpoint | The deployment doesn't serve skills yet — report and stop |
| Syncing to the default target for a Claude Code install | Add `--claude`; `--dry-run` shows the resolved target first |

## Prerequisites

- An active org login (`paperctl status`; repair with `paperctl doctor`). Scope
  one invocation to another org with `--org-slug <slug>`.
- A "this session" ask resolves only for a harness launched through paperd
  (`paperctl start claude|codex|pi`); a harness launched bare has no recording.
- `paperctl search` needs the local daemon (paperd) running; `paperctl sessions`
  talks to the org data plane and works even when the daemon is down.
