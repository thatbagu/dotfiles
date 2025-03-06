{ pkgs, lib, config, username, hostname, ... }:

with lib;
let cfg = config.modules.k3s;

in {
  options.modules.k3s = {
    enable = mkEnableOption "k3s";
    master = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node is a master node";
    };
    masterHostname = mkOption {
      type = types.str;
      default = "${hostname}";
      description = "Hostname of the master node to connect to";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ k3s cifs-utils nfs-utils ];

    systemd.tmpfiles.rules =
      [ "L+ /usr/local/bin - - - - /run/current-system/sw/bin/" ];
    virtualisation.docker.logDriver = "json-file";

    networking.firewall.enable = mkForce false;

    services = {
      openssh.enable = mkForce true;

      openiscsi = {
        enable = true;
        name = "iqn.2016-04.com.open-iscsi:${hostname}";
      };

      k3s = {
        enable = true;
        role = if cfg.master then "server" else "agent";
        tokenFile = config.sops.secrets.k3s_token.path;
        serverAddr =
          if (!cfg.master) then "https://${cfg.masterHostname}:6443" else null;
        extraFlags = toString ([
          ''--write-kubeconfig-mode "0644"''
          "--disable servicelb"
          "--disable traefik"
          "--disable local-storage"
        ] ++ (if cfg.master then [ "--cluster-init" ] else [ ]));
      };
    };
  };
}
