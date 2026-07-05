{ config, pkgs, lib, ... }:{
  

  # Don't require sudo/root to `reboot` or `poweroff`.
  security.polkit.enable = true;

  # Allow passwordless sudo from nixos user
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Automatically log in at the virtual consoles.
  services.getty.autologinUser = "operateur";

  # allow nix-copy to live system
  nix.settings.trusted-users = [ "operateur" ];
}
