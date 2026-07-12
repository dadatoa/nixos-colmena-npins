{ config, pkgs, ... }:
{
  users.users.operateur = {
    ## dont lock myself out at first boot
    hashedPassword = "$y$j9T$NxPYeSkHmzOaNbGuQkLK1.$Pv7ni5ZnntgNWGisvJ07uSMoJ.mdLgDcAZ7mK8.7wv9";
    isNormalUser = true;
    uid = 1000;
    description = "main user";
    extraGroups = [
      "video"
      "wheel"
    ];
    # packages = with pkgs; [ ];
    openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8cHhGVCwBSPMRvTj93JMMOIBl+jZE97APmjqiwJIEH dadatoa@MacBook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF36sv0vHnOUCx8uMWCkwLwpQoBgWP0NzYRhd6+6vr8t deploy_app_to_server_github_actions"

    ];
  };
  users.users.root = {
    ## dont lock myself out at first boot
    hashedPassword = "$y$j9T$uYTs80JuhTlMyiLgfok3V.$5tJtvXBuLUI0h8kUC2jEL9q3VSro1I/KksPfFbmKrSA"
  };
  security.sudo.wheelNeedsPassword = false;
}
