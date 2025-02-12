{ config, lib, inputs, ... }: {
  imports = [ ../../modules/system/darwin-configuration.nix ];
  config.modules = {
    sys-packages.enable = true;
    # steam.enable = true;
    # stylix.enable = true;
    # unifi.enable = true;
    sops.enable = true;
  };
}
