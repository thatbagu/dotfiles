{ pkgs, inputs, ... }:

let
  # Import lib.nix for helper functions but not variables
  lib = import ./lib.nix { inherit pkgs inputs; };

  # Centralized variables for all services - keeping close to original values
  vars = rec {
    domain = "egor.house";
    cloudflareEmail = "your-cloudflare-email@example.com";

    # Namespace definitions - keeping original namespaces
    namespaces = {
      dns = "dns-system";
      pihole = "pihole-system";
      nginx = "nginx-system";
      metallb = "metallb-system";
      longhorn = "longhorn-system";
    };

    # IP address pools - from original configuration
    ipPools = {
      metallb = "192.168.1.192/26";
      nginxExternal = "192.168.1.193";
      pihole = "192.168.1.250"; # Original Pi-hole IP
    };

    # References to make code cleaner (no duplication)
    piholeIp = ipPools.pihole;

    # Version control for images - from original configuration
    versions = {
      pihole = "2024.07.0"; # Original version from your config
    };

    # Common configuration 
    defaultReplicas = 1; # Original replicaCount

    # TLS configuration
    tls = {
      defaultIssuer = "letsencrypt-prod";
      stagingIssuer = "letsencrypt-staging";
      acmeServerProduction = "https://acme-v02.api.letsencrypt.org/directory";
      acmeServerStaging =
        "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
  };

  # Import all service configurations, passing the vars
  coreServices = {
    longhorn =
      import ./services/core/longhorn.nix { inherit pkgs inputs lib vars; };
    metallb =
      import ./services/core/metallb.nix { inherit pkgs inputs lib vars; };
    nginx = import ./services/core/nginx.nix { inherit pkgs inputs lib vars; };
  };

  dnsServices = {
    pihole = import ./services/dns/pihole.nix { inherit pkgs inputs lib vars; };
    externaldns =
      import ./services/dns/externaldns.nix { inherit pkgs inputs lib vars; };
    certManager =
      import ./services/dns/cert-manager.nix { inherit pkgs inputs lib vars; };
  };

  ingressResources = {
    ingress =
      import ./services/ingress/ingress.nix { inherit pkgs inputs lib vars; };
  };

  # Combine all services into a flat attribute set
  allServices = coreServices.longhorn // coreServices.metallb
    // coreServices.nginx // dnsServices.pihole // dnsServices.externaldns
    // dnsServices.certManager // ingressResources.ingress;

in allServices
