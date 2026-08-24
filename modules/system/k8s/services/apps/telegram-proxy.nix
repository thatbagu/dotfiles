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
            # in args so env vars expand before container start — no shell needed.
            # mtg v2 syntax: simple-run <bind-to> <secret> [flags]
            command = [ "/mtg" ];
            # fake-TLS secret = ee + raw-secret + hex("www.google.com")
            # mtg v2 simple-run only accepts ee-prefixed (fake-TLS) secrets and
            # requires a SNI hostname appended as hex bytes.
            args = [ "simple-run" "0.0.0.0:443" "ee$(MTP_SECRET)7777772e676f6f676c652e636f6d" ];
            ports = [{
              name = "mtproto";
              containerPort = 443;
              protocol = "TCP";
            }];
            env = [{
              name = "MTP_SECRET";
              valueFrom.secretKeyRef = {
                name = "telegram-proxy-secrets";
                key  = "secret";
              };
            }];
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

in {
  telegram-proxy = lib.mkRawManifest {
    name      = "telegram-proxy";
    inherit namespace;
    resources = [ deploymentResource serviceResource ];
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
