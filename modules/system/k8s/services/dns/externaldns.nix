{ pkgs, inputs, lib, vars }:

with lib;

let
  commonServiceAccountConfig = { create = true; };

  commonRbacConfig = {
    create = true;
    clusterRole = true;
    rules = [
      {
        apiGroups = [ "" ];
        resources = [ "services" "endpoints" "pods" ];
        verbs = [ "get" "watch" "list" ];
      }
      {
        apiGroups = [ "extensions" "networking.k8s.io" ];
        resources = [ "ingresses" ];
        verbs = [ "get" "watch" "list" ];
      }
      {
        apiGroups = [ "" ];
        resources = [ "nodes" ];
        verbs = [ "list" "watch" ];
      }
    ];
  };

  # Base configuration for all ExternalDNS instances
  externalDnsBase = {
    deploymentStrategy = { type = "Recreate"; };
    securityContext = { fsGroup = 65534; };
    sources = [ "service" "ingress" ];
    policy = "upsert-only";
    logLevel = "debug";
  };

  # Pi-hole specific configuration
  externalDnsPiholeConfig = overlayValues externalDnsBase {
    provider = "pihole";
    registry = "noop";
    serviceAccount = commonServiceAccountConfig // {
      name = "external-dns-pihole";
    };
    rbac = commonRbacConfig;
    env = [
      {
        name = "EXTERNAL_DNS_PIHOLE_SERVER";
        value = "http://${vars.piholeIp}";
      }
      {
        name = "EXTERNAL_DNS_PIHOLE_PASSWORD";
        valueFrom = {
          secretKeyRef = {
            name = "pihole-password";
            key = "password";
          };
        };
      }
    ];
    args = [
      "--source=service"
      "--source=ingress"
      "--provider=pihole"
      "--registry=noop"
      "--policy=upsert-only"
      "--log-level=debug"
    ];
    extraArgs = [ "--pihole-tls-skip-verify" "--txt-owner-id=k8s" ];
  };

  # Cloudflare specific configuration
  externalDnsCloudflareConfig = overlayValues externalDnsBase {
    provider = "cloudflare";
    registry = "txt";
    txtOwnerId = vars.domain;
    domainFilters = [ vars.domain ];
    cloudflare = { proxied = true; };
    serviceAccount = commonServiceAccountConfig // {
      name = "external-dns-cloudflare";
    };
    rbac = commonRbacConfig;
    env = [{
      name = "CF_API_TOKEN";
      valueFrom = {
        secretKeyRef = {
          name = "cloudflare-api-token";
          key = "api-token";
        };
      };
    }];
  };
in {
  # ExternalDNS for automatic DNS registration with Pi-hole
  externaldns-pihole = mkChart {
    name = "externaldns-pihole";
    chart = nixhelm.external-dns.external-dns;
    namespace = vars.namespaces.dns;
    values = externalDnsPiholeConfig;
  };

  # External DNS for Cloudflare integration
  externaldns-cloudflare = mkChart {
    name = "externaldns-cloudflare";
    chart = nixhelm.external-dns.external-dns;
    namespace = vars.namespaces.dns;
    values = externalDnsCloudflareConfig;
  };

  # Create a pihole password secret in dns-system namespace for reference
  pihole-password-dns = mkSecretRef {
    name = "pihole-password-dns";
    namespace = vars.namespaces.dns;
    secretName = "pihole-password";
    secretKey = "password";
    sopsSecretName = "pihole_password";
  };
}
