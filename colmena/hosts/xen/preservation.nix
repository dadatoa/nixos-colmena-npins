{
  preservation = {
    enable = true;

    preserveAt."/persist" = {
      directories = [
        "/etc/nixos"
        # "/var/lib/bluetooth"
        "/var/lib/tailscale"
        "/var/lib/xen"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }

      ];

      files = [
        "/etc/ssh/authorized_keys.d/operateur"
        "/etc/xen/auto/bender.cfg"
-       "/etc/xen/auto/nas.cfg"
-       "/etc/xen/auto/deckard.cfg"
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];
      users.operateur = {
        directories = [ ".ssh" ".config" "xl-configs" ];
        files = [ ".gitconfig" ];
      };

    };
  };
}
