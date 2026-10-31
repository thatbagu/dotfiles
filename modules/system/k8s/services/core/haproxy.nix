{ vars, ... }:

let
  namespace = vars.namespaces.nginx;

  configMap = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "haproxy-config";
      inherit namespace;
    };
    data."haproxy.cfg" = ''
      global
        maxconn 50000
        log stdout format raw local0

      defaults
        mode tcp
        log global
        option tcplog
        timeout connect 5s
        timeout client 120s
        timeout server 120s

      # Plain HTTP — forward to nginx (handles redirect to HTTPS).
      frontend f_http
        bind :80
        default_backend b_nginx_http

      # TLS — inspect SNI to demux fake-TLS MTProto from real HTTPS.
      # Route by domain: real HTTPS (SNI ends in .egor.house) goes to nginx;
      # everything else — including fake-TLS MTProto whose SNI HAProxy may not
      # parse correctly, or connections with SNI www.google.com — goes to telegram.
      # Keeping the accept rule so normal TLS is routed without the 5s delay;
      # non-TLS (or unparseable fake-TLS) falls through after the delay to telegram.
      frontend f_https
        bind :443
        tcp-request inspect-delay 5s
        tcp-request content accept if { req.ssl_hello_type 1 }
        use_backend b_nginx_https if { req.ssl_sni -m end .egor.house }
        use_backend b_nginx_https if { req.ssl_sni -m str egor.house }
        use_backend b_nginx_https if { req.ssl_sni -m str mlship.dev }
        use_backend b_nginx_https if { req.ssl_sni -m end .mlship.dev }
        default_backend b_telegram

      # Raw TCP passthrough for the SSH TUI (replaces nginx TCP configmap).
      frontend f_ssh
        bind :22
        default_backend b_cvtui

      backend b_nginx_http
        # PROXY protocol carries the real client IP to nginx (TCP mode loses it).
        server nginx ingress-nginx-controller.${namespace}.svc.cluster.local:80 send-proxy-v2

      backend b_nginx_https
        server nginx ingress-nginx-controller.${namespace}.svc.cluster.local:443 send-proxy-v2

      # Fake-TLS MTProto: send directly to mtg, bypassing nginx entirely.
      backend b_telegram
        server mtg telegram-proxy.${vars.namespaces.proxies}.svc.cluster.local:443

      backend b_cvtui
        server cvtui cv-tui.${vars.namespaces.cv}.svc.cluster.local:2222
    '';
  };

  deployment = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "haproxy";
      inherit namespace;
    };
    spec = {
      replicas = 1;
      selector.matchLabels.app = "haproxy";
      template = {
        metadata.labels.app = "haproxy";
        spec = {
          containers = [{
            name = "haproxy";
            image = "haproxy:3.0-alpine";
            ports = [
              { name = "http";    containerPort = 80;  protocol = "TCP"; }
              { name = "https";   containerPort = 443; protocol = "TCP"; }
              { name = "ssh-tui"; containerPort = 22;  protocol = "TCP"; }
            ];
            volumeMounts = [{
              name = "config";
              mountPath = "/usr/local/etc/haproxy";
              readOnly = true;
            }];
            resources = {
              requests = { cpu = "50m";  memory = "32Mi";  };
              limits   = { cpu = "500m"; memory = "128Mi"; };
            };
          }];
          volumes = [{
            name = "config";
            configMap.name = "haproxy-config";
          }];
        };
      };
    };
  };

  service = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "haproxy";
      inherit namespace;
    };
    spec = {
      type = "LoadBalancer";
      loadBalancerIP = vars.ipPools.nginxExternal;
      externalTrafficPolicy = "Local";
      selector.app = "haproxy";
      ports = [
        { name = "http";    port = 80;  targetPort = 80;  protocol = "TCP"; }
        { name = "https";   port = 443; targetPort = 443; protocol = "TCP"; }
        { name = "ssh-tui"; port = 22;  targetPort = 22;  protocol = "TCP"; }
      ];
    };
  };

in {
  applications.haproxy = {
    inherit namespace;
    syncWave = 2;
    yamls = map builtins.toJSON [ configMap deployment service ];
  };
}
