{ pkgs, inputs, lib, vars }:

let
  deploymentResource = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "signal-proxy";
      namespace = vars.namespaces.signalProxy;
    };
    spec = {
      replicas = 1;
      selector.matchLabels.app = "signal-proxy";
      template = {
        metadata.labels.app = "signal-proxy";
        spec = {
          containers = [{
            name = "signal-proxy";
            image = "signalapp/proxy:latest";
            ports = [{
              name = "https";
              containerPort = 443;
              protocol = "TCP";
            }];
            resources = {
              requests = { cpu = "50m"; memory = "64Mi"; };
              limits = { cpu = "200m"; memory = "128Mi"; };
            };
          }];
        };
      };
    };
  };

  serviceResource = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "signal-proxy";
      namespace = vars.namespaces.signalProxy;
    };
    spec = {
      selector.app = "signal-proxy";
      ports = [{
        name = "https";
        port = 443;
        targetPort = 443;
        protocol = "TCP";
      }];
    };
  };

  ingressResource = {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = "signal-proxy";
      namespace = vars.namespaces.signalProxy;
      annotations = {
        "nginx.ingress.kubernetes.io/ssl-passthrough" = "true";
        "external-dns.alpha.kubernetes.io/hostname" = "signal.${vars.domain}";
        "external-dns.alpha.kubernetes.io/cloudflare-proxied" = "false";
        "external-dns.alpha.kubernetes.io/ttl" = "120";
      };
    };
    spec = {
      ingressClassName = "nginx";
      rules = [{
        host = "signal.${vars.domain}";
        http.paths = [{
          path = "/";
          pathType = "Prefix";
          backend.service = {
            name = "signal-proxy";
            port.number = 443;
          };
        }];
      }];
    };
  };
in {
  signal-proxy = lib.mkRawManifest {
    name = "signal-proxy";
    namespace = vars.namespaces.signalProxy;
    resources = [ deploymentResource serviceResource ingressResource ];
  };
}
