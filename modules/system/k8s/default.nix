# In modules/system/k8s/default.nix
{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.modules.k8s;
  charts = import ./charts.nix { inherit pkgs inputs; };

  # Filter charts to get only secret references
  secretRefs = filterAttrs (_: chart: chart.isSecret) charts;

  # Filter charts to get regular (non-secret) charts
  regularCharts = filterAttrs (_: chart: !chart.isSecret) charts;

  requiredNamespaces =
    unique (mapAttrsToList (_: chart: chart.namespace) charts);
in {
  options.modules.k8s = { enable = mkEnableOption "k8s"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ kubectl kubernetes-helm ];

    # Create manifest directory only
    system.activationScripts.kubernetes-prepare = ''
      mkdir -p /var/lib/kubernetes/manifests
      ${concatStringsSep "\n" (mapAttrsToList (name: chart: ''
        echo "Copying ${name} chart..."
        cp ${chart.path} /var/lib/kubernetes/manifests/${name}.yaml
      '') regularCharts)}
    '';

    # Deployment service
    systemd.services.k8s-deploy = {
      description = "Deploy Kubernetes resources";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ kubectl coreutils bash ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Wait for k3s API to be ready
        echo "Waiting for Kubernetes API to be ready..."
        KUBECONFIG=/etc/rancher/k3s/k3s.yaml
        export KUBECONFIG

        count=0
        max_attempts=30
        until kubectl get nodes &>/dev/null; do
          echo "Waiting for Kubernetes API... Attempt $count of $max_attempts"
          sleep 10
          count=$((count + 1))
          if [ $count -ge $max_attempts ]; then
            echo "Kubernetes API did not become available in time"
            exit 1
          fi
        done

        # Create required namespaces first
        echo "Creating namespaces: ${concatStringsSep ", " requiredNamespaces}"
        ${concatMapStringsSep "\n" (ns: ''
          kubectl get namespace ${ns} &>/dev/null || kubectl create namespace ${ns}
        '') requiredNamespaces}

        # Create secrets first from SOPS
        ${concatStringsSep "\n" (mapAttrsToList (name: secretRef: ''
          echo "Creating secret ${secretRef.secretName} in namespace ${secretRef.namespace}..."
          SECRET_VALUE=$(cat ${
            config.sops.secrets.${secretRef.sopsSecretName}.path
          })
          kubectl create secret generic ${secretRef.secretName} \
            -n ${secretRef.namespace} \
            --from-literal=${secretRef.secretKey}="$SECRET_VALUE" \
            --dry-run=client -o yaml | kubectl apply -f -
        '') secretRefs)}

        # Give a moment for the secrets to be fully stored
        sleep 2

        # Deploy regular charts
        ${concatStringsSep "\n" (mapAttrsToList (name: _: ''
          echo "Deploying ${name} to namespace ${
            regularCharts.${name}.namespace
          }..."
          kubectl apply -f /var/lib/kubernetes/manifests/${name}.yaml --validate=false
        '') regularCharts)}
      '';
    };
  };
}
