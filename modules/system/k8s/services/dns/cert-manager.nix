{ pkgs, inputs, lib, vars }:

with lib;

let
  # Create a function to generate ACME issuers with shared config
  mkAcmeIssuer = { name, server }: {
    apiVersion = "cert-manager.io/v1";
    kind = "ClusterIssuer";
    metadata = { inherit name; };
    spec = {
      acme = {
        inherit server;
        emailSecretRef = {
          name = "cloudflare-email";
          key = "email";
        };
        privateKeySecretRef = { inherit name; };
        solvers = [{
          dns01 = {
            cloudflare = {
              emailSecretRef = {
                name = "cloudflare-email";
                key = "email";
              };
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

  # Default values for cert-manager with monitoring removed
  certManagerDefaults = {
    installCRDs = true;
    prometheus = { enabled = false; };
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
      enabled = false;
      servicemonitor = { enabled = false; };
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
    sopsSecretName = "cloudflare_token";
  };

  cloudflare-email-secret = mkSecretRef {
    name = "cloudflare-email-secret";
    namespace = vars.namespaces.dns;
    secretName = "cloudflare-email";
    secretKey = "email";
    sopsSecretName = "cloudflare_email";
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
