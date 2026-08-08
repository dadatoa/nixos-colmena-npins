{
  preservation = {
    enable = true;

    preserveAt."/persist" = {
      directories = [
        "/etc/nixos"
        # "/var/lib/bluetooth"
      ];

      files = [
        "/etc/ssh/authorized_keys.d/operateur"
        {
          file = "/etc/machine-id";
          inInitrd = true;
          how = "symlink";
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
