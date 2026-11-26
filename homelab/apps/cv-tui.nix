# The CV site's terminal UI over SSH: the edge proxy forwards ports 22 and
# 2001 to it (vars.nix edge.tcp); the public one is
# `ssh -p 2001 ssh.mlship.dev`.
# Its host key comes from SOPS (extraSecrets in flake.nix). It's public, so it
# runs locked down: non-root on a read-only root, and a NetworkPolicy lets in
# only the edge proxy and lets out only DNS and HTTPS to the internet (the
# Mastodon feed).
{ nixlab, ... }:

let
  namespace = "cv";

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
          affinity = nixlab.preferWorkers;
          # The image would run as root; 65532 is distroless' "nonroot".
          securityContext = {
            runAsNonRoot = true;
            runAsUser = 65532;
            runAsGroup = 65532;
            fsGroup = 65532;
            seccompProfile.type = "RuntimeDefault";
          };
          containers = [{
            name = "cv-tui";
            image = "docker.io/thatbagu/cv-tui:latest";
            imagePullPolicy = "Always";
            ports = [{
              name = "ssh";
              containerPort = 2222;
              protocol = "TCP";
            }];
            securityContext = {
              allowPrivilegeEscalation = false;
              readOnlyRootFilesystem = true;
              capabilities.drop = [ "ALL" ];
            };
            volumeMounts = [
              {
                name = "ssh-host-key";
                mountPath = "/app/.ssh/cv_ssh_host_key";
                subPath = "cv_ssh_host_key";
                readOnly = true;
              }
              { name = "tmp"; mountPath = "/tmp"; }
            ];
            resources = {
              requests = { cpu = "50m"; memory = "64Mi"; };
              limits   = { cpu = "200m"; memory = "256Mi"; };
            };
          }];
          # From SOPS via k8s-secrets; no hostPath, so the namespace can
          # enforce Pod Security "baseline".
          volumes = [
            {
              name = "ssh-host-key";
              secret = {
                secretName = "cv-tui-ssh-host-key";
                defaultMode = 288; # 0440, readable through fsGroup
              };
            }
            { name = "tmp"; emptyDir.sizeLimit = "16Mi"; }
          ];
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
    # ClusterIP: external SSH reaches the TUI via the edge proxy (haproxy),
    # which dials cv-tui:2222.
    spec = {
      type         = "ClusterIP";
      selector.app = "cv-tui";
      ports = [
        {
          name       = "ssh";
          port       = 2222;
          targetPort = 2222;
          protocol   = "TCP";
        }
        {
          name       = "ssh-22";
          port       = 22;
          targetPort = 2222;
          protocol   = "TCP";
        }
      ];
    };
  };

  # In: only the edge proxy, on the SSH port. Out: DNS, and HTTPS to public
  # addresses only, so a compromised TUI can't reach the cluster or the LAN.
  networkPolicyResource = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      name = "cv-tui";
      inherit namespace;
    };
    spec = {
      podSelector.matchLabels.app = "cv-tui";
      policyTypes = [ "Ingress" "Egress" ];
      ingress = [{
        from = [{
          namespaceSelector.matchLabels."kubernetes.io/metadata.name" = "gateway-system";
          podSelector.matchLabels.app = "haproxy";
        }];
        ports = [{ port = 2222; protocol = "TCP"; }];
      }];
      egress = [
        {
          to = [{
            namespaceSelector.matchLabels."kubernetes.io/metadata.name" = "kube-system";
            podSelector.matchLabels.k8s-app = "kube-dns";
          }];
          ports = [
            { port = 53; protocol = "UDP"; }
            { port = 53; protocol = "TCP"; }
          ];
        }
        {
          to = [{
            ipBlock = {
              cidr = "0.0.0.0/0";
              except = [ "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" "100.64.0.0/10" "169.254.0.0/16" ];
            };
          }];
          ports = [{ port = 443; protocol = "TCP"; }];
        }
      ];
    };
  };
in {
  applications.cv-tui = {
    namespace = "cv";
    syncWave = 4;
    yamls = map builtins.toJSON [ deploymentResource serviceResource networkPolicyResource ];
  };
}
