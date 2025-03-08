{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.modules.k8s;
  charts = import ./charts.nix { inherit pkgs inputs; };

  requiredNamespaces =
    unique (mapAttrsToList (_: chart: chart.namespace) charts);
in {
  options.modules.k8s = { enable = mkEnableOption "k8s"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ kubectl kubernetes-helm ];

    # Create directory for manifests
    system.activationScripts.kubernetes-prepare = ''
      mkdir -p /var/lib/kubernetes/manifests
      ${concatStringsSep "\n" (mapAttrsToList (name: chart: ''
        echo "Copying ${name} chart..."
        cp ${chart.path} /var/lib/kubernetes/manifests/${name}.yaml
      '') charts)}
    '';

    # Create a systemd service that will run after k3s is up
    systemd.services.k8s-deploy = {
      description = "Deploy Kubernetes resources";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.kubectl ];

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

        # Deploy charts with validation disabled
        ${concatStringsSep "\n" (mapAttrsToList (name: chart: ''
          echo "Deploying ${name} to namespace ${chart.namespace}..."
          kubectl apply -f /var/lib/kubernetes/manifests/${name}.yaml --validate=false
        '') charts)}
      '';
    };
  };
}
