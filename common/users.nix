# Shared "operateur" account, applied to every node via hive.nix `defaults`.
# - uid 1000
# - passwordless sudo
# - may reboot/poweroff without sudo (polkit)
{ ... }:
{
  users.users.operateur = {
    isNormalUser = true;
    uid = 1000;
    description = "Operator";
    openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBA52LLKZPhszwrzrqOwLJ2a2spNzjAn/ls6krE9SM/i dadatoa@dadabook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHnWrIExo7hWe04wTUUEn6smnx/LRfNtPtatR+NgQlfz SpaceK@dadabook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF36sv0vHnOUCx8uMWCkwLwpQoBgWP0NzYRhd6+6vr8t deploy_app_to_server_github_actions"
    ];
  };

  users.users.root.hashedPasswordFile = "/persist/secrets/root-password.txt";

  # Passwordless sudo, scoped to the operateur user only.
  security.sudo.extraRules = [
    {
      users = [ "operateur" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Allow operateur to reboot/power off without sudo (or any authentication),
  # even when other sessions are active or inhibitors are set.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "operateur" &&
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
