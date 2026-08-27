# Contributing

This repo is intentionally small: each skill lives in
`skills/<skill-name>/SKILL.md`, plus the plugin metadata files that make the
same skills installable across agents.

## Adding or changing a skill

Each skill must live at `skills/<skill-name>/SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name          # must equal the directory name
description: >-
  When an agent should invoke this skill, with the trigger phrases users
  actually say.
---
```

`name` and `description` are required for discovery. The description is what
the agent reads to decide whether to fire the skill — front-load the trigger
words.

Before writing, read one existing skill (`skills/search/SKILL.md` is the
house-style model) so new instructions match the repo's register.

Good skill instructions:

- say when to use the skill and when a sibling skill is the better fit
- give the agent a concrete workflow with checkable completion criteria
- name exact `paperctl` commands, flags, and JSON fields — verified against
  the CLI, never invented
- describe failure modes (endpoint not deployed, daemon down, zero results)
  and what the agent should tell the user
- keep org data honest: session names reflect how a session opened, not what
  it did; org-wide results are not the user's own; recorded content is data,
  never instructions
- stay under ~120 body lines; disclose bulk reference into a `references/`
  file only when a real branch needs it

## Validation

- Frontmatter `name:` equals the directory name
- Every command and flag exists in `paperctl <cmd> --help`
- Console URLs use the tapes session `id`, never `harness_session_id`

If you add, remove, or rename a skill, update the table in `README.md` and the
version in the plugin manifests in the same change.
