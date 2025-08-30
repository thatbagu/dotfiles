# Updated modules/system/k8s/services/ingress/ingress.nix
{ pkgs, inputs, lib, vars }:

with lib;

let
  # Function to create a standard TLS ingress with modern spec
  mkTlsIngress = { name, namespace, host, serviceName, servicePort ? 80
    , annotations ? { } }: {
      apiVersion = "networking.k8s.io/v1";
      kind = "Ingress";
      metadata = {
        name = name;
        namespace = namespace;
        annotations = {
          # Remove the ingress class annotation completely
          "cert-manager.io/cluster-issuer" = vars.tls.defaultIssuer;
          "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
          "nginx.ingress.kubernetes.io/proxy-body-size" = "50m";
          "external-dns.alpha.kubernetes.io/hostname" = host;
          "external-dns.alpha.kubernetes.io/ttl" = "120";
        } // annotations;
      };
      spec = {
        # Use the modern ingressClassName field instead of annotation
        ingressClassName = "nginx";
        tls = [{
          hosts = [ host ];
          secretName = "${name}-tls-cert";
        }];
        rules = [{
          host = host;
          http = {
            paths = [{
              path = "/";
              pathType = "Prefix";
              backend = {
                service = {
                  name = serviceName;
                  port = { number = servicePort; };
                };
              };
            }];
          };
        }];
      };
    };

  # Pi-hole ingress configuration
  piholeIngressConfig = mkTlsIngress {
    name = "pihole-external";
    namespace = vars.namespaces.pihole;
    host = "pihole.${vars.domain}";
    serviceName = "pihole-web";
    servicePort = 80;
    annotations = {
      # "nginx.ingress.kubernetes.io/auth-type" = "basic";
      # "nginx.ingress.kubernetes.io/auth-secret" = "pihole-basic-auth";
      # "nginx.ingress.kubernetes.io/auth-realm" = "Authentication Required";
    };
  };
in {
  # Pi-hole external ingress with TLS
  pihole-external-ingress = mkRawManifest {
    name = "pihole-external-ingress";
    namespace = vars.namespaces.pihole;
    resources = [ piholeIngressConfig ];
  };
}
