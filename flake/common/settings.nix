{ config, lib, pkgs, inputs, ... }:
{
  nix = {
    optimise.automatic = true;

    settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    settings.trusted-users = [ "@wheel" ];
  };

  # Set your time zone.
  time.timeZone = "Asia/Bangkok";

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

}
