{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.modules.k8s;
  charts = import ./charts.nix { inherit pkgs inputs; };

  # Filter charts to get only secret references
  secretRefs = filterAttrs (_: chart: chart.isSecret) charts;

  # Filter charts to get regular (non-secret) charts
  regularCharts = filterAttrs (_: chart: !chart.isSecret) charts;

  # Define deployment groups with dependencies and order
  deploymentGroups = [
    {
      name = "core-infrastructure";
      charts = [ "longhorn" "metallb" ];
      waitFor = { # Wait for these resources to be ready before proceeding
        metallb = {
          kind = "deployment";
          name = "metallb-controller";
          namespace = "metallb-system";
          timeout = 120; # seconds
        };
        longhorn = {
          kind = "deployment";
          name = "longhorn-driver-deployer";
          namespace = "longhorn-system";
          timeout = 180;
        };
      };
    }
    {
      name = "core-config";
      charts = [ "metallb-config" ];
      dependsOn = [ "core-infrastructure" ];
      retryAttempts = 5;
      retryDelay = 30; # seconds between retries
    }
    {
      name = "dns-services";
      charts = [ "external-dns" ];
      dependsOn = [ "core-config" ];
      waitFor = {
        externaldns = {
          kind = "deployment";
          name = "external-dns";
          namespace = "external-dns";
          timeout = 120;
        };
      };
    }
    {
      name = "applications";
      charts = [ "ingress-nginx-internal" "pihole" ];
      dependsOn = [ "core-config" ];
      waitFor = {
        nginx = {
          kind = "deployment";
          name = "ingress-nginx-internal-controller";
          namespace = "nginx-system";
          timeout = 180;
        };
      };
    }
  ];

  requiredNamespaces =
    unique (mapAttrsToList (_: chart: chart.namespace) charts);

  # Generate the deployment script for a group
  generateDeployScript = group: ''
    echo "Deploying group: ${group.name}"

    ${optionalString (group ? dependsOn) ''
      # Check if dependent groups completed successfully
      ${concatMapStringsSep "\n" (dep: ''
        if [ ! -f "/var/lib/kubernetes/.deploy-${dep}-done" ]; then
          echo "Dependent group ${dep} has not completed successfully. Aborting."
          exit 1
        fi
      '') group.dependsOn}
    ''}

    # Deploy charts in this group
    ${concatMapStringsSep "\n" (chartName: ''
      echo "Deploying ${chartName} to namespace ${
        regularCharts.${chartName}.namespace
      }..."

      retries=${toString (group.retryAttempts or 3)}
      delay=${toString (group.retryDelay or 10)}
      success=false

      for i in $(seq 1 $retries); do
        echo "Attempt $i of $retries for ${chartName}..."
        if kubectl apply -f /var/lib/kubernetes/manifests/${chartName}.yaml --validate=false; then
          success=true
          break
        else
          echo "Failed to deploy ${chartName}, waiting $delay seconds before retry..."
          sleep $delay
        fi
      done

      if [ "$success" != "true" ]; then
        echo "Failed to deploy ${chartName} after $retries attempts"
        exit 1
      fi
    '') group.charts}

    # Wait for resources if specified
    ${optionalString (group ? waitFor) (concatStringsSep "\n" (mapAttrsToList
      (resourceName: resource: ''
        echo "Waiting for ${resource.kind} ${resource.name} in namespace ${resource.namespace} to be ready..."

        kubectl wait --for=condition=Available --timeout=${
          toString (resource.timeout or 120)
        }s ${resource.kind}/${resource.name} -n ${resource.namespace} || {
          echo "Timed out waiting for ${resource.kind}/${resource.name} to be ready"
          # Continue anyway but warn
          echo "WARNING: Resource not ready, but continuing..."
        }
      '') group.waitFor))}

    # Mark this group as done
    touch /var/lib/kubernetes/.deploy-${group.name}-done
    echo "Group ${group.name} completed successfully"
  '';
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
        Restart = "on-failure";
        RestartSec = "30s";
      };

      script = ''
        # Clear previous deployment state
        rm -f /var/lib/kubernetes/.deploy-*-done

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
        sleep 5

        # Deploy each group in sequence
        ${concatMapStringsSep "\n\n" generateDeployScript deploymentGroups}

        echo "All deployments completed successfully!"
      '';
    };
  };
}
