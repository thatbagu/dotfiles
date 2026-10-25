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
  # deploymentGroups ordering). `auto` apps are auto-synced with self-heal and
  # prune;
  # the rest wait for a manual sync (longhorn stays manual on purpose).
  apps = {
    metallb        = { charts = [ "metallb" ];        wave = 0; auto = true; };
    longhorn       = { charts = [ "longhorn" ];       wave = 0; };
    metallb-config = { charts = [ "metallb-config" ]; wave = 1; auto = true; };

    ingress-nginx  = { charts = [ "ingress-nginx" ];  wave = 2; auto = true; };
    pihole         = { charts = [ "pihole" ];         wave = 2; auto = true; };
    haproxy        = { charts = [ "haproxy" ];        wave = 2; auto = true; };
    cert-manager   = { charts = [ "cert-manager" ];   wave = 2; auto = true; };

    externaldns-pihole      = { charts = [ "externaldns-pihole" ];      wave = 3; auto = true; };
    externaldns-cloudflare  = { charts = [ "externaldns-cloudflare" ];  wave = 3; auto = true; };
    cert-manager-issuers    = { charts = [ "cert-manager-issuers" ];    wave = 3; auto = true; };
    cloudflare-ddns         = { charts = [ "cloudflare-ddns" ];         wave = 3; auto = true; };
    pihole-external-ingress = { charts = [ "pihole-external-ingress" ]; wave = 3; auto = true; };

    wireguard = {
      charts = [
        "wireguard-config"
        "wireguard-caddy-cert"
        "wireguard-storage"
        "wireguard-deployment"
        "wireguard-service"
      ];
      wave = 4;
      auto = true;
    };
    signal-proxy   = { charts = [ "signal-proxy" ];   wave = 4; auto = true; };
    telegram-proxy = { charts = [ "telegram-proxy" ]; wave = 4; auto = true; };
    nextcloud      = { charts = [ "nextcloud" ];      wave = 4; auto = true; };
    cv             = { charts = [ "cv" ];             wave = 4; auto = true; };
    cv-tui         = { charts = [ "cv-tui" ];         wave = 4; auto = true; };
    sslh           = { charts = [ "sslh" ];           wave = 4; auto = true; };
  };

  mappedCharts = lib.concatMap (app: app.charts) (lib.attrValues apps);
  unmappedCharts = lib.subtractLists mappedCharts (lib.attrNames regularCharts);
in {
  # Never let Argo delete storage, CRDs (would cascade to every CR) or
  # namespaces, whether by pruning or by deleting an Application.
  nixidy.objectTransforms.protect-stateful = {
    match.kind = [ "PersistentVolumeClaim" "CustomResourceDefinition" "Namespace" ];
    update.metadata.annotations."argocd.argoproj.io/sync-options" = "Prune=false,Delete=false";
  };

  nixidy.target = {
    repository = "https://github.com/thatbagu/dotfiles.git";
    branch = "main";
    rootPath = "./modules/system/k8s/manifests";
  };

  applications = lib.mapAttrs (name: app: {
    namespace = regularCharts.${lib.head app.charts}.namespace;
    annotations."argocd.argoproj.io/sync-wave" = toString app.wave;
    syncPolicy = {
      autoSync = lib.mkIf (app.auto or false) {
        enable = true;
        selfHeal = true;
        prune = true;
      };
      syncOptions = {
        createNamespace = true;
        pruneLast = true;
      };
    };
    yamls = map (chart: builtins.readFile regularCharts.${chart}.path) app.charts;
  }) (lib.throwIf (unmappedCharts != [ ])
    "nixidy.nix: charts not assigned to an application: ${toString unmappedCharts}"
    apps);
}
