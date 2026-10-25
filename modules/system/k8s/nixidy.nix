{ lib, ... }:

# nixidy environment for the homelab cluster. Each service module defines its
# own `applications.<name>`.
#
# On every push to main, .github/workflows/k8s-render.yml renders this env and
# commits the YAML to the `k8s-rendered` branch, which Argo CD syncs from.
# Preview locally with: nix run github:arnarg/nixidy/v0.23.1 -- build .#homelab
{
  imports = [
    ./argocd.nix
    ./services/core/longhorn.nix
    ./services/core/metallb.nix
    ./services/core/nginx.nix
    ./services/core/haproxy.nix
    ./services/dns/pihole.nix
    ./services/dns/externaldns.nix
    ./services/dns/cert-manager.nix
    ./services/dns/ddns.nix
    ./services/ingress/ingress.nix
    ./services/vpn/wireguard.nix
    ./services/apps/signal-proxy.nix
    ./services/apps/telegram-proxy.nix
    ./services/apps/nextcloud.nix
    ./services/apps/cv.nix
    ./services/apps/cv-tui.nix
    ./services/apps/sslh.nix
  ];

  _module.args.vars = import ./vars.nix;

  # Extend every application with a sync wave and homelab defaults.
  nixidy.applicationImports = [
    ({ config, lib, ... }: {
      options.syncWave = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Argo CD sync wave of the Application within the app-of-apps.";
      };
      config = {
        annotations."argocd.argoproj.io/sync-wave" = toString config.syncWave;
        syncPolicy.syncOptions = {
          createNamespace = lib.mkDefault true;
          pruneLast = lib.mkDefault true;
        };
      };
    })
  ];

  nixidy.target = {
    repository = "https://github.com/thatbagu/dotfiles.git";
    branch = "k8s-rendered";
    rootPath = "./";
  };

  # Every app auto-syncs, self-heals and prunes unless it opts out.
  nixidy.defaults.syncPolicy.autoSync = {
    enable = true;
    selfHeal = true;
    prune = true;
  };

  # Never let Argo delete storage, CRDs (would cascade to every CR) or
  # namespaces, whether by pruning or by deleting an Application.
  # Appends to existing sync-options (e.g. ServerSideApply=true on large CRDs).
  nixidy.objectTransforms.protect-stateful = {
    match.kind = [ "PersistentVolumeClaim" "CustomResourceDefinition" "Namespace" ];
    update = obj:
      let
        key = "argocd.argoproj.io/sync-options";
        existing = obj.metadata.annotations.${key} or "";
        options = lib.filter (o: o != "") (lib.splitString "," existing)
          ++ [ "Prune=false" "Delete=false" ];
      in {
        metadata.annotations.${key} = lib.concatStringsSep "," (lib.unique options);
      };
  };
}
