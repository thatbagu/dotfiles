# Shared settings for the homelab cluster (nixidy modules + NixOS secrets unit).
rec {
  domain = "egor.house";

  # Namespace definitions
  namespaces = {
    dns = "dns-system";
    pihole = "pihole-system";
    nginx = "nginx-system";
    metallb = "metallb-system";
    longhorn = "longhorn-system";
    monitoring = "monitoring-system";
    wireguard = "wireguard-system";
    proxies   = "proxies";
    nextcloud = "nextcloud";
    cv = "cv";
  };

  # IP address pools
  ipPools = {
    metallb = "192.168.1.192/26";
    nginxExternal = "192.168.1.193";
    pihole = "192.168.1.250";
    wireguard = "192.168.1.194";
    sslh      = "192.168.1.195";
  };

  # References to make code cleaner
  piholeIp = ipPools.pihole;

  # Version control for images
  versions = { pihole = "2025.11.1"; };

  # Common configuration
  defaultReplicas = 1;

  # Prefer scheduling app pods on worker nodes so meowth stays free for
  # control-plane work. Using preferred (not required) so pods still
  # schedule on meowth if workers are unavailable.
  workerAffinity = {
    nodeAffinity = {
      preferredDuringSchedulingIgnoredDuringExecution = [{
        weight = 100;
        preference.matchExpressions = [{
          key      = "node-role";
          operator = "In";
          values   = [ "worker" ];
        }];
      }];
    };
  };

  # TLS configuration
  tls = {
    defaultIssuer = "letsencrypt-prod";
    stagingIssuer = "letsencrypt-staging";
    acmeServerProduction = "https://acme-v02.api.letsencrypt.org/directory";
    acmeServerStaging =
      "https://acme-staging-v02.api.letsencrypt.org/directory";
  };
}
