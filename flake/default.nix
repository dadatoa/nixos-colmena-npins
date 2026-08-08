{ inputs, ... }:
{
  flake.nixosConfigurations.nixdomu = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.preservation.nixosModules.default
      inputs.disko.nixosModules.default
      ./vm-config/configuration.nix
      ./vm-config/filesystems.nix
      ./vm-config/preservation.nix
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
