{ ... }:
{
  preservation = {
    enable = true;

    preserveAt."/persist" = {
      directories = [
        "/etc/nixos"
        "/run/keys"
      ];

      files = [
        "/etc/ssh/authorized_keys.d/operateur"
        { # PRevent Failed to start Save Transient machine-id to Disk
          file = "/etc/machine-id";
          inInitrd = true;
          how = "symlink";
        }
      ];
    };
  };
}
