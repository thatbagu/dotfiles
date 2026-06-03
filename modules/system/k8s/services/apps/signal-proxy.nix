{ pkgs, inputs, lib, vars }:

let
  configMapResource = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "signal-proxy-config";
      namespace = vars.namespaces.signalProxy;
    };
    data."nginx.conf" = ''
      error_log /dev/stderr info;

      events {}

      stream {
        log_format proxy '$remote_addr [$time_local] $protocol $status '
                         '$bytes_sent $bytes_received $session_time '
                         '"$ssl_preread_server_name"';
        access_log /dev/stdout proxy;

        resolver 1.1.1.1 8.8.8.8 valid=300s;
        resolver_timeout 10s;

        server {
          listen 443;
          ssl_preread on;
          proxy_pass $ssl_preread_server_name:443;
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

  serviceResource = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "signal-proxy";
      namespace = vars.namespaces.signalProxy;
      annotations = {
        "metallb.universe.tf/allow-shared-ip" = "signal-proxy-svc";
      };
    };
    spec = {
      type = "LoadBalancer";
      loadBalancerIP = vars.ipPools.signalProxy;
      selector.app = "signal-proxy";
      ports = [{
        name = "tcp";
        port = 443;
        targetPort = 443;
        protocol = "TCP";
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
    ];
  };
}
