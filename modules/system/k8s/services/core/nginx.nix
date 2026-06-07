{ pkgs, inputs, lib, vars }:

with lib;

let
  nginxValues = {
    controller = {
      service = {
        type = "LoadBalancer";
        loadBalancerIP = vars.ipPools.nginxExternal;
        externalTrafficPolicy = "Local";
        annotations = { "metallb.universe.tf/allow-shared-ip" = "nginx-svc"; };
      };

      # Increase resources slightly since we're handling both internal and external
      resources = {
        requests = {
          cpu = "200m";
          memory = "256Mi";
        };
        limits = {
          cpu = "1000m";
          memory = "1Gi";
        };
      };

      config = {
        # Performance settings
        "keep-alive" = "75";
        "keep-alive-requests" = "100";
        "proxy-body-size" = "50m";
        "server-tokens" = "false";

        # Security settings (will apply to all traffic, but can be overridden per ingress)
        "ssl-protocols" = "TLSv1.2 TLSv1.3";
        "ssl-ciphers" = "HIGH:!aNULL:!MD5";
        "use-forwarded-headers" = "true";
        "proxy-buffer-size" = "16k";
        "client-header-buffer-size" = "16k";
        "large-client-header-buffers" = "4 16k";
        "enable-ocsp" = "true";
        "hsts" = "true";
        "hsts-include-subdomains" = "true";
        "hsts-max-age" = "31536000";
        "allow-snippet-annotations" = "true";
        "annotations-risk-level" = "Critical";
      };

      ingressClassResource = {
        name = "nginx";
        enabled = true;
        default = true;
        controllerValue = "k8s.io/ingress-nginx";
        parameters = { };
      };

      ingressClass = "nginx";

      extraArgs = {
        "enable-ssl-passthrough" = "";
      };

      # Disable metrics to reduce overhead
      metrics = {
        enabled = false;
        serviceMonitor = { enabled = false; };
      };
    };
  };

in {
  # Single consolidated NGINX Ingress Controller
  ingress-nginx = mkChart {
    name = "ingress-nginx";
    chart = nixhelm.kubernetes-ingress-nginx.ingress-nginx;
    namespace = vars.namespaces.nginx;
    values = nginxValues;
  };
}
