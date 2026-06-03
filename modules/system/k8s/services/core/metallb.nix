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

  # Main pool covering the full /26
  poolConfig = {
    apiVersion = "metallb.io/v1beta1";
    kind = "IPAddressPool";
    metadata = {
      name = "pool";
      namespace = vars.namespaces.metallb;
    };
    spec = { addresses = [ vars.ipPools.metallb ]; };
  };

  # Dedicated pool for signal-proxy so it gets its own L2Advertisement
  signalProxyPoolConfig = {
    apiVersion = "metallb.io/v1beta1";
    kind = "IPAddressPool";
    metadata = {
      name = "signal-proxy-pool";
      namespace = vars.namespaces.metallb;
    };
    spec = {
      addresses = [ "${vars.ipPools.signalProxy}/32" ];
      autoAssign = false;
    };
  };

  # L2Advertisement for the main pool
  l2AdvertisementConfig = {
    apiVersion = "metallb.io/v1beta1";
    kind = "L2Advertisement";
    metadata = {
      name = "pool";
      namespace = vars.namespaces.metallb;
    };
    spec = { ipAddressPools = [ "pool" ]; };
  };

  # Dedicated L2Advertisement for signal-proxy
  signalProxyL2Config = {
    apiVersion = "metallb.io/v1beta1";
    kind = "L2Advertisement";
    metadata = {
      name = "signal-proxy-l2";
      namespace = vars.namespaces.metallb;
    };
    spec = { ipAddressPools = [ "signal-proxy-pool" ]; };
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
    resources = [ poolConfig signalProxyPoolConfig l2AdvertisementConfig signalProxyL2Config ];
  };
}
