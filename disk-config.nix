# ╔══════════════════════════════════════════════════════════════════╗
# ║  Declarative disk layout — no more parted/mkfs by hand          ║
# ║  Managed by disko: https://github.com/nix-community/disko      ║
# ╚══════════════════════════════════════════════════════════════════╝
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";    # Parallels on Apple Silicon — always sda
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
