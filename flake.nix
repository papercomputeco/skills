{
  description = "Paper Compute Co. agent skills";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-skills.url = "github:papercomputeco/flake-skills";
  };

  outputs = { self, nixpkgs, flake-skills }:
    flake-skills.lib.mkSkillsFlake {
      inherit nixpkgs;
      skillsSrc = ./skills;
    };
}
