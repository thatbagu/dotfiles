{ pkgs, inputs, lib, vars }:

with lib;

let
  # Default values for Pi-hole
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

  # Custom values specific to this deployment - AVOIDING subPath mounts
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
    env = [
      {
        name = "WEBPASSWORD";
        valueFrom = {
          secretKeyRef = {
            name = "pihole-password";
            key = "password";
          };
        };
      }
      # Use environment variables instead of subPath mounts
      {
        name = "CUSTOM_HOSTS";
        value = ''
          ${vars.ipPools.pihole} pihole.home
          ${vars.ipPools.pihole} pihole.test
          ${vars.ipPools.pihole} pihole.${vars.domain}
        '';
      }
      {
        name = "PIHOLE_DNS_1";
        value = "192.168.1.1";
      }
      {
        name = "PIHOLE_DNS_2";
        value = "8.8.4.4";
      }
      {
        name = "TZ";
        value = "UTC";
      }
      # Add dnsmasq config via environment
      {
        name = "FTLCONF_dns_upstreams";
        value = "192.168.1.1;8.8.4.4";
      }
      {
        name = "FTLCONF_webserver_port";
        value = "80";
      }
      {
        name = "VIRTUAL_HOST";
        value = "pi.hole";
      }
      {
        name = "FTLCONF_misc_etc_dnsmasq_d";
        value = "true";
      }
      {
        name = "FTLCONF_webserver_api_password";
        valueFrom = {
          secretKeyRef = {
            name = "pihole-password";
            key = "password";
          };
        };
      }
    ];

    # # Simplified dnsmasq config without subPath issues
    # dnsmasq = {
    #   customDnsEntries = [
    #     # Point local domain to Pi-hole IP
    #     "address=/pihole.home/${vars.ipPools.pihole}"
    #   ];
    #   # Remove additionalHostsEntries to avoid subPath mounting
    #   # Instead use CUSTOM_HOSTS environment variable above
    # };
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
