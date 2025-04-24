{ pkgs, input{ pkgs, inputs, ... }:

let
  # Import lib.nix for helper functions but not variables
  lib = import ./lib.nix { inherit pkgs inputs; };

  # Centralized variables for all services
  vars = rec {
    domain = "egor.house";
    cloudflareEmail = "austos243@gmail.com";
    
    # Namespace definitions
    namespaces = {
      dns = "dns-system";
      pihole = "pihole-system";
      nginx = "nginx-system";
      metallb = "metallb-system";
      longhorn = "longhorn-system";
    };
    
    # IP address pools - notice how we can reference other variables
    ipPools = {
      metallb = "192.168.1.192/26";
      nginxExternal = "192.168.1.193";
      pihole = "192.168.1.250";
    };
    
    # References to make code cleaner (no duplication)
    piholeIp = ipPools.pihole;
    
    # Version control for images
    versions = {
      pihole = "2024.07.0";
      certManager = "v1.14.1";
      externaldns = "0.14.0";
    };
    
    # Common configuration patterns
    defaultReplicas = 1;
    defaultTimeout = 180; # seconds
    shortTimeout = 120; # seconds
    
    # TLS configuration
    tls = {
      defaultIssuer = "letsencrypt-prod";
      stagingIssuer = "letsencrypt-staging";
      acmeServerProduction = "https://acme-v02.api.letsencrypt.org/directory";
      acmeServerStaging = "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
  };

  # Import all service configurations, passing the vars
  coreServices = {
    longhorn = import ./services/core/longhorn.nix { inherit pkgs inputs lib vars; };
    metallb = import ./services/core/metallb.nix { inherit pkgs inputs lib vars; };
    nginx = import ./services/core/nginx.nix { inherit pkgs inputs lib vars; };
  };

  dnsServices = {
    pihole = import ./services/dns/pihole.nix { inherit pkgs inputs lib vars; };
    externaldns = import ./services/dns/externaldns.nix { inherit pkgs inputs lib vars; };
    certManager = import ./services/dns/cert-manager.nix { inherit pkgs inputs lib vars; };
  };

  ingressResources = {
    ingress = import ./services/ingress/ingress.nix { inherit pkgs inputs lib vars; };
  };

  # Combine all services into a flat attribute set
  allServices = 
    coreServices.longhorn //
    coreServices.metallb //
    coreServices.nginx //
    dnsServices.pihole //
    dnsServices.externaldns //
    dnsServices.certManager //
    ingressResources.ingress;

in allServices
