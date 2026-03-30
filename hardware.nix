{ config, pkgs, lib, ... }:

{
  # ╔══════════════════════════════════════════════════════════════════╗
  # ║  Hardware config for Parallels Desktop on Apple Silicon         ║
  # ║  Filesystem mounts are handled by disko — not here.            ║
  # ╚══════════════════════════════════════════════════════════════════╝

  # Kernel modules for Parallels VM on aarch64
  boot.initrd.availableKernelModules = [
    "ehci_pci" "xhci_pci" "usbhid" "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Parallels Guest Tools (clipboard sync, display resize, shared folders)
  # Requires allowUnfree for prl-tools — see configuration.nix
  hardware.parallels.enable = true;
  # hardware.parallels.autoMountShares = true;  # uncomment for shared folders
}
