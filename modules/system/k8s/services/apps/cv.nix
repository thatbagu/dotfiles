{ vars, ... }:

let
  domain = "mlship.dev";
  namespace = vars.namespaces.cv;

  deploymentResource = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "cv";
      inherit namespace;
    };
    spec = {
      replicas = 2;
      selector.matchLabels.app = "cv";
      template = {
        metadata.labels.app = "cv";
        spec = {
          affinity = vars.workerAffinity;
          containers = [{
            name = "cv";
            image = "docker.io/thatbagu/website:latest";
            imagePullPolicy = "Always";
            ports = [{ containerPort = 80; }];
            resources = {
              requests = { cpu = "50m";  memory = "64Mi";  };
              limits   = { cpu = "500m"; memory = "512Mi"; };
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
      name = "cv";
      inherit namespace;
    };
    spec = {
      type = "ClusterIP";
      selector.app = "cv";
      ports = [{ port = 80; targetPort = 80; }];
    };
  };

  ingressResource = {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = "cv";
      inherit namespace;
      annotations = {
        "cert-manager.io/cluster-issuer" = vars.tls.defaultIssuer;
        "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
        "nginx.ingress.kubernetes.io/proxy-body-size" = "10m";
        # Let Cloudflare cache pages for 1 hour (s-maxage) and browsers for 5 min.
        # Cloudflare respects s-maxage when the domain is set to Proxied (orange cloud).
        # Override the upstream CSP to add 'unsafe-eval' — needed for Vue/React runtime
        # template compilation on page refresh.
        "nginx.ingress.kubernetes.io/configuration-snippet" = ''
          set $cc "public, max-age=300, s-maxage=3600";
          if ($http_hx_request = "true") { set $cc "no-store"; }
          add_header Cache-Control $cc always;
          add_header Vary "HX-Request" always;
          proxy_hide_header Content-Security-Policy;
          add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self' https://mastodon.social; frame-ancestors 'none';" always;
        '';
      };
    };
    spec = {
      ingressClassName = "nginx";
      tls = [{
        hosts = [ domain ];
        secretName = "cv-tls-cert";
      }];
      rules = [{
        host = domain;
        http.paths = [{
          path = "/";
          pathType = "Prefix";
          backend.service = {
            name = "cv";
            port.number = 80;
          };
        }];
      }];
    };
  };
  # Pod Security: no privileged / hostPath / hostNetwork pods in cv. Matters
  # because the CI deployer below may patch Deployments here.
  namespaceResource = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {
      name = namespace;
      labels = {
        "pod-security.kubernetes.io/enforce" = "baseline";
        "pod-security.kubernetes.io/enforce-version" = "latest";
        "pod-security.kubernetes.io/warn" = "restricted";
        "pod-security.kubernetes.io/audit" = "restricted";
      };
    };
  };

  # Least-privilege identity for the self-hosted GitHub runner: rollout
  # restart/status of the cv and cv-tui Deployments only.
  deployerResources = [
    {
      apiVersion = "v1";
      kind = "ServiceAccount";
      metadata = { name = "cv-deployer"; inherit namespace; };
    }
    {
      apiVersion = "v1";
      kind = "Secret";
      type = "kubernetes.io/service-account-token";
      metadata = {
        name = "cv-deployer-token";
        inherit namespace;
        annotations."kubernetes.io/service-account.name" = "cv-deployer";
      };
    }
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "Role";
      metadata = { name = "cv-deployer"; inherit namespace; };
      rules = [
        { apiGroups = [ "apps" ]; resources = [ "deployments" "replicasets" ]; verbs = [ "get" "list" "watch" ]; }
        { apiGroups = [ "apps" ]; resources = [ "deployments" ]; resourceNames = [ "cv" "cv-tui" ]; verbs = [ "patch" ]; }
      ];
    }
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "RoleBinding";
      metadata = { name = "cv-deployer"; inherit namespace; };
      roleRef = { apiGroup = "rbac.authorization.k8s.io"; kind = "Role"; name = "cv-deployer"; };
      subjects = [{ kind = "ServiceAccount"; name = "cv-deployer"; inherit namespace; }];
    }
  ];
in {
  applications.cv = {
    namespace = vars.namespaces.cv;
    syncWave = 4;
    yamls = map builtins.toJSON ([ namespaceResource deploymentResource serviceResource ingressResource ] ++ deployerResources);
  };
}
