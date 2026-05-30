{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.sys-packages;

in {
  options.modules.sys-packages = { enable = mkEnableOption "sys-packages"; };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pulsemixer
      acpi
      dnsutils
      tlp
      gnutls
      curl
      wget
      sops
      age
      jq
      colmena
      devenv
      wireguard-tools
    ];
  };
}
