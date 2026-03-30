# NixOS Agent VM — Setup Guide

> One script. Declarative everything. ~10 minutes.

---

## Step 1: Download the ISO

Go to **https://nixos.org/download/#nixos-iso**, scroll to **"Minimal ISO image"**,
click **"Download (64-bit ARM)"**.

---

## Step 2: Create the VM in Parallels

1. **File → New** → "Install from image file" → select the ISO
2. It'll say "Unable to detect operating system" — click Continue
3. Select **"Other Linux"** → OK
4. Name it `agent-vm`, check **"Customize settings before installation"**
5. Set: **4 CPUs, 8192 MB RAM (8GB), 32 GB disk**
   *(8GB is needed for the install — you can lower it to 4GB after if you want)*
6. Optionally remove: Sound, Camera, Printer
7. Close settings — VM boots

---

## Step 3: Run the Bootstrap

The VM boots into the NixOS live environment. Then:

```bash
sudo -i

# Option A: If you've pushed the flake to GitHub
nix-env -iA nixos.git
git clone https://github.com/YOUR_USER/nixos-agent-vm.git /tmp/nixos-agent-vm
bash /tmp/nixos-agent-vm/bootstrap.sh

# Option B: One-liner from GitHub (once the repo is set up)
curl -sL https://raw.githubusercontent.com/YOUR_USER/nixos-agent-vm/main/bootstrap.sh | bash
```

The script handles everything:
- Enables flakes
- Runs **disko** to declaratively partition, format, and mount the disk
- Copies your Nix config into place
- Runs `nixos-install`

Walk away for ~5 minutes.

---

## Step 4: Reboot & Finish

1. `reboot`
2. If it boots back into the ISO: shut down → Parallels VM Settings → CD/DVD → Disconnect → start again
3. Log in: `dev` / `changeme`
4. `passwd` (change it)
5. Set up API keys:
   ```bash
   cp /etc/nixos/.secrets.template ~/.secrets
   vim ~/.secrets
   source ~/.secrets
   ```
6. Verify:
   ```bash
   claude --version
   codex --version
   ```

---

## Step 5: SSH In (Recommended)

```bash
# Find the VM's IP (inside the VM)
ip addr show

# From your Mac
ssh dev@10.211.55.x
```

---

## Daily Commands

```bash
rebuild     # apply config changes (alias for nixos-rebuild switch)
update      # update nixpkgs (alias for nix flake update)
```

## Nuke & Redeploy

Delete the VM. Create a new one. Boot the ISO. Run the bootstrap script.
Identical environment in 10 minutes. That's the whole point.

---

## File Structure

```
/etc/nixos/
├── flake.nix           # Entry point + disko input
├── flake.lock          # Pinned versions (auto-generated)
├── configuration.nix   # Packages, services, shell, tools
├── hardware.nix        # Parallels-specific kernel/driver config
├── disk-config.nix     # Declarative disk layout (disko)
└── .secrets.template   # API key template
```
