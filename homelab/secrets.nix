# Kubernetes Secrets for the homelab-only apps, pushed from SOPS by nixlab's
# k8s-secrets unit (extraSecrets in flake.nix).
let vars = import ./k8s-vars.nix; in
[
  # SSH host key of the cv TUI.
  {
    namespace = vars.namespaces.cv;
    secretName = "cv-tui-ssh-host-key";
    secretKey = "cv_ssh_host_key";
    sopsSecretName = "cv_tui_ssh_host_key";
  }
  {
    namespace = vars.namespaces.proxies;
    secretName = "telegram-proxy-secrets";
    secretKey = "secret";
    sopsSecretName = "telegram_proxy_secret";
  }
  {
    namespace = vars.namespaces.proxies;
    secretName = "telegram-proxy-secrets";
    secretKey = "tag";
    sopsSecretName = "telegram_proxy_tag";
  }
]
