{
  description = "Egor's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stylix.url = "github:danth/stylix";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { home-manager, nixpkgs, stylix, sops-nix, nixvim, nix-darwin, disko
    , ... }@inputs:
    let
      mkSystem = pkgs: system: hostname: username:
        let
          isDarwin = builtins.match ".*darwin" system != null;
          systemFunc = if isDarwin then
            nix-darwin.lib.darwinSystem
          else
            pkgs.lib.nixosSystem;
          hmModule = if isDarwin then
            home-manager.darwinModules.home-manager
          else
            home-manager.nixosModules.home-manager;
          # Optional modules based on system type
          systemModules = if isDarwin then [
            (./. + "/hosts/${hostname}/system.nix")
            sops-nix.darwinModules.sops
          ] else [
            (./. + "/hosts/${hostname}/system.nix")
            (./. + "/hosts/${hostname}/hardware-configuration.nix")
            stylix.nixosModules.stylix
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        in systemFunc {
          inherit system;
          specialArgs = { inherit inputs username; };

          modules = [{
            networking.hostName = hostname;

            nixpkgs.config.allowUnfree = true;
          }

          # System-specific modules
            ] ++ systemModules ++ [

              hmModule
              {
                home-manager = {
                  useUserPackages = true;
                  useGlobalPkgs = true;
                  extraSpecialArgs = { inherit inputs; };
                  users.${username} = {
                    imports = [
                      (./. + "/hosts/${hostname}/user.nix")

                      nixvim.homeManagerModules.nixvim
                    ];
                  };
                };
              }
            ];
        };

    in {
      nixosConfigurations = {
        laptop = mkSystem inputs.nixpkgs "x86_64-linux" "laptop" "egor";
        main = mkSystem inputs.nixpkgs "x86_64-linux" "main" "egor";
      };

      darwinConfigurations = {
        work = mkSystem inputs.nix-darwin "aarch64-darwin" "work" "egor";
      };
    };
}
