{ pkgs, inputs, lib, vars }:

# SSH TUI for mlship.dev — connect with: ssh mlship.dev (port 22 via nginx TCP proxy)
#
# One-time setup before first deploy:
#   ssh-keygen -t ed25519 -f cv_ssh_host_key -N ""
#   sops modules/system/sops/secrets.yaml   # add cv_tui_ssh_host_key: | <private key>
#   colmena apply

let
  namespace = vars.namespaces.cv;

  deploymentResource = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "cv-tui";
      inherit namespace;
    };
    spec = {
      replicas = 1;
      selector.matchLabels.app = "cv-tui";
      template = {
        metadata.labels.app = "cv-tui";
        spec = {
          containers = [{
            name = "cv-tui";
            image = "docker.io/thatbagu/cv-tui:latest";
            imagePullPolicy = "Always";
            ports = [{
              name = "ssh";
              containerPort = 2222;
              protocol = "TCP";
            }];
            volumeMounts = [{
              name = "ssh-host-key";
              mountPath = "/app/.ssh";
              readOnly = true;
            }];
            resources = {
              requests = { cpu = "50m"; memory = "64Mi"; };
              limits   = { cpu = "200m"; memory = "256Mi"; };
            };
          }];
          volumes = [{
            name = "ssh-host-key";
            secret = {
              secretName  = "cv-tui-ssh-host-key";
              defaultMode = 384; # 0600
              items = [{
                key  = "host-key";
                path = "cv_ssh_host_key";
              }];
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
      name = "cv-tui";
      inherit namespace;
    };
    spec = {
      type     = "ClusterIP";
      selector.app = "cv-tui";
      ports = [{
        name       = "ssh";
        port       = 2222;
        targetPort = 2222;
        protocol   = "TCP";
      }];
    };
  };
in {
  cv-tui = lib.mkRawManifest {
    name      = "cv-tui";
    inherit namespace;
    resources = [ deploymentResource serviceResource ];
  };

  cv-tui-ssh-host-key = lib.mkSecretRef {
    name           = "cv-tui-ssh-host-key";
    inherit namespace;
    secretName     = "cv-tui-ssh-host-key";
    secretKey      = "host-key";
    sopsSecretName = "cv_tui_ssh_host_key";
  };
}
