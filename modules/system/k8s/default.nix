{ config, lib, pkgs, ... }:

# Workloads are deployed by Argo CD from modules/system/k8s/manifests (see
# nixidy.nix). The only thing left on the host is pushing SOPS secrets into
# the cluster, since they must never go through git.
with lib;
let
  cfg = config.modules.k8s;
  secrets = import ./secrets.nix { inherit lib; };

  # One Kubernetes Secret per (namespace, secretName), holding all its keys.
  grouped = groupBy (s: "${s.namespace}/${s.secretName}") secrets;
  namespaces = unique (map (s: s.namespace) secrets);

  applySecret = entries:
    let first = head entries;
    in ''
      echo "Applying secret ${first.namespace}/${first.secretName}"
      kubectl create secret generic ${escapeShellArg first.secretName} \
        --namespace ${escapeShellArg first.namespace} \
        ${concatMapStringsSep " \\\n    " (s:
          "--from-file=${escapeShellArg s.secretKey}=${config.sops.secrets.${s.sopsSecretName}.path}")
        entries} \
        --dry-run=client -o yaml | kubectl apply -f -
    '';
in {
  options.modules.k8s.enable =
    mkEnableOption "pushing SOPS secrets into the k3s cluster";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ kubectl kubernetes-helm ];

    # Re-push when a secret's value changes.
    sops.secrets = genAttrs (unique (map (s: s.sopsSecretName) secrets))
      (_: { restartUnits = [ "k8s-secrets.service" ]; });

    systemd.services.k8s-secrets = {
      description = "Push SOPS secrets into Kubernetes";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.kubectl ];
      environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
      restartTriggers = [ (builtins.toJSON secrets) ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 30;
      };
      script = ''
        set -o pipefail

        until kubectl get --raw /readyz >/dev/null 2>&1; do
          echo "Waiting for the Kubernetes API..."
          sleep 5
        done

        ${concatMapStringsSep "\n" (ns: ''
          kubectl get namespace ${ns} >/dev/null 2>&1 || kubectl create namespace ${ns}
        '') namespaces}

        ${concatMapStringsSep "\n" applySecret (attrValues grouped)}
      '';
    };
  };
}
