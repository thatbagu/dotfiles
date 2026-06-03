{ pkgs, inputs, lib, vars }:

let
  configMapResource = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "signal-proxy-config";
      namespace = vars.namespaces.signalProxy;
    };
    data."haproxy.cfg" = ''
      global
        log stdout format raw local0 info
        maxconn 10000

      defaults
        mode tcp
        log global
        option tcplog
        timeout connect 10s
        timeout client 1m
        timeout server 1m

      resolvers dns
        nameserver cloudflare 1.1.1.1:53
        nameserver google 8.8.8.8:53
        resolve_retries 3
        timeout resolve 1s
        timeout retry 1s
        accepted_payload_size 8192

      frontend signal_in
        bind :443
        default_backend textsecure

      backend textsecure
        server textsecure chat.signal.org:443 resolvers dns resolve-prefer ipv4 check inter 30s
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
            image = "haproxy:2.8-alpine";
            ports = [{
              name = "tcp";
              containerPort = 443;
              protocol = "TCP";
            }];
            volumeMounts = [{
              name = "config";
              mountPath = "/usr/local/etc/haproxy/haproxy.cfg";
              subPath = "haproxy.cfg";
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
