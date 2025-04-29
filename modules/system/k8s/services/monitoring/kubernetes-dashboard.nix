{ pkgs, inputs, lib, vars }:

with lib;

let
  dashboardDefaults = {
    fullnameOverride = "kubernetes-dashboard";
    protocolHttp = true;
    service = { externalPort = 80; };
    resources = {
      limits = {
        cpu = "100m";
        memory = "100Mi";
      };
      requests = {
        cpu = "50m";
        memory = "50Mi";
      };
    };
    ingress = {
      enabled = true;
      ingressClassName = "nginx-internal";
      hosts = [ "k8s.home" ];
    };
    extraArgs = [
      # Skip login for simpler use in homelab environment
      "--enable-skip-login"
      # Allow basic resources to be modified through the UI
      "--enable-resource-management"
      # Disable the built-in metrics scraper to reduce resources
      "--metrics-provider=none"
    ];
    # Security settings for homelab
    rbac = { clusterReadOnlyRole = true; };
    # Minimal settings for metrics-scraper
    metricsScraper = { enabled = false; };
  };
in {
  # Kubernetes Dashboard
  kubernetes-dashboard = mkChart {
    name = "kubernetes-dashboard";
    chart = nixhelm.kubernetes.dashboard;
    namespace = vars.namespaces.monitoring;
    values = dashboardDefaults;
  };
}
