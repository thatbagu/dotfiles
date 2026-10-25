{ charts, vars, ... }:

let
  # Default values for MetalLB with monitoring removed
  metallbDefaults = {
    # Remove any Prometheus/serviceMonitor settings
    prometheus = {
      serviceMonitor = { enabled = false; };
      prometheusRule = { enabled = false; };
    };
    controller = {
      # Disable metrics reporting
      metrics = { enabled = false; };
    };
    speaker = {
      # Disable metrics reporting
      metrics = { enabled = false; };
    };
  };

  poolConfig = {
    apiVersion = "metallb.io/v1beta1";
    kind = "IPAddressPool";
    metadata = {
      name = "pool";
      namespace = vars.namespaces.metallb;
    };
    spec = { addresses = [ vars.ipPools.metallb ]; };
  };

  l2AdvertisementConfig = {
    apiVersion = "metallb.io/v1beta1";
    kind = "L2Advertisement";
    metadata = {
      name = "pool";
      namespace = vars.namespaces.metallb;
    };
    spec = { ipAddressPools = [ "pool" ]; };
  };
in {
  # MetalLB - load balancer for bare metal clusters
  applications.metallb = {
    namespace = vars.namespaces.metallb;
    syncWave = 0;
    helm.releases.metallb = {
      chart = charts.metallb.metallb;
      values = metallbDefaults;
    };
  };

  applications.metallb-config = {
    namespace = vars.namespaces.metallb;
    syncWave = 1;
    yamls = map builtins.toJSON [ poolConfig l2AdvertisementConfig ];
  };
}
