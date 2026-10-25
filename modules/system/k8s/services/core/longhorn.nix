{ lib, charts, vars, ... }:

{
  # Longhorn - distributed storage. Manual sync only: a bad push must never
  # reach storage without someone pressing Sync.
  applications.longhorn = {
    namespace = vars.namespaces.longhorn;
    syncWave = 0;
    syncPolicy.autoSync = {
      enable = false;
      prune = false;
      selfHeal = false;
    };
    helm.releases.longhorn = {
      chart = charts.longhorn.longhorn;
      # Drop the chart's pre-delete uninstall Job so no Argo operation can ever
      # run it against live volumes.
      transformer = lib.filter (obj:
        !(obj.kind == "Job" && obj.metadata.name == "longhorn-uninstall"));
      values = {
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
    };
  };
}
