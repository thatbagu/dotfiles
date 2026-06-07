{ pkgs, inputs, lib, vars }:

{
  nextcloud = lib.mkChart {
    name = "nextcloud";
    namespace = vars.namespaces.nextcloud;
    chart = lib.nixhelm.nextcloud.nextcloud;
    values = {
      nextcloud = {
        host = "nextcloud.${vars.domain}";
        username = "admin";
        existingSecret = {
          enabled = true;
          secretName = "nextcloud-admin";
          passwordKey = "password";
        };
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
  };

  nextcloud-admin-secret = lib.mkSecretRef {
    name = "nextcloud-admin-secret";
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-admin";
    secretKey = "password";
    sopsSecretName = "nextcloud_admin_password";
  };

  nextcloud-admin-username-secret = lib.mkSecretRef {
    name = "nextcloud-admin-username-secret";
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-admin";
    secretKey = "nextcloud-username";
    sopsSecretName = "nextcloud_admin_username";
  };

  nextcloud-db-secret = lib.mkSecretRef {
    name = "nextcloud-db-secret";
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-db";
    secretKey = "password";
    sopsSecretName = "nextcloud_db_password";
  };

  nextcloud-db-username-secret = lib.mkSecretRef {
    name = "nextcloud-db-username-secret";
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-db";
    secretKey = "db-username";
    sopsSecretName = "nextcloud_db_username";
  };

  nextcloud-redis-secret = lib.mkSecretRef {
    name = "nextcloud-redis-secret";
    namespace = vars.namespaces.nextcloud;
    secretName = "nextcloud-redis";
    secretKey = "password";
    sopsSecretName = "nextcloud_redis_password";
  };
}
