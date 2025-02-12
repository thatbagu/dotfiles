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
    unifi.enable = true;
    sops.enable = true;
  };
}
