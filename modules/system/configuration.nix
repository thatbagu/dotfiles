{ config, pkgs, inputs, username, ... }:

{

  imports = [ ./steam ./packages ./stylix ./unifi ./sops ];

  # Remove unecessary preinstalled packages
  environment.defaultPackages = [ ];
  services.xserver.desktopManager.xterm.enable = false;

  # Install fonts
  fonts = {
    packages = with pkgs; [
      roboto
      openmoji-color
      nerd-fonts.jetbrains-mono
      noto-fonts-cjk-sans
    ];
    fontconfig = {
      enable = true;
      hinting.autohint = true;
      antialias = true;
      hinting.enable = true;
      defaultFonts = {
        emoji = [ "OpenMoji Color" ];
        monospace = [ "DejaVu Sans Mono" "Liberation Mono" ];
        sansSerif = [ "DejaVu Sans" "Liberation Sans" ];
        serif = [ "DejaVu Serif" "Liberation Serif" ];
      };
    };
  };
  # Wayland stuff: enable XDG integration, allow sway to use brillo
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
      # Add this new configuration for XDG portal
      config = { common.default = "*"; };
    };
  };

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
    shell = pkgs.nushell;
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
    GTK_RC_FILES = "$HOME/.local/share/gtk-1.0/gtkrc";
    GTK2_RC_FILES = "$HOME/.local/share/gtk-2.0/gtkrc";
    MOZ_ENABLE_WAYLAND = "1";
    ZK_NOTEBOOK_DIR = "$HOME/stuff/notes/";
    EDITOR = "nvim";
    DIRENV_LOG_FORMAT = "";
    ANKI_WAYLAND = "1";
    DISABLE_QT5_COMPAT = "0";
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

  programs.dconf.enable = true;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # Enable JACK support
    wireplumber.enable = true; # Enable Wireplumber explicitly
  };

  # For battery support
  services.upower.enable = true;

  # For backlight control
  programs.light.enable = true;

  # Disable bluetooth, enable pulseaudio, enable opengl (for Wayland)
  hardware = {
    bluetooth.enable = true;
    graphics = { # Changed from opengl to graphics
      enable = true;
      enable32Bit = true; # Changed from driSupport32Bit
    };
  };
  system.stateVersion = "24.05";
}
