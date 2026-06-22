{ pkgs, ... }:
{
  networking.hostName = "db01";

  # Minimal bootable layout so the configuration evaluates/builds.
  # Replace these with the real values from the target's hardware-configuration.nix.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # PostgreSQL server option module from stable, package from unstable.
  services.postgresql = {
    enable = true;
    package = pkgs.unstable.postgresql_16;
  };

  environment.systemPackages = [
    pkgs.unstable.pgcli
  ];

  networking.firewall.allowedTCPPorts = [ 5432 ];

  system.stateVersion = "26.05";
}
