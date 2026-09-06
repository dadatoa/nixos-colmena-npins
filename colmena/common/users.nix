# Shared "operateur" account, applied to every node via hive.nix `defaults`.
# - uid 1000
# - passwordless sudo
# - may reboot/poweroff without sudo (polkit)
{ pkgs, ... }:
{
  users.users.operateur = {
    isNormalUser = true;
    uid = 1000;
    description = "Operator";
    extraGroups = [ "wheel" "video" ];
    # shell = pkgs.nushell;
    packages = with pkgs; [ nushell zoxide fish carapace starship chezmoi ];
    hashedPasswordFile = "/persist/keys/operateur_password_hash";
  };

  environment.shells = [ pkgs.nushell ];

  # users.users.root.hashedPassword = "$y$j9T$7KS0JnyfiA/D3xjb5KhkL.$4ftVKMN9aVxQZ4HGXWOB8eVaq9EOXFL01Jq8vyEBG93";
  users.users.root.hashedPasswordFile = "/persist/keys/root_password_hash";
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

  # allow nix-copy to live system
  nix.settings.trusted-users = [ "operateur" ];
}
