{ pkgs, inputs, lib, vars, config }:

let
  # Import standard lib functions we need from pkgs.lib
  inherit (pkgs.lib)
    filterAttrs mapAttrs mapAttrsToList concatStringsSep listToAttrs toUpper;

  # Import users configuration
  usersConfig = import ./users.nix { inherit config lib; };

  # Filter enabled users only
  enabledUsers = filterAttrs (_: user: user.enabled) usersConfig.wireguardUsers;

  # Generate WireGuard server configuration
  generateServerConfig = ''
    [Interface]
    Address = 10.0.100.1/24
    ListenPort = 51820
    PrivateKey = __SERVER_PRIVATE_KEY__

    # Fixed PostUp/PostDown rules for container networking
    PostUp = echo 1 > /proc/sys/net/ipv4/ip_forward
    PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
    PostUp = iptables -A FORWARD -o wg0 -j ACCEPT  
    PostUp = iptables -t nat -A POSTROUTING -s 10.0.100.0/24 ! -d 10.0.100.0/24 -j MASQUERADE
    PostUp = iptables -A INPUT -p udp --dport 51820 -j ACCEPT

    PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
    PostDown = iptables -D FORWARD -o wg0 -j ACCEPT
    PostDown = iptables -t nat -D POSTROUTING -s 10.0.100.0/24 ! -d 10.0.100.0/24 -j MASQUERADE  
    PostDown = iptables -D INPUT -p udp --dport 51820 -j ACCEPT

    ${concatStringsSep "\n\n" (mapAttrsToList (name: user: ''
      [Peer]
      PublicKey = __${toUpper name}_PUBLIC_KEY__
      AllowedIPs = ${user.ip}/32
    '') enabledUsers)}
  '';

  # Generate client configs
  generateClientConfig = name: user: ''
    [Interface]
    PrivateKey = __PASTE_${toUpper name}_PRIVATE_KEY_HERE__
    Address = ${user.ip}/32
    DNS = 192.168.1.1

    [Peer]
    PublicKey = __SERVER_PUBLIC_KEY__
    Endpoint = __WG_SERVER_ENDPOINT__:51820
    AllowedIPs = ${user.allowedIPs}
    PersistentKeepalive = 25
  '';

  # ConfigMap with server template and client configs
  configMapResource = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "wireguard-config";
      namespace = vars.namespaces.wireguard;
    };
    data = {
      "wg0.conf.template" = generateServerConfig;
    } // (mapAttrs (name: user: generateClientConfig name user) enabledUsers);
  };

  pvcResource = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = {
      name = "wireguard-data";
      namespace = vars.namespaces.wireguard;
    };
    spec = {
      accessModes = [ "ReadWriteOnce" ];
      storageClassName = "longhorn";
      resources = { requests = { storage = "1Gi"; }; };
    };
  };

  # WireGuard deployment
  deploymentResource = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "wireguard";
      namespace = vars.namespaces.wireguard;
    };
    spec = {
      replicas = 1;
      strategy = { type = "Recreate"; };
      selector = { matchLabels = { app = "wireguard"; }; };
      template = {
        metadata = { labels = { app = "wireguard"; }; };
        spec = {
          securityContext = {
            capabilities = { add = [ "NET_ADMIN" "SYS_MODULE" ]; };
            privileged = true;
          };
          initContainers = [{
            name = "setup-config";
            image = "alpine:3.18";
            command = [ "/bin/sh" "-c" ];
            args = [''
              # Copy template to the config directory  
              cp /config-template/wg0.conf.template /config/wg_confs/wg0.conf

              # Replace server private key
              sed -i "s|__SERVER_PRIVATE_KEY__|$(cat /secrets/server-private-key)|g" /config/wg_confs/wg0.conf

              # Replace user public keys from SOPS secrets
              ${concatStringsSep "\n" (mapAttrsToList (name: user: ''
                sed -i "s|__${
                  toUpper name
                }_PUBLIC_KEY__|$(cat /secrets/${user.publicKeySecret})|g" /config/wg_confs/wg0.conf
              '') enabledUsers)}

              # For client configs, replace server public key and endpoint
              SERVER_PUBLIC_KEY=$(cat /secrets/server-public-key)
              WG_ENDPOINT=$(cat /secrets/wg-server-endpoint)

              # Replace placeholders in all client config files
              for file in /config-template/*; do
                if [[ $file != *.template ]]; then
                  filename=$(basename "$file")
                  cp "$file" "/config/$filename"
                  sed -i "s|__SERVER_PUBLIC_KEY__|$SERVER_PUBLIC_KEY|g" "/config/$filename"
                  sed -i "s|__WG_SERVER_ENDPOINT__|$WG_ENDPOINT|g" "/config/$filename"
                fi
              done

              # Set proper permissions
              chmod 600 /config/wg_confs/wg0.conf

              echo "WireGuard config ready with ${
                toString (builtins.length (builtins.attrNames enabledUsers))
              } users"
            ''];
            volumeMounts = [
              {
                name = "config-template";
                mountPath = "/config-template";
              }
              {
                name = "wireguard-data";
                mountPath = "/config";
              }
              {
                name = "wireguard-secrets";
                mountPath = "/secrets";
              }
            ];
          }];
          containers = [{
            name = "wireguard";
            image = "lscr.io/linuxserver/wireguard:latest";
            env = [
              {
                name = "PUID";
                value = "1000";
              }
              {
                name = "PGID";
                value = "1000";
              }
              {
                name = "TZ";
                value = "UTC";
              }
              {
                name = "SERVERURL";
                value = "auto";
              }
              {
                name = "SERVERPORT";
                value = "51820";
              }
              {
                name = "PEERDNS";
                value = "192.168.1.1";
              }
              {
                name = "INTERNAL_SUBNET";
                value = "10.0.100.0";
              }
              {
                name = "ALLOWEDIPS";
                value = "0.0.0.0/0";
              }
              # Enable IP forwarding and NAT
              {
                name = "LOG_CONFS";
                value = "true";
              }
            ];
            ports = [{
              name = "wireguard";
              containerPort = 51820;
              protocol = "UDP";
            }];
            resources = {
              requests = {
                cpu = "100m";
                memory = "128Mi";
              };
              limits = {
                cpu = "500m";
                memory = "256Mi";
              };
            };
            volumeMounts = [
              {
                name = "wireguard-data";
                mountPath = "/config";
              }
              {
                name = "lib-modules";
                mountPath = "/lib/modules";
                readOnly = true;
              }
            ];
            securityContext = {
              capabilities = { add = [ "NET_ADMIN" "SYS_MODULE" ]; };
              privileged = true;
            };
          }];
          volumes = [
            {
              name = "wireguard-data";
              persistentVolumeClaim = { claimName = "wireguard-data"; };
            }
            {
              name = "config-template";
              configMap = { name = "wireguard-config"; };
            }
            {
              name = "wireguard-secrets";
              secret = { secretName = "wireguard-secrets"; };
            }
            {
              name = "lib-modules";
              hostPath = {
                path = "/lib/modules";
                type = "Directory";
              };
            }
          ];
        };
      };
    };
  };

  # LoadBalancer service with external DNS
  serviceResource = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "wireguard";
      namespace = vars.namespaces.wireguard;
      annotations = {
        "metallb.universe.tf/allow-shared-ip" = "wireguard-svc";
      };
    };
    spec = {
      type = "LoadBalancer";
      loadBalancerIP = vars.ipPools.wireguard;
      selector = { app = "wireguard"; };
      ports = [{
        name = "wireguard";
        port = 51820;
        targetPort = 51820;
        protocol = "UDP";
      }];
    };
  };

  # Generate user secret references dynamically (public keys only — private keys stay local)
  userSecrets = listToAttrs (mapAttrsToList (name: user: {
    name = "wireguard-user-${name}";
    value = lib.mkSecretRef {
      name = "wireguard-user-${name}";
      namespace = vars.namespaces.wireguard;
      secretName = "wireguard-secrets";
      secretKey = user.publicKeySecret;
      sopsSecretName = user.publicKeySecret;
    };
  }) enabledUsers);

in {
  # Server public key and endpoint secrets
  wireguard-server-public-key = lib.mkSecretRef {
    name = "wireguard-server-public-key";
    namespace = vars.namespaces.wireguard;
    secretName = "wireguard-secrets";
    secretKey = "server-public-key";
    sopsSecretName = "wireguard_server_public_key";
  };

  wireguard-server-endpoint = lib.mkSecretRef {
    name = "wireguard-server-endpoint";
    namespace = vars.namespaces.wireguard;
    secretName = "wireguard-secrets";
    secretKey = "wg-server-endpoint";
    sopsSecretName = "wireguard_server_endpoint";
  };

  wireguard-server-key = lib.mkSecretRef {
    name = "wireguard-server-key";
    namespace = vars.namespaces.wireguard;
    secretName = "wireguard-secrets";
    secretKey = "server-private-key";
    sopsSecretName = "wireguard_server_private_key";
  };

  # WireGuard configuration
  wireguard-config = lib.mkRawManifest {
    name = "wireguard-config";
    namespace = vars.namespaces.wireguard;
    resources = [ configMapResource ];
  };

  # WireGuard storage
  wireguard-storage = lib.mkRawManifest {
    name = "wireguard-storage";
    namespace = vars.namespaces.wireguard;
    resources = [ pvcResource ];
  };

  # WireGuard deployment
  wireguard-deployment = lib.mkRawManifest {
    name = "wireguard-deployment";
    namespace = vars.namespaces.wireguard;
    resources = [ deploymentResource ];
  };

  # WireGuard service
  wireguard-service = lib.mkRawManifest {
    name = "wireguard-service";
    namespace = vars.namespaces.wireguard;
    resources = [ serviceResource ];
  };
} // userSecrets
