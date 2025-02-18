{ ... }: {
  imports = [ ../../modules/home/default.nix ];
  config.modules = {
    # Terminal & Shell
    nixvim.enable = true;
    nushell.enable = true;
    zellij.enable = true;

    # Development
    git.enable = true;

    # System
    packages.enable = true;
    scripts.enable = true;
  };
}
