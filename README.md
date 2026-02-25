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

---


| Skill | Description |
|--------|-------------|
| [`dagger-check`](./skills/dagger-check) | Tell the agent how to run `dagger check` |
