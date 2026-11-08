# Self-hosted GitHub Actions runners for github.com/thatbagu/cv (workflows use
# `runs-on: cv-runner`). ARC (arc.nix) starts a fresh pod per job, so nothing
# persists between jobs, and none run while idle.
# - Images are built by a rootless BuildKit sidecar (no privileged pod, no
#   Docker daemon); workflows point buildx at tcp://127.0.0.1:1234.
# - The runner's ServiceAccount may only restart the cv and cv-tui
#   Deployments (rollout restart/status); kubectl uses it directly.
# - The registration token is github_token, from SOPS (extraSecrets).
{ arcCharts, ... }:

let
  namespace = "arc-runners";

  # Rootless BuildKit wants unconfined seccomp and AppArmor, which baseline
  # Pod Security forbids, hence its own namespace. Nothing here is privileged.
  namespaceResource = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {
      name = namespace;
      labels = {
        "pod-security.kubernetes.io/enforce" = "privileged";
        "pod-security.kubernetes.io/warn" = "baseline";
      };
    };
  };

  serviceAccount = {
    apiVersion = "v1";
    kind = "ServiceAccount";
    metadata = { name = "cv-runner"; inherit namespace; };
  };

  # Deploying cv: watch Deployments, restart only cv and cv-tui.
  role = {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "Role";
    metadata = { name = "cv-deployer"; namespace = "cv"; };
    rules = [
      { apiGroups = [ "apps" ]; resources = [ "deployments" "replicasets" ]; verbs = [ "get" "list" "watch" ]; }
      { apiGroups = [ "apps" ]; resources = [ "deployments" ]; resourceNames = [ "cv" "cv-tui" ]; verbs = [ "patch" ]; }
    ];
  };
  roleBinding = {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "RoleBinding";
    metadata = { name = "cv-deployer"; namespace = "cv"; };
    roleRef = { apiGroup = "rbac.authorization.k8s.io"; kind = "Role"; name = "cv-deployer"; };
    subjects = [{ kind = "ServiceAccount"; name = "cv-runner"; inherit namespace; }];
  };
in
{
  applications.cv-runner = {
    inherit namespace;
    syncWave = 4;
    yamls = map builtins.toJSON [ namespaceResource serviceAccount role roleBinding ];
    helm.releases.cv-runner = {
      chart = arcCharts.scaleSet;
      values = {
        githubConfigUrl = "https://github.com/thatbagu/cv";
        githubConfigSecret = "arc-github";
        runnerScaleSetName = "cv-runner";
        minRunners = 0;
        maxRunners = 2;
        # Rendered offline, so the chart can't look the controller up.
        controllerServiceAccount = { namespace = "arc-systems"; name = "arc-gha-rs-controller"; };
        template.spec = {
          serviceAccountName = "cv-runner";
          # BuildKit as a native sidecar: it stops when the job's runner exits.
          initContainers = [{
            name = "buildkitd";
            image = "docker.io/moby/buildkit:v0.34.2-rootless@sha256:c8252268760e1baba80780d63d738ef9f260fb7c7c0973c78494cb9ddd99eda1";
            restartPolicy = "Always";
            args = [ "--addr" "tcp://127.0.0.1:1234" "--oci-worker-no-process-sandbox" ];
            securityContext = {
              runAsUser = 1000;
              runAsGroup = 1000;
              seccompProfile.type = "Unconfined";
              appArmorProfile.type = "Unconfined";
            };
            volumeMounts = [{ name = "buildkit"; mountPath = "/home/user/.local/share/buildkit"; }];
          }];
          containers = [{
            name = "runner";
            image = "ghcr.io/actions/actions-runner:2.338.2@sha256:759a1d94a15b05941aba5196974ff43fe15b4cbba29b694b35cbc32a1166b232";
            command = [ "/home/runner/run.sh" ];
            resources = {
              requests = { cpu = "100m"; memory = "256Mi"; };
              limits.memory = "4Gi";
            };
          }];
          volumes = [{ name = "buildkit"; emptyDir = { }; }];
        };
      };
    };
  };
}
