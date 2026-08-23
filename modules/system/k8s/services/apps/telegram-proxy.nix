{ pkgs, inputs, lib, vars }:

let
  namespace = vars.namespaces.proxies;

  deploymentResource = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "telegram-proxy";
      inherit namespace;
    };
    spec = {
      replicas = 1;
      selector.matchLabels.app = "telegram-proxy";
      template = {
        metadata.labels.app = "telegram-proxy";
        spec = {
          containers = [{
            name = "telegram-proxy";
            # mtg (Go) doesn't do a startup DC handshake probe like seriyps does,
            # so it works cleanly behind k8s NAT. Fake-TLS via ee-prefixed secret.
            image = "ghcr.io/9seconds/mtg:2";
            # mtg is a scratch image (no shell). Use k8s $(VAR) substitution
            # in args so the env vars expand before container start — no shell needed.
            command = [ "/mtg" ];
            args = [ "simple-run" "--bind" "0.0.0.0:443" "--tag" "$(MTP_TAG)" "ee$(MTP_SECRET)" ];
            ports = [{
              name = "mtproto";
              containerPort = 443;
              protocol = "TCP";
            }];
            env = [
              {
                name = "MTP_SECRET";
                valueFrom.secretKeyRef = {
                  name = "telegram-proxy-secrets";
                  key  = "secret";
                };
              }
              {
                name = "MTP_TAG";
                valueFrom.secretKeyRef = {
                  name = "telegram-proxy-secrets";
                  key  = "tag";
                };
              }
            ];
            resources = {
              requests = { cpu = "10m";  memory = "16Mi";  };
              limits   = { cpu = "200m"; memory = "64Mi"; };
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
      name = "telegram-proxy";
      inherit namespace;
    };
    spec = {
      type = "ClusterIP";
      selector.app = "telegram-proxy";
      ports = [{
        name       = "mtproto";
        port       = 443;
        targetPort = 443;
        protocol   = "TCP";
      }];
    };
  };

  # nginx reads the SNI from the fake-TLS ClientHello and routes to this pod.
  # The proxy handles the full fake-TLS handshake itself — no cert needed here.
  ingressResource = {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = "telegram-proxy";
      inherit namespace;
      annotations = {
        "nginx.ingress.kubernetes.io/ssl-passthrough" = "true";
      };
    };
    spec = {
      ingressClassName = "nginx";
      rules = [{
        host = "telegram.${vars.domain}";
        http.paths = [{
          path     = "/";
          pathType = "Prefix";
          backend.service = {
            name = "telegram-proxy";
            port.number = 443;
          };
        }];
      }];
    };
  };
in {
  telegram-proxy = lib.mkRawManifest {
    name      = "telegram-proxy";
    inherit namespace;
    resources = [ deploymentResource serviceResource ingressResource ];
  };

  telegram-proxy-secret = lib.mkSecretRef {
    name           = "telegram-proxy-secret";
    inherit namespace;
    secretName     = "telegram-proxy-secrets";
    secretKey      = "secret";
    sopsSecretName = "telegram_proxy_secret";
  };

  telegram-proxy-tag = lib.mkSecretRef {
    name           = "telegram-proxy-tag";
    inherit namespace;
    secretName     = "telegram-proxy-secrets";
    secretKey      = "tag";
    sopsSecretName = "telegram_proxy_tag";
  };
}
