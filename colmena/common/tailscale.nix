{ config, lib, pkgs, ... }:

{
# enable Tailscale with config
  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };


}
