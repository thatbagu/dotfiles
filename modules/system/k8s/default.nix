{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.modules.k8s;
  charts = import ./charts.nix { inherit pkgs inputs; };
in {
  options.modules.k8s = { enable = mkEnableOption "k8s"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ kubectl kubernetes-helm ];

    system.activationScripts.kubernetes-deploy = ''

      export PATH=${pkgs.kubectl}/bin:$PATH

      # Directory to store rendered manifests
      mkdir -p /var/lib/kubernetes/manifests

      # Deploy charts
      ${concatStringsSep "\n" (mapAttrsToList (name: chart: ''
        echo "Deploying ${name}..."
        cp ${chart} /var/lib/kubernetes/manifests/${name}.yaml
        kubectl apply -f ${chart}
      '') charts)}
    '';
  };
}
