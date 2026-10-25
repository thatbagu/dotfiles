{ lib, charts, vars, ... }:

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

    admin = {
      enabled = false;
    };

    dnsmasq = {
      customDnsEntries = [
        # Point local domain to Pi-hole IP
        "address=/pihole.home/${vars.ipPools.pihole}"
        # VPN-only: nextcloud resolves to WireGuard caddy proxy for header-based auto-login
        "address=/nextcloud.${vars.domain}/10.0.100.1"
      ];
      additionalHostsEntries = [
        "${vars.ipPools.pihole} pihole.home"
        "${vars.ipPools.pihole} pihole.test"
        "${vars.ipPools.pihole} pihole.${vars.domain}"
      ];
    };
  };

  # Final values are the defaults merged with custom values
  finalValues = lib.recursiveUpdate piholeDefaults piholeValues;

in {
  # Pi-hole - network-wide ad blocking
  applications.pihole = {
    namespace = vars.namespaces.pihole;
    syncWave = 2;
    helm.releases.pihole = {
      chart = charts.mojo2600.pihole;
      values = finalValues;
    };
  };
}
