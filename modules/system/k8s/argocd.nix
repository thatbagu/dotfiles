{ charts, ... }:

# Argo CD, managed by itself once bootstrapped. Kept lean: meowth's SSD
# struggles with etcd load, so no dex/notifications/applicationset, and every
# component prefers worker nodes.
let
  preferWorkers = {
    nodeAffinity = {
      type = "soft";
      matchExpressions = [{
        key = "node-role";
        operator = "In";
        values = [ "worker" ];
      }];
    };
  };
in {
  applications.argocd = {
    namespace = "argocd";
    createNamespace = true;
    annotations."argocd.argoproj.io/sync-wave" = "-1";

    helm.releases.argocd = {
      chart = charts.argoproj.argo-cd;
      values = {
        global.affinity = preferWorkers;

        dex.enabled = false;
        notifications.enabled = false;
        applicationSet.enabled = false;

        configs = {
          cm = {
            # Track ownership via annotation so charts' own
            # app.kubernetes.io/instance labels don't confuse Argo.
            "application.resourceTrackingMethod" = "annotation";

            # Report Application health so sync waves on child apps are
            # respected by the app-of-apps (Argo removed this by default).
            "resource.customizations.health.argoproj.io_Application" = ''
              hs = {}
              hs.status = "Progressing"
              hs.message = ""
              if obj.status ~= nil and obj.status.health ~= nil then
                hs.status = obj.status.health.status
                if obj.status.health.message ~= nil then
                  hs.message = obj.status.health.message
                end
              end
              return hs
            '';

            # Check git every 3 min (default) but don't hammer the API with
            # frequent full resyncs.
            "timeout.reconciliation" = "180s";
          };
          params = {
            # Fewer concurrent operations = gentler on etcd.
            "controller.status.processors" = 10;
            "controller.operation.processors" = 5;
          };
        };
      };
    };
  };
}
