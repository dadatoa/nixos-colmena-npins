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
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    nushell # add fish and carapace for completions
    skate # database key-value pair
    starship
    zoxide
  ];
}
