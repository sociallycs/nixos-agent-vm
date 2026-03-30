{ config, pkgs, lib, ... }:

{
  # ╔══════════════════════════════════════════════════════════════════╗
  # ║  NixOS Agent VM — Minimal AI Coding Environment                ║
  # ║  One config. Both tools. Blow away and rebuild in seconds.     ║
  # ╚══════════════════════════════════════════════════════════════════╝

  imports = [
    ./hardware.nix
  ];

  system.stateVersion = "25.05";

  # ── Boot ──────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Allow unfree packages (required for Parallels Tools) ──────────
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "prl-tools"
    ];

  # ── Networking ────────────────────────────────────────────────────
  networking = {
    hostName = "agent-vm";
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # ── Locale & Time ────────────────────────────────────────────────
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Users ─────────────────────────────────────────────────────────
  users.users.dev = {
    isNormalUser = true;
    home = "/home/dev";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    initialPassword = "changeme";
  };

  # Passwordless sudo for dev user
  security.sudo.extraRules = [{
    users = [ "dev" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  # ── SSH ───────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;  # Flip to false after adding keys
      PermitRootLogin = "no";
    };
  };
  # Uncomment and add your public key:
  # users.users.dev.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAA... you@mac"
  # ];

  # ── Zsh ───────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "z" "fzf" "docker" ];
    };
    shellAliases = {
      ll = "eza -la --icons";
      lt = "eza -la --tree --level=2 --icons";
      gs = "git status";
      gd = "git diff";
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#agent-vm";
      update = "nix flake update --flake /etc/nixos";
    };
    interactiveShellInit = ''
      export EDITOR=vim

      # Source API keys from a gitignored secrets file
      [[ -f ~/.secrets ]] && source ~/.secrets
    '';
  };

  # ── Core Dev Tools ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # essentials
    git
    curl
    wget
    vim
    tmux

    # modern CLI replacements
    eza           # ls replacement
    bat           # cat replacement
    ripgrep       # grep replacement
    fd            # find replacement
    fzf           # fuzzy finder
    jq            # JSON wrangler
    yq            # YAML wrangler
    htop          # process viewer
    tree

    # node ecosystem (for claude-code + codex)
    nodejs_22
    corepack      # enables pnpm/yarn without global install

    # python (some tools / scripts may need it)
    python3
    python3Packages.pip

    # nix tooling
    nil           # nix LSP
    nixfmt-rfc-style  # nix formatter
    nix-tree      # explore nix store

    # networking / debug
    dig
    traceroute
    file
    unzip
  ];

  # ── Node.js Global Packages (Claude Code + Codex CLI) ────────────
  system.activationScripts.installNodeTools = lib.stringAfter [ "users" ] ''
    export HOME=/home/dev
    export NPM_CONFIG_PREFIX=/home/dev/.npm-global
    mkdir -p $NPM_CONFIG_PREFIX
    export PATH=$NPM_CONFIG_PREFIX/bin:${pkgs.nodejs_22}/bin:$PATH

    # Install Claude Code if not present
    if ! [ -x "$NPM_CONFIG_PREFIX/bin/claude" ]; then
      ${pkgs.nodejs_22}/bin/npm install -g @anthropic-ai/claude-code 2>/dev/null || true
    fi

    # Install Codex CLI if not present
    if ! [ -x "$NPM_CONFIG_PREFIX/bin/codex" ]; then
      ${pkgs.nodejs_22}/bin/npm install -g @openai/codex 2>/dev/null || true
    fi

    chown -R dev:users $NPM_CONFIG_PREFIX
  '';

  environment.variables = {
    NPM_CONFIG_PREFIX = "/home/dev/.npm-global";
  };
  environment.sessionVariables = {
    PATH = [ "/home/dev/.npm-global/bin" ];
  };

  # ── Docker (optional, useful for agent sandboxing) ────────────────
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # ── Nix Settings ──────────────────────────────────────────────────
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [ "https://cache.nixos.org" ];
      trusted-users = [ "root" "dev" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # ── Disable bloat ────────────────────────────────────────────────
  services.xserver.enable = false;
  services.pulseaudio.enable = false;
  services.printing.enable = false;
  documentation.nixos.enable = false;
}
