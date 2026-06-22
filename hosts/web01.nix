{ pkgs, ... }:
{
  networking.hostName = "web01";

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

  # Mixing stable and unstable packages: the system stays on stable (24.11),
  # but these packages come from nixos-unstable via the overlay.
  environment.systemPackages = [
    pkgs.htop            # stable
    pkgs.unstable.neovim # unstable
    pkgs.unstable.zellij # unstable
  ];

  # A service whose option module comes from stable, but the package from unstable.
  services.caddy = {
    enable = true;
    package = pkgs.unstable.caddy;
    virtualHosts."web01.example.com".extraConfig = ''
      respond "hello from unstable caddy"
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "24.11";
}
