{ pkgs, inputs, ... }:

let
  # Import lib.nix for helper functions but not variables
  lib = import ./lib.nix { inherit pkgs inputs; };

  # Centralized variables for all services
  vars = rec {
    domain = "egor.house";
    cloudflareEmail = "your-cloudflare-email@example.com";

    # Namespace definitions
    namespaces = {
      dns = "dns-system";
      pihole = "pihole-system";
      nginx = "nginx-system";
      metallb = "metallb-system";
      longhorn = "longhorn-system";
      monitoring = "monitoring-system";
    };

    # IP address pools
    ipPools = {
      metallb = "192.168.1.192/26";
      nginxExternal = "192.168.1.193";
      pihole = "192.168.1.250";
    };

    # References to make code cleaner
    piholeIp = ipPools.pihole;

    # Version control for images
    versions = { pihole = "2024.07.0"; };

    # Common configuration 
    defaultReplicas = 1;

    # TLS configuration
    tls = {
      defaultIssuer = "letsencrypt-prod";
      stagingIssuer = "letsencrypt-staging";
      acmeServerProduction = "https://acme-v02.api.letsencrypt.org/directory";
      acmeServerStaging =
        "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
  };

  # Import all service configurations using the service builder
  coreServices = {
    longhorn = mkService (import ./services/core/longhorn.nix);
    metallb = mkService (import ./services/core/metallb.nix);
    nginx = mkService (import ./services/core/nginx.nix);
  };

  dnsServices = {
    pihole = mkService (import ./services/dns/pihole.nix);
    externaldns = mkService (import ./services/dns/externaldns.nix);
    certManager = mkService (import ./services/dns/cert-manager.nix);
  };

  ingressResources = {
    ingress = mkService (import ./services/ingress/ingress.nix);
  };

  monitoringServices = {
    metricsServer = mkService (import ./services/monitoring/metrics-server.nix);
    kubernetesDashboard =
      mkService (import ./services/monitoring/kubernetes-dashboard.nix);
  };

  # Combine all services into a flat attribute set
  allServices = coreServices.longhorn // coreServices.metallb
    // coreServices.nginx // dnsServices.pihole // dnsServices.externaldns
    // dnsServices.certManager // ingressResources.ingress
    // monitoringServices.metricsServer
    // monitoringServices.kubernetesDashboard;

in allServices
