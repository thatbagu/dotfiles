# Homelab-only Kubernetes settings, merged into nixlab's `vars` by the
# modules in apps/ (nixlab doesn't know about these apps).
{
  namespaces = {
    cv = "cv";
    proxies = "proxies";
  };
  ipPools.sslh = "192.168.1.195";

  # Prefer scheduling app pods on worker nodes so meowth stays free for
  # control-plane work (preferred, not required: pods still schedule on
  # meowth if the workers are unavailable).
  workerAffinity = {
    nodeAffinity = {
      preferredDuringSchedulingIgnoredDuringExecution = [{
        weight = 100;
        preference.matchExpressions = [{
          key = "node-role";
          operator = "In";
          values = [ "worker" ];
        }];
      }];
    };
  };
}
