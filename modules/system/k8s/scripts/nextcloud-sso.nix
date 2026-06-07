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
    kubectl exec -n nextcloud deployment/nextcloud -- php /var/www/html/occ saml:config:create
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ saml:config:set 1 --type=environment-variable
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ saml:config:set 1 --general-uid_mapping=HTTP_X_REMOTE_USER
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ saml:config:set 1 --general-require_provisioned_account=1

    echo "Nextcloud VPN SSO configured"
  '';
}
