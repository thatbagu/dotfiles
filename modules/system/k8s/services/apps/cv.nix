{ pkgs, inputs, lib, vars }:

let
  domain = "mlship.dev";
  namespace = vars.namespaces.cv;

  deploymentResource = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "cv";
      inherit namespace;
    };
    spec = {
      replicas = 2;
      selector.matchLabels.app = "cv";
      template = {
        metadata.labels.app = "cv";
        spec = {
          affinity = vars.workerAffinity;
          containers = [{
            name = "cv";
            image = "docker.io/thatbagu/website:latest";
            imagePullPolicy = "Always";
            ports = [{ containerPort = 80; }];
            resources = {
              requests = { cpu = "50m";  memory = "64Mi";  };
              limits   = { cpu = "500m"; memory = "512Mi"; };
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
      name = "cv";
      inherit namespace;
    };
    spec = {
      type = "ClusterIP";
      selector.app = "cv";
      ports = [{ port = 80; targetPort = 80; }];
    };
  };

  ingressResource = {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = "cv";
      inherit namespace;
      annotations = {
        "cert-manager.io/cluster-issuer" = vars.tls.defaultIssuer;
        "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
        "nginx.ingress.kubernetes.io/proxy-body-size" = "10m";
        # Let Cloudflare cache pages for 1 hour (s-maxage) and browsers for 5 min.
        # Cloudflare respects s-maxage when the domain is set to Proxied (orange cloud).
        "nginx.ingress.kubernetes.io/configuration-snippet" = ''
          add_header Cache-Control "public, max-age=300, s-maxage=3600" always;
        '';
      };
    };
    spec = {
      ingressClassName = "nginx";
      tls = [{
        hosts = [ domain ];
        secretName = "cv-tls-cert";
      }];
      rules = [{
        host = domain;
        http.paths = [{
          path = "/";
          pathType = "Prefix";
          backend.service = {
            name = "cv";
            port.number = 80;
          };
        }];
      }];
    };
  };
in {
  cv = lib.mkRawManifest {
    name = "cv";
    namespace = vars.namespaces.cv;
    resources = [ deploymentResource serviceResource ingressResource ];
  };
}
