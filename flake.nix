{
  description = "Multi-machine NixOS configuration (NAS, Framework Desktop, LattePanda)";

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

      diy-nas = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/common.nix
          ./modules/networking.nix
          ./modules/packages.nix
		  ./modules/virtualization.nix
          ./hosts/diy-nas
          {
            nixpkgs.overlays = [ nur.overlays.default ];
          }
        ];
      };

      framework = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/common.nix
          ./modules/networking.nix
          ./modules/gnome-desktop.nix
          ./modules/packages.nix
          ./hosts/framework
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

      lattepanda = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/common.nix
          ./modules/networking.nix
          ./modules/packages.nix
          ./hosts/lattepanda
          {
            nixpkgs.overlays = [ nur.overlays.default ];
          }
        ];
      };

      bard-frigate = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/common.nix
          ./modules/networking.nix
          ./modules/packages.nix
          ./hosts/bard-frigate
          {
            nixpkgs.overlays = [ nur.overlays.default ];
          }
        ];
      };



    };
  };
}
