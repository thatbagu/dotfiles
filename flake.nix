{
  description = "Egor's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Separate pin so only wine can be updated without touching the main nixpkgs.
    nixpkgs-wine.url = "github:nixos/nixpkgs/nixos-unstable";
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

    prismlauncher = {
      url = "github:PrismLauncher/PrismLauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    papertoy = {
      url = "github:thatbagu/papertoy";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    impermanence.url = "github:nix-community/impermanence";
    colmena.url = "github:zhaofengli/colmena";
    nixhelm.url = "github:farcaller/nixhelm";
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
    nixidy = {
      url = "github:arnarg/nixidy/v0.23.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code.url = "github:sadjow/claude-code-nix";

    # The homelab platform (NixOS + k3s + GitOps). The homelab nodes and the
    # Kubernetes render are built with nixlab.lib.mkNixlab (homelab/). Shares
    # this flake's pins so the nodes keep the same package versions.
    nixlab = {
      url = "github:thatbagu/nixlab/906275b13eefebcfeaeef2256f4d99c778f35203"; # v1.7.1 (unreleased): external-dns fix
      inputs = {
        nixpkgs.follows = "nixpkgs";
        disko.follows = "disko";
        sops-nix.follows = "sops-nix";
        impermanence.follows = "impermanence";
        colmena.follows = "colmena";
        nixhelm.follows = "nixhelm";
        nix-kube-generators.follows = "nix-kube-generators";
        nixidy.follows = "nixidy";
      };
    };
  };

  outputs =
    {
      self,
      home-manager,
      nixpkgs,
      stylix,
      sops-nix,
      nixvim,
      nix-darwin,
      disko,
      impermanence,
      colmena,
      nixhelm,
      papertoy,
      ghostty,
      claude-code,
      ...
    }@inputs:
    let
      # Function to get clean hostname without path
      cleanHostname =
        hostname:
        let
          parts = builtins.split "/" hostname;
          lastPart = builtins.elemAt parts (builtins.length parts - 1);
        in
        lastPart;

      # Define all Linux machines configuration
      nixosMachines = {
        # Homelab machines
        meowth = {
          hostname = "homelab/meowth";
          username = "egor";
          tags = [
            "homelab"
            "master"
            "meowth"
          ];
        };
        psyduck = {
          hostname = "homelab/psyduck";
          username = "egor";
          tags = [
            "homelab"
            "worker"
            "psyduck"
          ];
        };
        bulbasaur = {
          hostname = "homelab/bulbasaur";
          username = "egor";
          tags = [
            "homelab"
            "worker"
            "bulbasaur"
          ];
        };
        # Other Linux machines
        laptop = {
          hostname = "laptop";
          username = "egor";
          tags = [
            "personal"
            "laptop"
          ];
        };
        main = {
          hostname = "main";
          username = "egor";
          tags = [
            "personal"
            "main"
          ];
        };
      };

      mkSystemModules =
        system: hostname: username:
        let
          isDarwin = builtins.match ".*darwin" system != null;
          hmModule =
            if isDarwin then
              home-manager.darwinModules.home-manager
            else
              home-manager.nixosModules.home-manager;

          # Load overlays
          overlays = import ./overlays/default.nix;

          # Wine-only upgrade overlay: pulls wineWowPackages.staging from a
          # separately pinned nixpkgs so wine can be updated without touching
          # the rest of the system. Only applied on x86_64-linux.
          wineOverlay = final: prev:
            if system == "x86_64-linux" then {
              wineWowPackages = prev.wineWowPackages // {
                staging = (import inputs."nixpkgs-wine" {
                  inherit system;
                  config.allowUnfree = true;
                }).wineWowPackages.staging;
              };
            } else { };

          # Optional modules based on system type
          systemModules =
            if isDarwin then
              [
                (./. + "/hosts/${hostname}/system.nix")
                sops-nix.darwinModules.sops
              ]
            else
              [
                (./. + "/hosts/${hostname}/system.nix")
                (./. + "/hosts/${hostname}/hardware-configuration.nix")
                stylix.nixosModules.stylix
                sops-nix.nixosModules.sops
                disko.nixosModules.disko
                impermanence.nixosModules.impermanence
              ];
        in
        [
          {
            networking.hostName = cleanHostname hostname;
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = (builtins.attrValues overlays) ++ [ wineOverlay ];
          }
        ]
        ++ systemModules
        ++ [
          hmModule
          {
            home-manager = {
              useUserPackages = true;
              useGlobalPkgs = true;
              backupFileExtension = "-backup";
              extraSpecialArgs = {
                inherit inputs;
                claude-code = claude-code.packages.x86_64-linux.default;
              };
              users.${username} = {
                imports = [
                  (./. + "/hosts/${hostname}/user.nix")
                  nixvim.homeModules.nixvim
                ];
              };
            };
          }
        ];
      # Function to build NixOS configurations
      mkSystem =
        pkgs: system: hostname: username:
        let
          isDarwin = builtins.match ".*darwin" system != null;
          systemFunc = if isDarwin then nix-darwin.lib.darwinSystem else pkgs.lib.nixosSystem;
          modules = mkSystemModules system hostname username;
        in
        systemFunc {
          specialArgs = {
            inherit inputs username;
            hostname = cleanHostname hostname;
          };
          modules = modules ++ [{ nixpkgs.hostPlatform = system; }];
        };

      isHomelab = machine: builtins.elem "homelab" machine.tags;
      personalMachines = nixpkgs.lib.filterAttrs (_: m: !isHomelab m) nixosMachines;

      # The homelab (nodes + Kubernetes render), built with nixlab.
      homelab = inputs.nixlab.lib.mkNixlab {
        vars = import ./homelab/vars.nix;
        secretsFile = ./modules/system/sops/secrets.yaml;
        appsDir = ./homelab/apps;
        hardwareConfig = hostname: ./homelab/hosts + "/${hostname}/hardware-configuration.nix";
        extraNixosModules = [ (import ./homelab/hosts inputs) ];
        # Kubernetes Secrets for the homelab's own apps, from SOPS (see
        # nixlab's docs/secrets.md).
        extraSecrets = [
          {
            # SSH host key of the cv TUI.
            namespace = "cv";
            secretName = "cv-tui-ssh-host-key";
            secretKey = "cv_ssh_host_key";
            sopsSecretName = "cv_tui_ssh_host_key";
          }
          {
            # GitHub token the cv runners register with (apps/cv-runner.nix).
            namespace = "arc-runners";
            secretName = "arc-github";
            secretKey = "github_token";
            sopsSecretName = "github_token";
          }
        ];
      };

    in
    {
      inherit nixosMachines;

      nixosConfigurations = {
        # installer iso
        iso = mkSystem inputs.nixpkgs "x86_64-linux" "iso" "nixos";
      }
      // (builtins.mapAttrs (
        name: machine: mkSystem inputs.nixpkgs "x86_64-linux" machine.hostname machine.username
      ) personalMachines)
      // homelab.nixosConfigurations;

      # Kubernetes manifests for the homelab cluster, synced by Argo CD.
      # Render with: nix run github:arnarg/nixidy/v0.23.1 -- switch .#homelab
      nixidyEnvs.x86_64-linux = homelab.nixidyEnvs;

      darwinConfigurations = {
        work = mkSystem inputs.nix-darwin "aarch64-darwin" "work" "egor";
      };

      colmena = {
        meta = {
          nixpkgs = nixpkgs.legacyPackages.x86_64-linux;
          specialArgs = {
            inherit inputs;

          };
        };
      }
      // (builtins.mapAttrs (name: machine: {
        # Reuse the same modules that we use for NixOS configurations (the
        # homelab nodes come from nixlab).
        _module.args = if isHomelab machine then
          homelab.specialArgsFor name
        else {
          hostname = cleanHostname machine.hostname;
          username = machine.username;
        };
        imports = if isHomelab machine then
          homelab.modulesFor name
        else
          mkSystemModules "x86_64-linux" machine.hostname "egor"
          ++ [{ nixpkgs.hostPlatform = "x86_64-linux"; }];

        deployment = {
          targetHost = if builtins.elem "homelab" machine.tags
            then "${cleanHostname machine.hostname}.local"
            else cleanHostname machine.hostname;
          targetUser = machine.username;
          privilegeEscalationCommand = [
            "sudo"
            "-S"
          ];
          tags = machine.tags;
        };
      }) nixosMachines);
    };
}
