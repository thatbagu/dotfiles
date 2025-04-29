{ pkgs, inputs, lib, vars }:

with lib;

let
  metricsServerDefaults = {
    fullnameOverride = "metrics-server";
    args = [
      "--kubelet-insecure-tls"
      "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
    ];
    resources = {
      limits = {
        cpu = "100m";
        memory = "64Mi";
      };
      requests = {
        cpu = "20m";
        memory = "32Mi";
      };
    };
    # Ensures HPA works correctly
    apiService = { create = true; };
  };
in {
  metrics-server = mkChart {
    name = "metrics-server";
    chart = nixhelm.metrics-server.metrics-server;
    namespace = vars.namespaces.monitoring;
    values = metricsServerDefaults;
  };
}
