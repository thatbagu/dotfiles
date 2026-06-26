{ pkgs }:

pkgs.writeShellApplication {
  name = "nextcloud-sso";
  runtimeInputs = [ pkgs.kubectl pkgs.python3 ];
  text = ''
    KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    export KUBECONFIG

    echo "Checking Nextcloud VPN SSO configuration..."

    if ! kubectl get deployment nextcloud -n nextcloud >/dev/null 2>&1; then
      echo "Nextcloud deployment not found, skipping SSO setup"
      exit 0
    fi

    if kubectl exec -n nextcloud deployment/nextcloud -- \
        php /var/www/html/occ app:list --output=json 2>/dev/null \
        | python3 -c "import sys,json; exit(0 if 'user_saml' in json.load(sys.stdin).get('enabled',{}) else 1)" 2>/dev/null; then
      echo "Nextcloud VPN SSO already configured, skipping"
      exit 0
    fi

    echo "Enabling user_saml for VPN header auth..."
    kubectl exec -n nextcloud deployment/nextcloud -- php /var/www/html/occ app:enable user_saml

    # user_saml v8+ stores type as an app config key, not a per-provider SAML config.
    # HTTP_X_REMOTE_USER is how PHP exposes the X-Remote-User HTTP header.
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ config:app:set user_saml type --value=environment-variable
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ config:app:set user_saml general-uid_mapping --value=HTTP_X_REMOTE_USER
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ config:app:set user_saml general-require_provisioned_account --value=0

    echo "Nextcloud VPN SSO configured"
  '';
}
