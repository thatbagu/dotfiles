{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.packages.core;
in {
  options.modules.packages.core = { enable = mkEnableOption "core packages"; };
  config = mkIf cfg.enable {
    home.shellAliases = {
      # zoxide replacement for cd
      cd = "z";

      # ripgrep replacement for grep
      grep = "rg --smart-case";
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };

    home.packages = with pkgs; [
      # Development
      git
      gh
      lua
      terraform
      terragrunt
      opentofu

      # Python
      python3
      ruff
      python311Packages.flake8
      python311Packages.black

      # Go
      go
      golangci-lint
      gopls
      go-tools
      gotools

      # Nix
      statix
      nil
      nixfmt

      # Lua
      stylua

      # JavaScript/TypeScript/Web
      nodePackages.prettier
      nodePackages.eslint_d

      # Rust
      rustup            # Rust toolchain manager (includes cargo, rustc, rustfmt, clippy, rust-analyzer)
      gcc

      # Embedded Development (ESP32 Rust)
      espflash          # Flash ESP32 devices
      espup             # Install ESP Rust toolchains
      esp-generate      # Modern ESP project generator
      cargo-espflash    # Cargo integration for flashing
      cargo-generate    # General Rust project templates
      probe-rs-tools    # Debugging and flashing for ARM/RISC-V

      # Cloud & Container Tools
      google-cloud-sdk
      awscli
      kubectl

      # System Utils
      htop
      yazi
      fzf
      ripgrep
      bat
      eza
      unzip
      tealdeer
      age
      tree
    ];
  };
}

