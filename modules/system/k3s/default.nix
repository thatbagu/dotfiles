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
    # Firewall: only what the cluster needs from the LAN. LoadBalancer/NodePort
    # traffic is DNATed to pods in PREROUTING (FORWARD, not filtered here), so
    # it isn't affected. etcd (2379/2380) stays closed: single server, local only.
    networking.firewall = {
      allowedTCPPorts = [
        22 # ssh (keys only)
        6443 # Kubernetes API (agents -> server, kubectl)
        10250 # kubelet (API server, metrics-server)
        7946 # MetalLB memberlist
      ];
      allowedUDPPorts = [
        8472 # flannel VXLAN (pod network between nodes)
        7946 # MetalLB memberlist
      ];
      allowedTCPPortRanges = [{ from = 30000; to = 32767; }]; # NodePorts / health checks
      allowedUDPPortRanges = [{ from = 30000; to = 32767; }];
      # Pod traffic to the host (kubelet, API via the kubernetes Service, ...).
      trustedInterfaces = [ "cni0" "flannel.1" ];
      # Strict reverse-path filtering drops asymmetric overlay/LB traffic.
      checkReversePath = "loose";
    };
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
      openssh = {
        enable = mkForce true;
        # Keys only: egor has passwordless sudo, so a guessed/phished password
        # would mean root on the cluster. Deploys use egor + sudo, never root.
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
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
          # Admin kubeconfig: root + wheel only (it was world-readable, i.e.
          # cluster-admin for any local user or process).
          "--write-kubeconfig-mode=0640"
          "--write-kubeconfig-group=wheel"
          "--disable=servicelb"
          "--disable=traefik"
          "--disable=local-storage"
          "--node-label=node-role=master"
        ] ++ concatMap (component: map (arg: "--${component}-arg=${arg}") [
          # meowth's SSD stalls ~2s on cache flush every ~2.5min; back-to-back
          # stalls exceeded the default 10s renew deadline, and a lost leader
          # lease makes k3s exit. Defaults are 15s lease / 10s renew.
          "leader-elect-lease-duration=60s"
          "leader-elect-renew-deadline=40s"
        ]) [ "kube-controller-manager" "kube-scheduler" "kube-cloud-controller-manager" ]
        else [
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
