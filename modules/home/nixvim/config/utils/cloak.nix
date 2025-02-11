{ lib, config, ... }:

{
  options = { cloak.enable = lib.mkEnableOption "Enable cloak module"; };

  config = lib.mkIf config.cloak.enable {
    plugins.cloak = {
      enable = true;
      settings = {
        cloak_character = "*";
        highlight_group = "Comment";
        patterns = [
          # General patterns for all configs and secrets
          {
            file_pattern = [
              ".env*"
              "*.yaml"
              "*.yml"
              "*.json"
              "*.toml"
              "*.tf"
              "*.tfvars"
              "go.mod"
              "go.sum"
              "config.go"
              "Cargo.toml"
              "Cargo.lock"
              "requirements.txt"
              "pyproject.toml"
              "setup.cfg"
            ];
            cloak_pattern =
              "(password|secret|key|token|credential|access_key|secret_key|connection|api).*[=:].+";
          }
          # MLOps specific tools and CI/CD
          {
            file_pattern = [
              "mlflow.yml"
              "dagster.yaml"
              "airflow.cfg"
              "kubeconfig"
              "*.pkl"
              "model-*.json"
              ".gitlab-ci.yml"
              ".github/workflows/*.yml"
              "jenkins*.groovy"
              "azure-pipelines.yml"
              "terraform.tfstate"
              ".cargo/config"
              ".python-version"
              ".golangci.yml"
            ];
            cloak_pattern =
              "(secret|token|password|key|connection_string|api_key):.*";
          }
        ];
      };
    };
  };
}
