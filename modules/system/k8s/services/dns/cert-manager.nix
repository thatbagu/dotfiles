{ pkgs, inputs, lib, vars }:

with lib;

let
  # Create a function to generate ACME issuers with shared config
  mkAcmeIssuer = { name, server }: {
    apiVersion = "cert-manager.io/v1";
    kind = "ClusterIssuer";
    metadata = { name = name; };
    spec = {
      acme = {
        server = server;
        email = vars.cloudflareEmail;
        privateKeySecretRef = { name = name; };
        solvers = [{
          dns01 = {
            cloudflare = {
              email = vars.cloudflareEmail;
              apiTokenSecretRef = {
                name = "cloudflare-api-token";
                key = "api-token";
              };
            };
          };
        }];
      };
    };
  };

  # Default values for cert-manager
  certManagerDefaults = {
    installCRDs = true;
    prometheus = { enabled = true; };
    resources = {
      requests = {
        cpu = "100m";
        memory = "128Mi";
      };
      limits = {
        cpu = "200m";
        memory = "256Mi";
      };
    };
    global = { leaderElection = { namespace = vars.namespaces.dns; }; };
  };

  # Custom values for cert-manager
  certManagerValues = {
    installCRDs = true;
    prometheus = {
      enabled = true;
      servicemonitor = {
        enabled = true;
        prometheusInstance = "default";
      };
    };
    startupapicheck = { timeout = "5m"; };
    webhook = { timeoutSeconds = 30; };
  };
in {
  # Cert-manager for TLS certificates
  cert-manager = mkChart {
    name = "cert-manager";
    chart = nixhelm.jetstack.cert-manager;
    namespace = vars.namespaces.dns;
    defaultValues = certManagerDefaults;
    values = certManagerValues;
  };

  # Cloudflare API token secret for DNS validation
  cloudflare-api-token-secret = mkSecretRef {
    name = "cloudflare-api-token-secret";
    namespace = vars.namespaces.dns;
    secretName = "cloudflare-api-token";
    secretKey = "api-token";
    sopsSecretName = "cloudflare_api_token";
  };

  # Cluster issuer for Let's Encrypt
  cert-manager-issuers = mkRawManifest {
    name = "cert-manager-issuers";
    namespace = vars.namespaces.dns;
    resources = [
      (mkAcmeIssuer {
        name = vars.tls.stagingIssuer;
        server = vars.tls.acmeServerStaging;
      })
      (mkAcmeIssuer {
        name = vars.tls.defaultIssuer;
        server = vars.tls.acmeServerProduction;
      })
    ];
  };
}
