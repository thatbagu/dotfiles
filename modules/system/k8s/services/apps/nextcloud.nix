{ charts, vars, ... }:

let
  nextcloudValues = {
    nextcloud = {
      host = "nextcloud.${vars.domain}";
      username = "admin";
      existingSecret = {
        enabled = true;
        secretName = "nextcloud-admin";
        passwordKey = "password";
      };
      # VPN SSO: user_saml in environment-variable mode reads REMOTE_USER, which
      # Apache sets from the X-Remote-User header Caddy injects per VPN client
      # IP (see vpn/wireguard.nix). Runs as www-data on every start; no-op once
      # configured.
      hooks.before-starting = ''
        #!/bin/sh
        set -e
        occ() { php /var/www/html/occ "$@"; }
        if occ saml:config:get --providerId=1 2>/dev/null | grep -q 'general-uid_mapping: REMOTE_USER'; then
          echo "VPN SSO already configured"
          exit 0
        fi
        echo "Configuring user_saml for VPN header auth..."
        occ app:install user_saml 2>/dev/null || occ app:enable user_saml
        occ config:app:set user_saml type --value=environment-variable
        occ config:app:set user_saml general-require_provisioned_account --value=0
        # HTTP_* vars are rejected by saml:config:set; .htaccess bridges the
        # header into REMOTE_USER instead.
        occ saml:config:set 1 --general-uid_mapping=REMOTE_USER
        occ saml:config:set 1 --general-idp0_display_name=VPN-SSO
      '';

      configs = {
        "proxy.config.php" = ''
          <?php
          $CONFIG = array(
            'trusted_proxies' => ['10.42.0.0/16'],
            'forwarded_for_headers' => ['HTTP_X_FORWARDED_FOR'],
            'overwriteprotocol' => 'https',
          );
        '';
      };
    };

    # Patch .htaccess on every pod start so mod_rewrite sets REMOTE_USER from
    # the X-Remote-User header Caddy injects per VPN client IP.
    # user_saml reads $_SERVER['REMOTE_USER'] to auto-login without a password.
    lifecycle.postStartCommand = [
      "/bin/sh"
      "-c"
      "grep -q 'X-Remote-User' /var/www/html/.htaccess || sed -i '/RewriteEngine on/a\\    RewriteRule ^ - [E=REMOTE_USER:%{HTTP:X-Remote-User}]' /var/www/html/.htaccess"
    ];

    internalDatabase.enabled = false;

    externalDatabase = {
      enabled = true;
      type = "postgresql";
      host = "nextcloud-postgresql";
      database = "nextcloud";
      username = "nextcloud";
      existingSecret = {
        enabled = true;
        secretName = "nextcloud-db";
        passwordKey = "password";
      };
    };

    postgresql = {
      enabled = true;
      global.postgresql.auth = {
        username = "nextcloud";
        database = "nextcloud";
        existingSecret = "nextcloud-db";
        secretKeys.userPasswordKey = "password";
      };
      primary.persistence = {
        enabled = true;
        storageClass = "longhorn";
        size = "8Gi";
      };
    };

    redis = {
      enabled = true;
      auth = {
        enabled = true;
        existingSecret = "nextcloud-redis";
        existingSecretPasswordKey = "password";
      };
    };

    persistence = {
      enabled = true;
      storageClass = "longhorn";
      size = "100Gi";
    };

    ingress = {
      enabled = true;
      className = "nginx";
      annotations = {
        "nginx.ingress.kubernetes.io/proxy-body-size" = "0";
        "nginx.ingress.kubernetes.io/proxy-read-timeout" = "3600";
        "nginx.ingress.kubernetes.io/proxy-send-timeout" = "3600";
        "cert-manager.io/cluster-issuer" = vars.tls.defaultIssuer;
      };
      hosts = [{
        host = "nextcloud.${vars.domain}";
        paths = [{ path = "/"; pathType = "Prefix"; }];
      }];
      tls = [{
        secretName = "nextcloud-tls";
        hosts = [ "nextcloud.${vars.domain}" ];
      }];
    };
  };
in {
  applications.nextcloud = {
    namespace = vars.namespaces.nextcloud;
    syncWave = 4;
    helm.releases.nextcloud = {
      chart = charts.nextcloud.nextcloud;
      values = nextcloudValues;
    };
  };
}
