{ pkgs, ... }:
{
  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  environment.systemPackages = with pkgs; [
    colmena
    npins
  ];
}
