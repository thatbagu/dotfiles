{ lib, pkgs, inputs, ... }:

# nixidy environment for the homelab cluster.
#
# Migration stage 1: every Argo CD application is fed the exact YAML the
# existing mkChart/mkRawManifest helpers render, so Argo adopts what's already
# live without changing it. Services get ported to native nixidy one by one.
let
  charts = import ./charts.nix { inherit pkgs inputs; config = null; };
  regularCharts = lib.filterAttrs (_: chart: !chart.isSecret) charts;

  # Argo application -> charts it's built from + sync wave (replaces the old
  # deploymentGroups ordering). `manual` apps never auto-sync.
  apps = {
    metallb        = { charts = [ "metallb" ];        wave = 0; };
    longhorn       = { charts = [ "longhorn" ];       wave = 0; manual = true; };
    metallb-config = { charts = [ "metallb-config" ]; wave = 1; };

    ingress-nginx  = { charts = [ "ingress-nginx" ];  wave = 2; };
    pihole         = { charts = [ "pihole" ];         wave = 2; };
    haproxy        = { charts = [ "haproxy" ];        wave = 2; };
    cert-manager   = { charts = [ "cert-manager" ];   wave = 2; };

    externaldns-pihole      = { charts = [ "externaldns-pihole" ];      wave = 3; };
    externaldns-cloudflare  = { charts = [ "externaldns-cloudflare" ];  wave = 3; };
    cert-manager-issuers    = { charts = [ "cert-manager-issuers" ];    wave = 3; };
    cloudflare-ddns         = { charts = [ "cloudflare-ddns" ];         wave = 3; };
    pihole-external-ingress = { charts = [ "pihole-external-ingress" ]; wave = 3; };

    wireguard = {
      charts = [
        "wireguard-config"
        "wireguard-caddy-cert"
        "wireguard-storage"
        "wireguard-deployment"
        "wireguard-service"
      ];
      wave = 4;
    };
    signal-proxy   = { charts = [ "signal-proxy" ];   wave = 4; };
    telegram-proxy = { charts = [ "telegram-proxy" ]; wave = 4; };
    nextcloud      = { charts = [ "nextcloud" ];      wave = 4; };
    cv             = { charts = [ "cv" ];             wave = 4; };
    cv-tui         = { charts = [ "cv-tui" ];         wave = 4; };
    sslh           = { charts = [ "sslh" ];           wave = 4; };
  };

  mappedCharts = lib.concatMap (app: app.charts) (lib.attrValues apps);
  unmappedCharts = lib.subtractLists mappedCharts (lib.attrNames regularCharts);
in {
  nixidy.target = {
    repository = "https://github.com/thatbagu/dotfiles.git";
    branch = "main";
    rootPath = "./modules/system/k8s/manifests";
  };

  applications = lib.mapAttrs (name: app: {
    namespace = regularCharts.${lib.head app.charts}.namespace;
    annotations."argocd.argoproj.io/sync-wave" = toString app.wave;
    yamls = map (chart: builtins.readFile regularCharts.${chart}.path) app.charts;
  }) (lib.throwIf (unmappedCharts != [ ])
    "nixidy.nix: charts not assigned to an application: ${toString unmappedCharts}"
    apps);
}
