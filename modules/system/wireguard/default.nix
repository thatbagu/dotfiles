{ lib, config, ... }:

with lib;
let cfg = config.modules.wireguard;
in {
  options.modules.wireguard = {
    enable = mkEnableOption "wireguard";

    homelab = {
      enable = mkEnableOption "the homelab VPN (egor-main peer, toggled from waybar)";
      endpoint = mkOption {
        type = types.str;
        # MetalLB IP of the wireguard Service; reachable while on the home LAN.
        default = "192.168.1.194:51820";
        description = "WireGuard endpoint of the homelab server.";
      };
    };
  };

  config = mkIf cfg.enable {
    networking.wg-quick.interfaces.japan = {
      configFile = config.sops.secrets.japan_wg_private_key.path;
    };

    # Split tunnel: only the VPN subnet goes through it. While up, DNS points at
    # Pi-hole, which resolves nextcloud.egor.house to the Caddy proxy on
    # 10.0.100.1, so Nextcloud logs in as egor automatically.
    networking.wg-quick.interfaces.homelab = mkIf cfg.homelab.enable {
      autostart = false;
      address = [ "10.0.100.2/32" ];
      dns = [ "192.168.1.250" ];
      privateKeyFile = config.sops.secrets.egor_main_wg_private_key.path;
      peers = [{
        publicKey = "I5z2TF0qPxp/tK3mjuHsL+h5W/OYNiS/l3ujaWVfHSk=";
        endpoint = cfg.homelab.endpoint;
        allowedIPs = [ "10.0.100.0/24" ];
        persistentKeepalive = 25;
      }];
    };
  };
}
