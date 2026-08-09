{ inputs, ... }:
{
  flake.nixosConfigurations.nixdomu = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.preservation.nixosModules.default
      ../colmena/common/xen_domU.nix
      ../colmena/common/users.nix
      ../colmena/common/locale.nix
      # ./vm-config/configuration.nix
      # ./vm-config/filesystems.nix
      # ./vm-config/preservation.nix
      ./vm-config/networking.nix
    ];
  };

  flake.nixosConfigurations.xen = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.preservation.nixosModules.default
      inputs.disko.nixosModules.default
      ./xen-config/configuration.nix
      ./xen-config/filesystems.nix
      ./xen-config/preservation.nix
    ];
  };
}
