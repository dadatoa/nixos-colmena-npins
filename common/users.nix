# Shared "operator" account, applied to every node via hive.nix `defaults`.
# - uid 1000
# - passwordless sudo
# - may reboot/poweroff without sudo (polkit)
{ ... }:
{
  users.users.operator = {
    isNormalUser = true;
    uid = 1000;
    description = "Operator";
    # No password / SSH key is set here. Add one per-host (or here) so the
    # account can actually log in, e.g.:
    #   users.users.operator.openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ];
  };

  # Passwordless sudo, scoped to the operator user only.
  security.sudo.extraRules = [
    {
      users = [ "operator" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Allow operator to reboot/power off without sudo (or any authentication),
  # even when other sessions are active or inhibitors are set.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "operator" &&
          (action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
           action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
           action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
           action.id == "org.freedesktop.login1.reboot-ignore-inhibit")) {
        return polkit.Result.YES;
      }
    });
  '';
}
