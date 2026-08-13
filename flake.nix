{
  description = "Paper Compute Co. agent skills";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-skills.url = "github:papercomputeco/flake-skills";
    dagger.url = "github:dagger/nix";
    dagger.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-skills, dagger }:
    let
      skillsFlake = flake-skills.lib.mkSkillsFlake {
        inherit nixpkgs;
        skillsSrc = ./skills;
      };
    in
    skillsFlake // {
      devShells = nixpkgs.lib.mapAttrs (system: shells: shells // {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          name = "skills-dev";
          buildInputs = [
            dagger.packages.${system}.dagger
          ];
          shellHook = skillsFlake.lib.mkSkillsHook {
            skills = skillsFlake.skillNames;
          };
        };
      }) skillsFlake.devShells;
    };
}
