{ config, pkgs, inputs, username, ... }:

{

  imports = [ ./steam ./packages ./stylix ./unifi ./sops ./desktop ./k3s ];

  # Remove unnecessary preinstalled packages
  environment.defaultPackages = [ ];

  # Nix settings, auto cleanup and enable flakes
  nix = {
    settings.auto-optimise-store = true;
    settings.allowed-users = [ "${username}" ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-old";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      trusted-users = root ${username}
    '';
  };

  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 10;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        configurationLimit = 10; # Keep 10 generations in boot menu
      };
    };
  };

  swapDevices = [{
    device = "/swapfile";
    size = 32000; # Size in MB (16GB in this example)
  }];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # Use up to 50% of RAM for compressed swap
  };

  # Set up locales (timezone and keyboard layout)
  time.timeZone = "Asia/Almaty";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Set up user and enable sudo
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "input" "wheel" "gamemode" "video" ];
    hashedPasswordFile = config.sops.secrets.user_password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQRS6OzC9Ip5lUhIyFvG03KgyupxJE55gmY3Dis0u18 cluster"
    ];
    shell = pkgs.nushell;
  };

  users.users.root = {
    hashedPasswordFile = config.sops.secrets.user_password.path;
  };

  # Set up networking and secure it
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 443 80 27036 27037 ];
      allowedUDPPorts = [ 443 80 44857 27031 27036 ];
      allowPing = false;
    };
  };

  # Set environment variables
  environment.sessionVariables = {
    NIXOS_CONFIG = "$HOME/.config/nixos/configuration.nix";
    NIXOS_CONFIG_DIR = "$HOME/.config/nixos/";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_RUNTIME_DIR = "/run/user/1000";
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    ZK_NOTEBOOK_DIR = "$HOME/stuff/notes/";
    EDITOR = "nvim";
    DIRENV_LOG_FORMAT = "";
    ANTHROPIC_API_KEY_LOAD = config.sops.secrets.antropic_key.path;
    GITHUB_TOKEN_PATH = config.sops.secrets.github_token.path;
  };

  # Security 
  security = {
    sudo.enable = false;
    doas = {
      enable = true;
      extraRules = [{
        users = [ "${username}" ];
        keepEnv = true;
        persist = true;
      }];
    };

    # Extra security
    protectKernelImage = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  system.stateVersion = "24.05";
}
