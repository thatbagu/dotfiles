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
    seedNodePassword = mkOption {
      type = types.bool;
      default = false;
      description = "Pre-seed /etc/rancher/node/password from k3s_token so the worker presents a deterministic password after reinstalls.";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ k3s cifs-utils nfs-utils ];
    systemd.tmpfiles.rules =
      [ "L+ /usr/local/bin - - - - /run/current-system/sw/bin/" ];
    virtualisation.docker.logDriver = "json-file";
    networking.firewall.enable = mkForce false;
    systemd.services.sshd.stopIfChanged = mkForce false;

    # Pre-seed the node password from k3s_token before k3s starts so the worker
    # always presents the same password after a reinstall.
    systemd.services.k3s-node-password = mkIf cfg.seedNodePassword {
      description = "Pre-seed k3s node password from k3s_token";
      before = [ "k3s.service" ];
      wantedBy = [ "k3s.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /etc/rancher/node
        cp ${config.sops.secrets.k3s_token.path} /etc/rancher/node/password
        chmod 0600 /etc/rancher/node/password
      '';
    };

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
        extraFlags = toString ((if cfg.master then [
          "--cluster-init"
          "--write-kubeconfig-mode=0644"
          "--disable=servicelb"
          "--disable=traefik"
          "--disable=local-storage"
          "--node-label=node-role=master"
        ] else [
          "--node-label=node-role=worker"
        ]) ++ [
          "--node-label=node.longhorn.io/create-default-disk=true"
        ]);
      } // (if !cfg.master then {
        serverAddr = "https://${cfg.masterHostname}:6443";
      } else { });
    };
  };
}
