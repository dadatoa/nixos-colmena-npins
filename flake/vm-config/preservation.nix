{
  preservation = {
    enable = true;

    preserveAt."/persist" = {
      directories = [
        "/etc/nixos"
        # "/var/lib/bluetooth"
        "/var/lib/tailscale"
        "/var/lib/glusterd"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
      ];

      files = [
        "/etc/ssh/authorized_keys.d/operateur"
        {
          file = "/persist/secrets/root-password.txt";
          inInitrd = true;
        }
        {
          file = "/persist/secrets/ts-key.txt";
          inInitrd = true;
        }
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];

      # Preserve user files
      users.operateur = {
        files = [
          ".gitconfig"
          ".ssh/authorized_keys"
        ];
      };
      users.root = {
        home = "/root";
        directories = [ ];
        files = [ ".gitconfig" ];
      };
    };
  };
}
