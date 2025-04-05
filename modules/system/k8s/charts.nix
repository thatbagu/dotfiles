{ pkgs, inputs, ... }:

let
  nixhelm = inputs.nixhelm.charts { inherit pkgs; };
  kubelib = inputs.nix-kube-generators.lib { inherit pkgs; };

  mkChart = { name, namespace, chart, values ? { } }: {
    path = kubelib.buildHelmChart { inherit name chart namespace values; };
    inherit namespace;
    isSecret = false;
  };

  mkRawManifest = { name, namespace, resources }: {
    path = kubelib.toYAMLStreamFile resources;
    inherit namespace;
    isSecret = false;
  };

  mkSecretRef =
    { name, namespace, secretName, secretKey ? "password", sopsSecretName }: {
      inherit namespace name secretName secretKey sopsSecretName;
      isSecret = true;
    };

in {

  # Longhorn - Distributed storage for Kubernetes
  longhorn = mkChart {
    name = "longhorn";
    chart = nixhelm.longhorn.longhorn;
    namespace = "longhorn-system";
    values = {
      persistence = {
        defaultClass = true;
        defaultClassReplicaCount = 3;
      };
      defaultSettings = {
        createDefaultDiskLabeledNodes = true;
        defaultDataPath = "/var/lib/longhorn";
        backupstorePollInterval = 300; # Seconds between backup store polling

        # Replica settings
        replicaSoftAntiAffinity = true; # Try to avoid same node for replicas
        replicaAutoBalance = "best-effort"; # Balance replicas across nodes
      };
    };
  };

  # MetalLB - Load balancer for bare metal Kubernetes clusters
  metallb = mkChart {
    name = "metallb";
    chart = nixhelm.metallb.metallb;
    namespace = "metallb-system";
    values = { };
  };

  metallb-config = mkRawManifest {
    name = "metallb-config";
    namespace = "metallb-system";
    resources = [
      {
        apiVersion = "metallb.io/v1beta1";
        kind = "IPAddressPool";
        metadata = {
          name = "pool";
          namespace = "metallb-system";
        };
        spec = { addresses = [ "192.168.1.192/26" ]; };
      }
      {
        apiVersion = "metallb.io/v1beta1";
        kind = "L2Advertisement";
        metadata = {
          name = "pool";
          namespace = "metallb-system";
        };
        spec = { ipAddressPools = [ "pool" ]; };
      }
    ];
  };

  pihole-secret = mkSecretRef {
    name = "pihole-secret";
    namespace = "pihole-system";
    secretName = "pihole-secret"; # Changed to match the name
    sopsSecretName = "pihole_password";
  };

  # Pi-hole - Network-wide ad blocking
  pihole = mkChart {
    name = "pihole";
    chart = nixhelm.mojo2600.pihole;
    namespace = "pihole-system";
    values = {
      DNS1 = "192.168.1.1";
      persistentVolumeClaim = { enabled = true; };
      # Use SOPS-managed secret
      adminPassword = null;
      existingSecret = "pihole-secret"; # Changed to match secretName
      passwordKey = "password";

      ingress = {
        enabled = true;
        hosts = [ "pihole.home" ];
      };
      serviceWeb = {
        loadBalancerIP = "192.168.1.250";
        annotations = { "metallb.universe.tf/allow-shared-ip" = "pihole-svc"; };
        type = "LoadBalancer";
      };
      serviceDns = {
        loadBalancerIP = "192.168.1.250";
        annotations = { "metallb.universe.tf/allow-shared-ip" = "pihole-svc"; };
        type = "LoadBalancer";
      };
      replicaCount = 1;
    };
  };

  # NGINX Ingress Controller for internal network
  ingress-nginx-internal = mkChart {
    name = "ingress-nginx-internal";
    chart = nixhelm.kubernetes-ingress-nginx.ingress-nginx;
    namespace = "nginx-system";
    values = {
      controller = {
        ingressClassResource = {
          name = "nginx-internal";
          enabled = true;
          default = true;
          controllerValue = "k8s.io/ingress-nginx";
          parameters = { };
        };
        ingressClass = "nginx-internal";
      };
    };
  };

  # ExternalDNS for automatic DNS registration with Pi-hole
  externaldns-pihole = mkChart {
    name = "externaldns-pihole";
    chart = nixhelm.external-dns.external-dns;
    namespace = "pihole-system";
    values = {
      provider = "pihole";
      sources = [ "service" "ingress" ];
      registry = "noop"; # Pihole only supports A/AAAA/CNAME records
      policy = "upsert-only"; # Protect manually managed records
      # Service Account and RBAC configuration
      serviceAccount = {
        create = true;
        name = "external-dns";
      };
      rbac = {
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

      # Deployment specific settings
      deploymentStrategy = { type = "Recreate"; };

      securityContext = {
        fsGroup = 65534; # For ExternalDNS to read Kubernetes token files
      };

      env = [
        {
          name = "EXTERNAL_DNS_PIHOLE_PASSWORD";
          valueFrom = {
            secretKeyRef = {
              name = "pihole-secret";
              key = "password";
              optional = false;
            };
          };
        }
        {
          name = "EXTERNAL_DNS_PIHOLE_SERVER";
          value = "http://pihole-web.pihole-system.svc.cluster.local";
        }
      ];

      # Filter which ingress classes to watch
      ingressClassFilters = [ "nginx-internal" ];
    };
  };
}
