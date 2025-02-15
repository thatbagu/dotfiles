{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.packages.core;
in {
  options.modules.packages.core = { enable = mkEnableOption "core packages"; };
  config = mkIf cfg.enable {
    home.shellAliases = {
      # eza replacements for ls
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      l = "eza -l";

      # bat replacement for cat
      cat = "bat";

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
      enableNushellIntegration = true;
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

      # Go
      go
      golangci-lint
      gopls
      go-tools

      # Nix
      statix
      nil
      nixfmt

      # Rust
      rustc
      cargo
      rustfmt
      rust-analyzer
      clippy
      gcc

      # Cloud & Container Tools
      google-cloud-sdk
      awscli
      kubectl
      k9s

      # System Utils
      htop
      ranger
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

