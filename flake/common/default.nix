{ lib, ... }:
{
  system.stateVersion = "26.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  imports = [
    ./users
    ./administration.nix
    ./localisation.nix
    ./remote_access.nix
    ./settings.nix
    ./usefull_tools.nix
  ]; 
}
