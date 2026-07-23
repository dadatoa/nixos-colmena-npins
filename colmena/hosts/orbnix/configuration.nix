{ config, pkgs, modulesPath, ... }:

{
  imports =
    [
      # Include the default lxd configuration.
      "${modulesPath}/virtualisation/lxc-container.nix"
      # Include the OrbStack-specific configuration.
      ./orbstack.nix
      # add custom confg
      ./custom.nix
    ];

  networking.hostName = "orbnix";
  users.users.dadatoa = {
    uid = 502;
    extraGroups = [ "wheel" "orbstack" "audio" ];

    # simulate isNormalUser, but with an arbitrary UID
    isSystemUser = true;
    group = "users";
    createHome = true;
    home = "/home/dadatoa";
    homeMode = "700";
    useDefaultShell = true;
  };

  security.sudo.wheelNeedsPassword = false;

  # This being `true` leads to a few nasty bugs, change at your own risk!
  users.mutableUsers = false;

  time.timeZone = "Asia/Bangkok";

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  # Extra certificates from OrbStack.
  security.pki.certificates = [
    ''
      -----BEGIN CERTIFICATE-----
MIICCzCCAbKgAwIBAgIQVYjLFHJxZUPLL0JyNao9czAKBggqhkjOPQQDAjBmMR0w
GwYDVQQKExRPcmJTdGFjayBEZXZlbG9wbWVudDEeMBwGA1UECwwVQ29udGFpbmVy
cyAmIFNlcnZpY2VzMSUwIwYDVQQDExxPcmJTdGFjayBEZXZlbG9wbWVudCBSb290
IENBMB4XDTI2MDYzMDAzMzYwMVoXDTM2MDYzMDAzMzYwMVowZjEdMBsGA1UEChMU
T3JiU3RhY2sgRGV2ZWxvcG1lbnQxHjAcBgNVBAsMFUNvbnRhaW5lcnMgJiBTZXJ2
aWNlczElMCMGA1UEAxMcT3JiU3RhY2sgRGV2ZWxvcG1lbnQgUm9vdCBDQTBZMBMG
ByqGSM49AgEGCCqGSM49AwEHA0IABEOuVzOUJOqYi08AXh4tGVDm5iwi/pxyOAe0
/3teVReI9DS6Poc9X8RWDUHqzlU4yiHLa9h6ZX+dwipL3gHKnmqjQjBAMA4GA1Ud
DwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBS461C4YJ+aCPCv
QBgmIgst8liZfDAKBggqhkjOPQQDAgNHADBEAiAYLQAWsNq/rcO/vBmnWJjqSQOw
YhRBlXtMyTIgyugLBAIgJpw1ishCTG8mKHqvzKfmtM2+52CJDFlnOQAEfExgpCY=
-----END CERTIFICATE-----

    ''
  ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
