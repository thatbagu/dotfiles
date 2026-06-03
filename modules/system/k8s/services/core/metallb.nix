{ pkgs, inputs, lib, vars }:

with lib;

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
  # MetalLB - Load balancer for bare metal Kubernetes clusters
  metallb = mkChart {
    name = "metallb";
    chart = nixhelm.metallb.metallb;
    namespace = vars.namespaces.metallb;
    values = metallbDefaults;
  };

  metallb-config = mkRawManifest {
    name = "metallb-config";
    namespace = vars.namespaces.metallb;
    resources = [ poolConfig l2AdvertisementConfig ];
  };
}
