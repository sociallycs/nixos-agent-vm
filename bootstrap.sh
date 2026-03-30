#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  NixOS Agent VM — One-shot bootstrap                            ║
# ║                                                                  ║
# ║  Boot the NixOS minimal ISO in Parallels, then run:             ║
# ║    curl -sL https://raw.githubusercontent.com/YOU/REPO/main/bootstrap.sh | bash  ║
# ║  Or clone the repo and run:                                     ║
# ║    bash /path/to/bootstrap.sh                                   ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${CYAN}${BOLD}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
fail() { echo -e "${RED}  ✗ $1${NC}"; exit 1; }

# ── Preflight ───────────────────────────────────────────────────────
step "Checking environment"

[[ $EUID -eq 0 ]] || { fail "Run as root: sudo bash bootstrap.sh"; }

# Check we're in the live installer
[[ -f /etc/NIXOS ]] || { fail "This doesn't look like a NixOS live environment"; }

# Check the target disk exists
DISK="/dev/sda"
[[ -b "$DISK" ]] || {
  echo "  /dev/sda not found. Available disks:"
  lsblk -d -o NAME,SIZE,TYPE | grep disk
  fail "Expected /dev/sda — is this a Parallels VM?"
}
ok "Running as root in NixOS live environment"
ok "Target disk: $DISK ($(lsblk -dno SIZE $DISK))"

# ── Enable flakes ──────────────────────────────────────────────────
step "Enabling flakes"
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf
ok "Flakes enabled"

# ── Get the config ─────────────────────────────────────────────────
step "Fetching configuration"

NIXOS_DIR="/mnt/etc/nixos"
WORK_DIR="/tmp/nixos-agent-vm"

# If the repo is already cloned locally (e.g. we're running from it)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/flake.nix" ]]; then
  echo "  Using local config from $SCRIPT_DIR"
  WORK_DIR="$SCRIPT_DIR"
else
  # Try to clone — if git isn't available, install it first
  if ! command -v git &>/dev/null; then
    echo "  Installing git..."
    nix-env -iA nixos.git 2>/dev/null
  fi

  # Ask for repo URL
  echo ""
  echo "  Where is your nixos-agent-vm flake?"
  echo "  Enter a git URL, or press Enter to look in /tmp/nixos-agent-vm"
  read -r -p "  Git URL: " REPO_URL

  if [[ -n "$REPO_URL" ]]; then
    rm -rf "$WORK_DIR"
    git clone "$REPO_URL" "$WORK_DIR"
  elif [[ ! -f "$WORK_DIR/flake.nix" ]]; then
    fail "No flake found at $WORK_DIR and no URL provided"
  fi
fi

ok "Config ready at $WORK_DIR"

# ── Partition & format with disko ──────────────────────────────────
step "Partitioning & formatting disk with disko"
echo "  This will ERASE $DISK completely."
echo ""
read -r -p "  Type 'yes' to continue: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || { fail "Aborted by user"; }

# Run disko to partition, format, and mount
nix run github:nix-community/disko -- \
  --mode disko \
  "$WORK_DIR/disk-config.nix"

ok "Disk partitioned, formatted, and mounted at /mnt"

# Verify mounts
mountpoint -q /mnt      || fail "/mnt is not mounted"
mountpoint -q /mnt/boot || fail "/mnt/boot is not mounted"
ok "Mounts verified"

# ── Copy config to target ─────────────────────────────────────────
step "Installing configuration"
mkdir -p "$NIXOS_DIR"
cp "$WORK_DIR"/flake.nix       "$NIXOS_DIR/"
cp "$WORK_DIR"/configuration.nix "$NIXOS_DIR/"
cp "$WORK_DIR"/hardware.nix    "$NIXOS_DIR/"
cp "$WORK_DIR"/disk-config.nix "$NIXOS_DIR/"
[[ -f "$WORK_DIR/.secrets.template" ]] && cp "$WORK_DIR/.secrets.template" "$NIXOS_DIR/"
ok "Config files copied to $NIXOS_DIR"

# ── Prevent tmpfs from filling up ──────────────────────────────────
# The live ISO runs in RAM. The nix store + downloads will overflow
# the tmpfs if we don't redirect temp files to the mounted disk.
step "Setting up build space on disk (avoids tmpfs overflow)"
mkdir -p /mnt/tmp
export TMPDIR=/mnt/tmp
ok "TMPDIR set to /mnt/tmp"

# ── Install NixOS ─────────────────────────────────────────────────
step "Installing NixOS (this takes a few minutes)"
nixos-install \
  --flake "$NIXOS_DIR#agent-vm" \
  --no-root-passwd \
  --no-channel-copy

ok "NixOS installed!"

# Clean up build artifacts from disk
rm -rf /mnt/tmp

# ── Done ───────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Installation complete!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo "    1. Reboot:  reboot"
echo "    2. Remove the ISO from Parallels (VM Settings → CD/DVD → Disconnect)"
echo "    3. Log in:  dev / changeme"
echo "    4. Change password:  passwd"
echo "    5. Set up API keys:  cp /etc/nixos/.secrets.template ~/.secrets && vim ~/.secrets"
echo ""
echo "  After that:"
echo "    claude --version"
echo "    codex --version"
echo ""
echo "  To rebuild after config changes:"
echo "    rebuild"
echo ""
