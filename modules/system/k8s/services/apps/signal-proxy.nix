{ pkgs, inputs, lib, vars }:

let
  # cert-manager issues a Let's Encrypt cert for signal.egor.house via DNS-01.
  # Signal app verifies this cert normally (CA chain), not via pinning —
  # pinning only applies to Signal's own servers, not user-configured proxies.
  certificateResource = {
    apiVersion = "cert-manager.io/v1";
    kind = "Certificate";
    metadata = {
      name = "signal-proxy-tls";
      namespace = vars.namespaces.signalProxy;
    };
    spec = {
      dnsNames = [ "signal.${vars.domain}" ];
      secretName = "signal-proxy-tls";
      issuerRef = {
        kind = "ClusterIssuer";
        name = vars.tls.defaultIssuer;
      };
    };
  };

  configMapResource = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "signal-proxy-config";
      namespace = vars.namespaces.signalProxy;
    };
    # Terminates TLS from Signal app (presents signal.egor.house cert).
    # Re-encrypts upstream with SNI=chat.signal.org so Signal's server
    # returns the correct pinned certificate for its own domain.
    data."nginx.conf" = ''
      error_log /dev/stderr info;

      events {
        worker_connections 4096;
      }

      stream {
        log_format proxy '$remote_addr [$time_local] $protocol $status '
                         '$bytes_sent $bytes_received $session_time';
        access_log /dev/stdout proxy;

        resolver 1.1.1.1 8.8.8.8 valid=300s;
        resolver_timeout 10s;

        server {
          listen 443 ssl;
          ssl_certificate /etc/ssl/signal/tls.crt;
          ssl_certificate_key /etc/ssl/signal/tls.key;
          ssl_protocols TLSv1.2 TLSv1.3;

          set $upstream "chat.signal.org:443";
          proxy_pass $upstream;
          proxy_ssl on;
          proxy_ssl_server_name on;
          proxy_ssl_name "chat.signal.org";
          proxy_ssl_verify off;

          proxy_connect_timeout 30s;
          proxy_timeout 600s;
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
              name = "tcp";
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
                mountPath = "/etc/ssl/signal";
                readOnly = true;
              }
            ];
            resources = {
              requests = { cpu = "10m"; memory = "16Mi"; };
              limits = { cpu = "100m"; memory = "64Mi"; };
            };
          }];
          volumes = [
            { name = "config"; configMap.name = "signal-proxy-config"; }
            { name = "tls"; secret.secretName = "signal-proxy-tls"; }
          ];
        };
      };
    };
  };

  # ClusterIP — external access goes through nginx ingress ssl-passthrough
  serviceResource = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "signal-proxy";
      namespace = vars.namespaces.signalProxy;
    };
    spec = {
      type = "ClusterIP";
      selector.app = "signal-proxy";
      ports = [{
        name = "tcp";
        port = 443;
        targetPort = 443;
        protocol = "TCP";
      }];
    };
  };

  # nginx ingress passes raw TLS stream to signal-proxy based on SNI.
  # No TLS termination here — signal-proxy handles the forwarding.
  ingressResource = {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = "signal-proxy";
      namespace = vars.namespaces.signalProxy;
      annotations = {
        "nginx.ingress.kubernetes.io/ssl-passthrough" = "true";
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
