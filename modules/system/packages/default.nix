{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.sys-packages;

in {
  options.modules.sys-packages = { enable = mkEnableOption "sys-packages"; };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      acpi
      tlp
      gnutls
      curl
      wget
      sops
      age
      colmena
    ];
  };
}
