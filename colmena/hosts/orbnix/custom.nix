{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    colmena
    npins
  ];
}
