{
  description = "Multi-machine NixOS configuration (Lenovo laptop + AMD desktop)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, home-manager, nur, ... }@inputs: {
    nixosConfigurations = {

      lenovo-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/common.nix
          ./modules/gnome-desktop.nix
          ./modules/virtualization.nix
          ./modules/gaming.nix
          ./modules/packages.nix
		  ./modules/lenovo-yoga-speakers.nix
		  ./modules/pipewire-eq.nix
          ./hosts/lenovo
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.dylan = import ./home/dylan.nix;
          }
          {
            nixpkgs.overlays = [ nur.overlays.default ];
          }
        ];
      };

      desktop-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/common.nix
          ./modules/gnome-desktop.nix
          ./modules/virtualization.nix
          ./modules/gaming.nix
          ./modules/packages.nix
          ./hosts/desktop
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.dylan = import ./home/dylan.nix;
          }
          {
            nixpkgs.overlays = [ nur.overlays.default ];
          }
        ];
      };
    };
  };
}
