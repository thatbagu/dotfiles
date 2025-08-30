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

  # Custom values specific to this deployment
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

    # COMPLETELY DISABLE authentication for both web UI and API
    admin = {
      enabled = false; # Disable admin authentication
    };

    extraEnvVars = {
      FTLCONF_webserver_api_password =
        ""; # This is the CORRECT way to disable auth
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
  # Remove the pihole-secret since we don't need password authentication
  # pihole-secret = mkSecretRef { ... };  # Commented out

  # Pi-hole - Network-wide ad blocking
  pihole = mkChart {
    name = "pihole";
    chart = nixhelm.mojo2600.pihole;
    namespace = vars.namespaces.pihole;
    values = finalValues;
  };
}
