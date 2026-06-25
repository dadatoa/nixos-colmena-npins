{
  preservation = {
    enable = true;

    preserveAt."/persist" = {
      directories = [
        "/etc/nixos"
        # "/var/lib/bluetooth"
        "/var/lib/tailscale"
        "/var/lib/glusterd"
        { directory = "/var/lib/nixos"; inInitrd = true; }
      ];

      files = [
        "/etc/ssh/authorized_keys.d/operateur"
        { file = "/etc/machine-id"; inInitrd = true; }
      ];

      # Preserve user files
      users.operateur = {
        directories = [ ".ssh" ];
        files = [ ".gitconfig" ];
      };
      users.root = {
        home = "/root";
        directories = [ ];
        files = [ ".gitconfig" ];
      };
    };
  };
}
