# GitHub Actions Runner Controller (ARC): runs self-hosted GitHub Actions
# runners as pods, one fresh pod per job (see cv-runner.nix for the runners).
# The charts come from ARC's repository at a pinned release.
{ pkgs, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "actions";
    repo = "actions-runner-controller";
    rev = "gha-runner-scale-set-0.15.1";
    hash = "sha256-kkwWr/LpD9ggMGye+aeBgHUWWM9aV2os3fYAVgG/J2Y=";
  };
in
{
  _module.args.arcCharts = {
    controller = "${src}/charts/gha-runner-scale-set-controller";
    scaleSet = "${src}/charts/gha-runner-scale-set";
  };

  applications.arc = {
    namespace = "arc-systems";
    syncWave = 3;
    # ARC's CRDs are too big for client-side apply's annotation.
    syncPolicy.syncOptions.serverSideApply = true;
    helm.releases.arc = {
      chart = "${src}/charts/gha-runner-scale-set-controller";
      values = {
        image = {
          repository = "ghcr.io/actions/gha-runner-scale-set-controller";
          tag = "0.15.1@sha256:4b51a20db717b194e2f3fa96cfe2ddcb21602811f79053c75fd1a383517b9f90";
        };
      };
    };
  };
}
