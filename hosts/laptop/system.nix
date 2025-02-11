{ config, lib, inputs, ...}:
{
    imports = [ 
               ../../modules/system/configuration.nix
              ];
    config.modules = {
        sys-packages.enable = true;
        steam.enable = true;
        stylix.enable = true;
    };
}
