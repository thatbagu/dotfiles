{ pkgs, inputs, lib, vars }:

with lib;

let
  piholeDefaults = {
    image = {
      repository = "pihole/pihole";
      tag = vars.versions.pihole;
    };
    DNS1 = "192.168.1.1";
    persistentVolumeClaim = { enabled = true; };
    replicaCount = vars.defaultReplicas;
    # Remove monitoring settings
    monitoring = {
      enabled = false;
      serviceMonitor = { enabled = false; };
    };
  };

  # Custom values specific to this deployment - CORRECTED for mojo2600 chart
  piholeValues = {
    ingress = {
      enabled = true;
      hosts = [ "pihole.home" "pihole.test" ];
    };
    serviceWeb = {
      loadBalancerIP = vars.ipPools.pihole;
      annotations = { "metallb.universe.tf/allow-shared-ip" = "pihole-svc"; };
      type = "LoadBalancer";
    };
    serviceDns = {
      loadBalancerIP = vars.ipPools.pihole;
      annotations = { "metallb.universe.tf/allow-shared-ip" = "pihole-svc"; };
      type = "LoadBalancer";
    };

    # CORRECT way to configure password for mojo2600 chart
    admin = {
      enabled = true;
      existingSecret = "pihole-password";
      passwordKey = "password";
    };

    dnsmasq = {
      customDnsEntries = [
        # Point local domain to Pi-hole IP
        "address=/pihole.home/${vars.ipPools.pihole}"
      ];
      additionalHostsEntries = [
        "${vars.ipPools.pihole} pihole.home"
        "${vars.ipPools.pihole} pihole.test"
        "${vars.ipPools.pihole} pihole.${vars.domain}"
      ];
    };
  };

  # Final values are the defaults merged with custom values
  finalValues = overlayValues piholeDefaults piholeValues;
in {
  pihole-secret = mkSecretRef {
    name = "pihole-secret";
    namespace = vars.namespaces.pihole;
    secretName = "pihole-password";
    sopsSecretName = "pihole_password";
  };

  # Pi-hole - Network-wide ad blocking
  pihole = mkChart {
    name = "pihole";
    chart = nixhelm.mojo2600.pihole;
    namespace = vars.namespaces.pihole;
    values = finalValues;
  };
}
