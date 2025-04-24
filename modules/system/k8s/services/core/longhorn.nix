{ pkgs, inputs, lib, vars }:

with lib;

let
  # Values for Longhorn
  longhornValues = {
    persistence = {
      defaultClass = true;
      defaultClassReplicaCount = 3;
    };
    defaultSettings = {
      createDefaultDiskLabeledNodes = true;
      defaultDataPath = "/var/lib/longhorn";
      backupstorePollInterval = 300;
      replicaSoftAntiAffinity = true;
      replicaAutoBalance = "best-effort";
    };
  };
in {
  # Longhorn - Distributed storage for Kubernetes
  longhorn = mkChart {
    name = "longhorn";
    chart = nixhelm.longhorn.longhorn;
    namespace = vars.namespaces.longhorn;
    values = longhornValues;
  };
}
