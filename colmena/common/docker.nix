{ ... }:
{
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    daemon.settings = {
      userland-proxy = false;
      experimental = true;
      metrics-addr = "0.0.0.0:9323";
      ipv6 = true;
      fixed-cidr-v6 = "fd00::/80";
    };
  };

  users.users.mobi = {
    isNormalUser = true;
    uid = 1005;
    description = "docker user";
    extraGroups = [ "docker" ];
    shell = pkgs.nushell;
    packages = with pkgs; [ nushell zoxide fish carapace starship chezmoi ];
  };
}
