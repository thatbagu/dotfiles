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

    impermanence = { url = "github:nix-community/impermanence"; };
    colmena = { url = "github:zhaofengli/colmena"; };
  };

  outputs = { self, home-manager, nixpkgs, stylix, sops-nix, nixvim, nix-darwin
    , disko, impermanence, colmena, ... }@inputs:
    let
      # Function to get clean hostname without path
      cleanHostname = hostname:
        let
          parts = builtins.split "/" hostname;
          lastPart = builtins.elemAt parts (builtins.length parts - 1);
        in lastPart;

      # Define all Linux machines configuration
      nixosMachines = {
        # Homelab machines
        meowth = {
          hostname = "homelab/meowth";
          username = "egor";
          tags = [ "homelab" "master" "meowth" ];
        };
        psyduck = {
          hostname = "homelab/psyduck";
          username = "egor";
          tags = [ "homelab" "worker" "psyduck" ];
        };
        bulbasaur = {
          hostname = "homelab/bulbasaur";
          username = "egor";
          tags = [ "homelab" "worker" "bulbasaur" ];
        };
        # Other Linux machines
        laptop = {
          hostname = "laptop";
          username = "egor";
          tags = [ "personal" "laptop" ];
        };
        main = {
          hostname = "main";
          username = "egor";
          tags = [ "personal" "main" ];
        };
      };

      # Create system modules that can be used by both NixOS and Colmena
      mkSystemModules = system: hostname: username:
        let
          isDarwin = builtins.match ".*darwin" system != null;
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
            impermanence.nixosModules.impermanence
          ];
        in [{
          networking.hostName = cleanHostname hostname;
          nixpkgs.config.allowUnfree = true;
        }] ++ systemModules ++ [
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

      # Function to build NixOS configurations
      mkSystem = pkgs: system: hostname: username:
        let
          isDarwin = builtins.match ".*darwin" system != null;
          systemFunc = if isDarwin then
            nix-darwin.lib.darwinSystem
          else
            pkgs.lib.nixosSystem;
          modules = mkSystemModules system hostname username;
        in systemFunc {
          inherit system;
          specialArgs = {
            inherit inputs username;
            hostname = cleanHostname hostname;
          };
          inherit modules;
        };

    in {
      inherit nixosMachines;

      nixosConfigurations = {
        # installer iso
        iso = mkSystem inputs.nixpkgs "x86_64-linux" "iso" "nixos";
      } // (builtins.mapAttrs (name: machine:
        mkSystem inputs.nixpkgs "x86_64-linux" machine.hostname
        machine.username) nixosMachines);

      darwinConfigurations = {
        work = mkSystem inputs.nix-darwin "aarch64-darwin" "work" "egor";
      };

      colmena = {
        meta = {
          nixpkgs = import nixpkgs { system = "x86_64-linux"; };
          specialArgs = {
            inherit inputs;

          };
        };
      } // (builtins.mapAttrs (name: machine: {
        # Explicitly add the hostname module parameter
        _module.args.hostname = cleanHostname machine.hostname;

        # Reuse the same modules that we use for NixOS configurations
        imports = mkSystemModules "x86_64-linux" machine.hostname "egor";

        deployment = {
          targetHost = cleanHostname machine.hostname;
          targetUser = machine.username;
          privilegeEscalationCommand = [ "sudo" "-S" ];
          tags = machine.tags;
        };
      }) nixosMachines);
    };
}
