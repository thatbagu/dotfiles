{ pkgs }:

pkgs.writeShellApplication {
  name = "nextcloud-sso";
  runtimeInputs = [ pkgs.kubectl ];
  text = ''
    KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    export KUBECONFIG

    echo "Checking Nextcloud VPN SSO configuration..."

    if ! kubectl get deployment nextcloud -n nextcloud >/dev/null 2>&1; then
      echo "Nextcloud deployment not found, skipping SSO setup"
      exit 0
    fi

    # Idempotency: skip if provider 1 already has the correct uid_mapping
    if kubectl exec -n nextcloud deployment/nextcloud -- \
        php /var/www/html/occ saml:config:get --providerId=1 2>/dev/null \
        | grep -q 'general-uid_mapping: REMOTE_USER'; then
      echo "Nextcloud VPN SSO already configured, skipping"
      exit 0
    fi

    echo "Configuring user_saml for VPN header auth..."

    # Enable app (creates empty provider 1 if it doesn't exist)
    kubectl exec -n nextcloud deployment/nextcloud -- php /var/www/html/occ app:enable user_saml

    # Global: environment-variable mode + auto-provision accounts on first login
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ config:app:set user_saml type --value=environment-variable
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ config:app:set user_saml general-require_provisioned_account --value=0

    # Per-provider: read REMOTE_USER (set by Apache SetEnvIf from X-Remote-User header)
    # HTTP_* vars are rejected by saml:config:set for security; SetEnvIf bridges the gap.
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ saml:config:set 1 --general-uid_mapping=REMOTE_USER
    kubectl exec -n nextcloud deployment/nextcloud -- \
      php /var/www/html/occ saml:config:set 1 --general-idp0_display_name=VPN-SSO

    echo "Nextcloud VPN SSO configured"
  '';
}
