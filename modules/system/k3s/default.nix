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
    systemd.services.sshd.stopIfChanged = mkForce false;
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
        # Common node label configuration for both server and agent
        extraFlags = toString ((if cfg.master then [
          # Server (master) specific configuration
          "--cluster-init"
          "--write-kubeconfig-mode=0644"
          "--disable=servicelb"
          "--disable=traefik"
          "--disable=local-storage"
        ] else
          [
            # Agent (worker) specific configuration
          ]) ++ [
            # Common flags for both server and agent
            "--node-label=node.longhorn.io/create-default-disk=true"
          ]);
      } // (if !cfg.master then {
        # Agent-only configuration
        serverAddr = "https://${cfg.masterHostname}:6443";
      } else
        { });
    };
  };
}
