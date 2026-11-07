# Kubernetes Secrets for the homelab's own apps, pushed from SOPS by nixlab's
# k8s-secrets unit (extraSecrets in flake.nix). The leading "_" keeps nixlab
# from loading this file as an app.
[
  # SSH host key of the cv TUI.
  {
    namespace = "cv";
    secretName = "cv-tui-ssh-host-key";
    secretKey = "cv_ssh_host_key";
    sopsSecretName = "cv_tui_ssh_host_key";
  }
]
