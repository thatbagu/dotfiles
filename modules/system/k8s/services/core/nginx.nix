{ pkgs, inputs, lib, vars }:

with lib;

let
  nginxValues = {
    controller = {
      service = {
        # ClusterIP: haproxy (192.168.1.193) is now the external entrypoint and
        # proxies to nginx internally, so nginx does not need a LoadBalancer IP.
        type = "ClusterIP";
        ports       = { http = 80; https = 443; };
        targetPorts = { http = "http"; https = "https"; };
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

      # Report haproxy's LB IP in Ingress status instead of nginx's ClusterIP,
      # so external-dns (pihole) publishes an address LAN clients can reach.
      publishService.enabled = false;

      extraArgs = {
        "enable-ssl-passthrough" = "";
        "publish-status-address" = vars.ipPools.nginxExternal;
      };

      # Disable metrics to reduce overhead
      metrics = {
        enabled = false;
        serviceMonitor = { enabled = false; };
      };
    };
  };

in {
  ingress-nginx = mkChart {
    name = "ingress-nginx";
    chart = nixhelm.kubernetes-ingress-nginx.ingress-nginx;
    namespace = vars.namespaces.nginx;
    values = nginxValues;
  };
}
