{ lib }:

# Kubernetes Secrets pushed from SOPS by the k8s-secrets unit on the master.
# They never go through git/Argo CD. Entries targeting the same secretName are
# merged key by key.
let
  vars = import ./vars.nix;
  users = (import ./services/vpn/users.nix { inherit lib; config = null; }).wireguardUsers;
  enabledUsers = lib.filterAttrs (_: user: user.enabled) users;
in
[
  {
    namespace = vars.namespaces.dns;
    secretName = "cloudflare-api-token";
    secretKey = "api-token";
    sopsSecretName = "cloudflare_token";
  }

  {
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-admin";
    secretKey = "password";
    sopsSecretName = "nextcloud_admin_password";
  }
  {
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-admin";
    secretKey = "nextcloud-username";
    sopsSecretName = "nextcloud_admin_username";
  }
  {
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-db";
    secretKey = "password";
    sopsSecretName = "nextcloud_db_password";
  }
  {
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-db";
    secretKey = "db-username";
    sopsSecretName = "nextcloud_db_username";
  }
  # VPN SSO shared secret: Caddy (wireguard ns) sends it, Nextcloud checks it.
  {
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-sso";
    secretKey = "secret";
    sopsSecretName = "nextcloud_sso_secret";
  }
  {
    namespace = vars.namespaces.wireguard;
    secretName = "wireguard-secrets";
    secretKey = "nextcloud-sso-secret";
    sopsSecretName = "nextcloud_sso_secret";
  }
  {
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-redis";
    secretKey = "password";
    sopsSecretName = "nextcloud_redis_password";
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

  {
    namespace = vars.namespaces.wireguard;
    secretName = "wireguard-secrets";
    secretKey = "server-public-key";
    sopsSecretName = "wireguard_server_public_key";
  }
  {
    namespace = vars.namespaces.wireguard;
    secretName = "wireguard-secrets";
    secretKey = "wg-server-endpoint";
    sopsSecretName = "wireguard_server_endpoint";
  }
  {
    namespace = vars.namespaces.wireguard;
    secretName = "wireguard-secrets";
    secretKey = "server-private-key";
    sopsSecretName = "wireguard_server_private_key";
  }
]
# WireGuard peers' public keys (private keys stay on the clients).
++ lib.mapAttrsToList (_: user: {
  namespace = vars.namespaces.wireguard;
  secretName = "wireguard-secrets";
  secretKey = user.publicKeySecret;
  sopsSecretName = user.publicKeySecret;
}) enabledUsers
