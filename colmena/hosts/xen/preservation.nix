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
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];
    };
  };
}
