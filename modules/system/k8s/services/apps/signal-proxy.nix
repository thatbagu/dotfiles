{ pkgs, inputs, lib, vars }:

let
  certificateResource = {
    apiVersion = "cert-manager.io/v1";
    kind = "Certificate";
    metadata = {
      name = "signal-proxy-tls";
      namespace = vars.namespaces.signalProxy;
    };
    spec = {
      secretName = "signal-proxy-tls";
      issuerRef = {
        name = "letsencrypt-prod";
        kind = "ClusterIssuer";
      };
      dnsNames = [ "signal.${vars.domain}" ];
    };
  };

  configMapResource = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "signal-proxy-config";
      namespace = vars.namespaces.signalProxy;
    };
    data."nginx.conf" = ''
      events { worker_connections 1024; }

      http {
        server {
          listen 443 ssl;

          ssl_certificate     /etc/nginx/ssl/tls.crt;
          ssl_certificate_key /etc/nginx/ssl/tls.key;
          ssl_protocols       TLSv1.2 TLSv1.3;
          ssl_ciphers         HIGH:!aNULL:!MD5;

          location / {
            proxy_pass https://textsecure-service.whispersystems.org;
            proxy_ssl_server_name on;
            proxy_set_header Host textsecure-service.whispersystems.org;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_read_timeout 3600;
            proxy_send_timeout 3600;
            proxy_buffering off;
          }
        }
      }
    '';
  };

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
            image = "nginx:stable-alpine";
            ports = [{
              name = "https";
              containerPort = 443;
              protocol = "TCP";
            }];
            volumeMounts = [
              {
                name = "config";
                mountPath = "/etc/nginx/nginx.conf";
                subPath = "nginx.conf";
              }
              {
                name = "tls";
                mountPath = "/etc/nginx/ssl";
                readOnly = true;
              }
            ];
            resources = {
              requests = { cpu = "50m"; memory = "64Mi"; };
              limits = { cpu = "200m"; memory = "128Mi"; };
            };
          }];
          volumes = [
            {
              name = "config";
              configMap.name = "signal-proxy-config";
            }
            {
              name = "tls";
              secret.secretName = "signal-proxy-tls";
            }
          ];
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
    resources = [
      certificateResource
      configMapResource
      deploymentResource
      serviceResource
      ingressResource
    ];
  };
}
