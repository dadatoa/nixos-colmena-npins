{ ... }:
{
  imports = [
    ../../common/xen_domU.nix
    ./test.nix
  ];

  preservation = {
    enable = true;

    preserveAt."/persist" = {
      directories = [
        "/etc/nixos"
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
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];

      # Preserve user files
      users.operateur = {
        directories = [ ".ssh" ".config" ];
        files = [ ".gitconfig" ];
      };
      users.root = {
        home = "/root";
        directories = [];
        files = [ ".gitconfig" ];
      };
    };
  };
}
