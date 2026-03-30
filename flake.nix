{
  description = "Minimal NixOS VM for AI coding agents (Claude Code + Codex CLI)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko }: let
    system = "aarch64-linux";
  in {
    nixosConfigurations.agent-vm = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko
        ./disk-config.nix
        ./configuration.nix
      ];
    };
  };
}
