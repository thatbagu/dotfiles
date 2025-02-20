{ ... }: {
  imports = [
    ../../../modules/system/configuration.nix
    ./disko.nix
    ../../../modules/system/impermanence
  ];
  config.modules = {
    sys-packages.enable = true;
    k3s = {
      enable = true;
      master = true;
    };
    sops.enable = true;
  };
}
