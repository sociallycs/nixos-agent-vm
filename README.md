# nixos-agent-vm

Minimal, declarative NixOS environment for AI coding agents on Parallels (Apple Silicon).

**What's inside:** Claude Code, Codex CLI, zsh + oh-my-zsh, modern CLI stack (eza, bat, ripgrep, fd, fzf, jq, tmux), Docker. No GUI. ~400MB idle.

**What's declarative:** Everything. Disk layout (disko), packages, services, shell config. One flake, one command to rebuild, one script to deploy from scratch.

## Quick Start

1. Download [NixOS Minimal ISO (64-bit ARM)](https://nixos.org/download/#nixos-iso)
2. Create a Parallels VM (Other Linux, 4 CPU, 8GB RAM, 32GB disk)
3. Boot the ISO, then:

```bash
sudo -i
nix-env -iA nixos.git
git clone https://github.com/YOUR_USER/nixos-agent-vm.git /tmp/nixos-agent-vm
bash /tmp/nixos-agent-vm/bootstrap.sh
```

4. Reboot, log in as `dev/changeme`, set up API keys in `~/.secrets`

See [SETUP-GUIDE.md](SETUP-GUIDE.md) for the full walkthrough.
