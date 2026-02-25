# Paper Compute Co. skills

Our curated AI agent skills.

Use them in your project's flake with [`flake-skills`](https://github.com/papercomputeco/flake-skills):

```nix
devShells.default = pkgs.mkShell {
  shellHook = skills.mkSkillsHook {
    skills = [ "dagger-check" ];
  };
};
```

---


| Skill | Description |
|--------|-------------|
| [`dagger-check`](./skills/dagger-check) | Tell the agent how to run `dagger check` |
