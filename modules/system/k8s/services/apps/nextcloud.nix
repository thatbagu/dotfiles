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
      # Shared secret Caddy sends as X-Remote-Auth; .htaccess only honours
      # X-Remote-User when it matches (see lifecycle.postStartCommand).
      extraEnv = [{
        name = "SSO_SECRET";
        valueFrom.secretKeyRef = { name = "nextcloud-sso"; key = "secret"; };
      }];

      # VPN SSO: user_saml in environment-variable mode reads REMOTE_USER, which
      # Apache sets from the X-Remote-User header Caddy injects per VPN client
      # IP (see vpn/wireguard.nix). Runs as www-data on every start; no-op once
      # configured.
      hooks.before-starting = ''
        #!/bin/sh
        set -e
        occ() { php /var/www/html/occ "$@"; }

        # Password logins only from the VPN and the home LAN. Public share
        # links don't log in, so they keep working from anywhere.
        occ app:install limit_login_to_ip 2>/dev/null || occ app:enable limit_login_to_ip
        occ config:app:set limit_login_to_ip whitelisted.ranges --value="10.0.100.0/24,192.168.1.0/24"

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
      ''
        f=/var/www/html/.htaccess
        sed -i '/X-Remote-User/d; /X-Remote-Auth/d' "$f"
        # Fail closed: without the shared secret there is no header SSO at all.
        if [ -n "$SSO_SECRET" ]; then
          sed -i "/RewriteEngine on/a\\    RewriteCond %{HTTP:X-Remote-Auth} =$SSO_SECRET\\n    RewriteRule ^ - [E=REMOTE_USER:%{HTTP:X-Remote-User}]" "$f"
        fi
        chown www-data:www-data "$f"
      ''
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
        # SECURITY: X-Remote-User logs the request in as that user (VPN SSO).
        # Only Caddy in the wireguard pod may set it, and it talks to the
        # Service directly; never pass a client-supplied value from the
        # public ingress.
        "nginx.ingress.kubernetes.io/configuration-snippet" = ''
          proxy_set_header X-Remote-User "";
          proxy_set_header X-Remote-Auth "";
          # The public entry point never carries a VPN identity, so the VPN SSO
          # route can only fail here (500, and it poisons the session for a
          # later password login). Send it to the normal login form instead.
          if ($request_uri ~* "^/(index\.php/)?apps/user_saml/saml/login") {
            return 302 https://$host/login?direct=1;
          }
        '';
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
