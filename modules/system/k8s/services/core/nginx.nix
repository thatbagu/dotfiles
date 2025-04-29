{ pkgs, inputs, lib, vars }:

with lib;

let
  # Common defaults for all NGINX controllers
  nginxDefaults = {
    controller = {
      # Remove metrics section
      resources = {
        requests = {
          cpu = "100m";
          memory = "128Mi";
        };
        limits = {
          cpu = "500m";
          memory = "512Mi";
        };
      };
      config = {
        "keep-alive" = "75";
        "keep-alive-requests" = "100";
        "proxy-body-size" = "50m";
        "server-tokens" = "false";
        "ssl-protocols" = "TLSv1.2 TLSv1.3";
        "ssl-ciphers" = "HIGH:!aNULL:!MD5";
      };
    };
  };

  # External-specific NGINX controller settings
  externalNginxAdditions = {
    controller = {
      service = {
        type = "LoadBalancer";
        loadBalancerIP = vars.ipPools.nginxExternal;
        externalTrafficPolicy = "Local";
        annotations = {
          "metallb.universe.tf/allow-shared-ip" = "nginx-external-svc";
        };
      };
      config = {
        "use-forwarded-headers" = "true";
        "proxy-buffer-size" = "16k";
        "client-header-buffer-size" = "16k";
        "large-client-header-buffers" = "4 16k";
        "enable-ocsp" = "true";
        "hsts" = "true";
        "hsts-include-subdomains" = "true";
        "hsts-max-age" = "31536000";
      };
    };
  };

  # Common NGINX configuration generator with better defaults handling
  mkNginxIngress = { name, ingressClass, isDefault ? false, isExternal ? false
    , additionalValues ? { } }:
    let
      finalValues = overlayValues nginxDefaults (if isExternal then
        overlayValues externalNginxAdditions additionalValues
      else
        additionalValues);
    in mkChart {
      inherit name;
      chart = nixhelm.kubernetes-ingress-nginx.ingress-nginx;
      namespace = vars.namespaces.nginx;
      values = finalValues // {
        controller = finalValues.controller // {
          ingressClassResource = {
            name = ingressClass;
            enabled = true;
            default = isDefault;
            controllerValue =
              "k8s.io/ingress-nginx${if isExternal then "-external" else ""}";
            parameters = { };
          };
          ingressClass = ingressClass;
          # Remove Prometheus service monitors and metrics ports
          metrics = {
            enabled = false;
            serviceMonitor = { enabled = false; };
          };
        };
      };
    };
in {
  # NGINX Ingress Controller for internal network
  ingress-nginx-internal = mkNginxIngress {
    name = "ingress-nginx-internal";
    ingressClass = "nginx-internal";
    isDefault = true;
    isExternal = false;
    additionalValues = {
      controller = {
        config = {
          "ssl-redirect" = "false"; # Don't force SSL for internal traffic
        };
      };
    };
  };

  # NGINX Ingress Controller for external access
  ingress-nginx-external = mkNginxIngress {
    name = "ingress-nginx-external";
    ingressClass = "nginx-external";
    isDefault = false;
    isExternal = true;
    additionalValues = {
      controller = {
        config = {
          "whitelist-source-range" =
            "0.0.0.0/0"; # Can be restricted to specific IPs
          "ssl-redirect" =
            "true"; # Always redirect to HTTPS for external traffic
        };
      };
    };
  };
}
