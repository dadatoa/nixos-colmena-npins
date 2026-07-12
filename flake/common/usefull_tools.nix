{ config, pkgs, ... }:
{
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    bat
    carapace # needed for nushell completions
    chezmoi # to replce stow for dotfiles
    fish # needed for nushell completions
    gum
    jq
    just
    nushell # add fish and carapace for completions
    skate # database key-value pair
    starship
    zoxide
  ];
}
