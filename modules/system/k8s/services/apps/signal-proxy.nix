{ pkgs, inputs, lib, vars }:

let
  configMapResource = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "signal-proxy-config";
      namespace = vars.namespaces.signalProxy;
    };
    # ssl_preread reads SNI without terminating TLS, then maps any SNI to
    # chat.signal.org:443. Signal app does cert pinning (not hostname
    # verification), so the TLS session with Signal's servers succeeds even
    # though the ClientHello carries our proxy hostname as SNI.
    data."nginx.conf" = ''
      error_log /dev/stderr info;

      events {
        worker_connections 4096;
      }

      stream {
        log_format proxy '$remote_addr [$time_local] $protocol $status '
                         '$bytes_sent $bytes_received $session_time '
                         '"$ssl_preread_server_name"';
        access_log /dev/stdout proxy;

        resolver 1.1.1.1 8.8.8.8 valid=300s;
        resolver_timeout 10s;

        map $ssl_preread_server_name $upstream {
          default "chat.signal.org:443";
        }

        server {
          listen 443;
          ssl_preread on;
          proxy_pass $upstream;
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
            volumeMounts = [{
              name = "config";
              mountPath = "/etc/nginx/nginx.conf";
              subPath = "nginx.conf";
            }];
            resources = {
              requests = { cpu = "10m"; memory = "16Mi"; };
              limits = { cpu = "100m"; memory = "64Mi"; };
            };
          }];
          volumes = [{
            name = "config";
            configMap.name = "signal-proxy-config";
          }];
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
      configMapResource
      deploymentResource
      serviceResource
      ingressResource
    ];
  };
}
