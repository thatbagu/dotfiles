{ pkgs, inputs, lib, vars }:

let
  namespace = vars.namespaces.cv;

  deploymentResource = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = { name = "sslh"; inherit namespace; };
    spec = {
      replicas = 1;
      selector.matchLabels.app = "sslh";
      template = {
        metadata.labels.app = "sslh";
        spec.containers = [{
          name = "sslh";
          image = "ghcr.io/yrutschle/sslh:latest";
          args = [
            "--foreground"
            "--listen=0.0.0.0:443"
            "--ssh=cv-tui.cv.svc.cluster.local:2222"
            "--tls=ingress-nginx-controller.nginx-system.svc.cluster.local:443"
            "--on-timeout=ssh"
          ];
          ports = [{ containerPort = 443; protocol = "TCP"; }];
          resources = {
            requests = { cpu = "10m"; memory = "16Mi"; };
            limits   = { cpu = "100m"; memory = "64Mi"; };
          };
        }];
      };
    };
  };

  serviceResource = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "sslh";
      inherit namespace;
      annotations."metallb.universe.tf/allow-shared-ip" = "sslh-svc";
    };
    spec = {
      type = "LoadBalancer";
      loadBalancerIP = vars.ipPools.sslh;
      externalTrafficPolicy = "Cluster";
      selector.app = "sslh";
      ports = [{ name = "https"; port = 443; targetPort = 443; protocol = "TCP"; }];
    };
  };
in {
  sslh = lib.mkRawManifest {
    name = "sslh";
    inherit namespace;
    resources = [ deploymentResource serviceResource ];
  };
}
