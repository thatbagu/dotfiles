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

  # Import all service configurations directly with the standard pattern
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

  # Create a list of all service attribute sets
  services = builtins.concatLists
    (map builtins.attrValues [ coreServices dnsServices ingressResources ]);

  # Combine them all with a single fold operation
  allServices = lib.recursiveMerge' services;

in allServices
