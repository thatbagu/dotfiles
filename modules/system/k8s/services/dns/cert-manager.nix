{ lib, charts, vars, ... }:

let
  # Create a function to generate ACME issuers with shared config
  mkAcmeIssuer = { name, server }: {
    apiVersion = "cert-manager.io/v1";
    kind = "ClusterIssuer";
    metadata = { inherit name; };
    spec = {
      acme = {
        inherit server;
        privateKeySecretRef = { inherit name; };
        solvers = [{
          dns01 = {
            cloudflare = {
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
  applications.cert-manager = {
    namespace = vars.namespaces.dns;
    syncWave = 2;
    helm.releases.cert-manager = {
      chart = charts.jetstack.cert-manager;
      values = lib.recursiveUpdate certManagerDefaults certManagerValues;
    };
  };

  # Let's Encrypt cluster issuers (DNS-01 via Cloudflare)
  applications.cert-manager-issuers = {
    namespace = vars.namespaces.dns;
    syncWave = 3;
    yamls = map builtins.toJSON [
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
