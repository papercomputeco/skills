# Paper Compute Co. skills

Our curated AI agent skills.

Use them in your project's flake with [`flake-skills`](https://github.com/papercomputeco/flake-skills):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    paper-skills.url = "github:papercomputeco/skills";
    paper-skills.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, paper-skills }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};
      skills = paper-skills.lib;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        shellHook = skills.mkSkillsHook {
          skills = [ "dagger-check" ];
        };
      };
    };
}
```

Enter the dev shell `nix develop` for skills to automatically propagate.

Or install directly with the [skills CLI](https://skills.sh):

```bash
npx skills add papercomputeco/skills
```

---


| Skill | Description |
|--------|-------------|
| [`confluent-cloud-setup`](./skills/confluent-cloud-setup) | Set up Confluent Cloud clusters, topics, and API keys for any project |
| [`dagger-check`](./skills/dagger-check) | Tell the agent how to run `dagger check` |
| [`pull-from-paper`](./skills/pull-from-paper) | Look up paperd-captured org sessions, yours or a teammate's, via `paperctl` |
| [`tapes`](./skills/tapes) | Search and query past agent sessions captured locally by tapes, through `tapesctl` |
| [`recall`](./skills/recall) | Before starting work, find the closest prior sessions and turn them into a playbook for the task at hand |
| [`search`](./skills/search) | Semantic search over recorded sessions across the whole org — all authors, all harnesses — plus time/author browsing |
| [`digest`](./skills/digest) | Summarize org activity for today, the past 7 days, or the past 30 days from session rollups |
| [`generate-skill`](./skills/generate-skill) | Turn recorded sessions into a reusable org skill via `paperctl skill generate`, then install it locally |
| [`session-link`](./skills/session-link) | Identify the agent's own recorded session and return its console link |

## Requirements for the Paper session skills

`recall`, `search`, `digest`, `generate-skill`, and `session-link` need
[`paperctl`](https://docs.papercompute.com) installed with the `paperd` daemon
running (`paperctl init`, `paperctl login`; check `paperctl status`), and an
active org whose tapes backend has recorded sessions — agents launched through
`paperctl start claude|codex|pi` are captured automatically.

## Agent-specific installation

<details>
<summary>Claude Code</summary>

```bash
/plugin marketplace add papercomputeco/skills
/plugin install paper
```

</details>

<details>
<summary>Codex (OpenAI)</summary>

```bash
git clone https://github.com/papercomputeco/skills.git ~/.agents/skills/paper
```

Codex auto-discovers skills from `~/.agents/skills/` and `.agents/skills/`.

</details>

<details>
<summary>Cursor</summary>

```bash
git clone https://github.com/papercomputeco/skills.git ~/.cursor/skills/paper
```

Cursor auto-discovers skills from `.agents/skills/` and `.cursor/skills/`.

</details>

<details>
<summary>Copilot</summary>

```bash
git clone https://github.com/papercomputeco/skills.git ~/.copilot/skills/paper
```

Copilot auto-discovers skills from `.copilot/skills/`.

</details>

<details>
<summary>Gemini CLI</summary>

```bash
gemini extensions install https://github.com/papercomputeco/skills
```

</details>

<details>
<summary>OpenCode</summary>

```bash
git clone https://github.com/papercomputeco/skills.git ~/.agents/skills/paper
```

OpenCode auto-discovers skills from `.agents/skills/`, `.opencode/skills/`,
and `.claude/skills/`.

</details>

Org skills generated with `paperctl skill generate` install the same way:
`paperctl skill sync <slug>` writes them into these discovery directories.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for skill-authoring conventions.
