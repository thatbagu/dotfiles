{ ... }: {
  imports = [
    ../../modules/system/configuration.nix
    ./disko.nix
    ../../modules/system/impermanence
  ];
  config.modules = {
    sys-packages.enable = true;
    steam.enable = true;
    stylix.enable = true;
    sops.enable = true;
    desktop.enable = true;
  };
}
