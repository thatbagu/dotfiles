{ config, pkgs, inputs, username, ... }:

{
  imports = [ ./packages ./sops ];

  # Remove unnecessary preinstalled packages
  environment.defaultPackages = [ ];

  # Install fonts
  fonts = {
    fontDir.enable = true; # Darwin-specific font setup
    fonts = with pkgs; [
      roboto
      openmoji-color
      nerd-fonts.jetbrains-mono
      noto-fonts-cjk-sans
    ];
  };

  # Nix settings, auto cleanup and enable flakes
  nix = {
    settings = {
      auto-optimise-store = true;
      allowed-users = [ "${username}" ];
      trusted-users = [ "root" "${username}" ];
    };
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      }; # Run weekly
      options = "--delete-old";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # Set up locales (timezone and keyboard layout)
  time.timeZone = "Asia/Almaty";

  # Set up user
  users.users.${username} = {
    name = "${username}";
    home = "/Users/${username}";
    shell = pkgs.fish;
  };

  # Darwin-specific system settings
  system = {
    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleShowScrollBars = "Always";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };
      dock = {
        autohide = true;
        mru-spaces = false;
        orientation = "bottom";
        showhidden = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        QuitMenuItem = true;
        FXEnableExtensionChangeWarning = false;
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };

  # Set environment variables
  environment.sessionVariables = {
    NIXOS_CONFIG = "$HOME/.config/nixos/configuration.nix";
    NIXOS_CONFIG_DIR = "$HOME/.config/nixos/";
    XDG_DATA_HOME = "$HOME/.local/share";
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    GTK_RC_FILES = "$HOME/.local/share/gtk-1.0/gtkrc";
    GTK2_RC_FILES = "$HOME/.local/share/gtk-2.0/gtkrc";
    ZK_NOTEBOOK_DIR = "$HOME/stuff/notes/";
    EDITOR = "nvim";
    DIRENV_LOG_FORMAT = "";
    ANTHROPIC_API_KEY_LOAD = config.sops.secrets.antropic_key.path;
    GITHUB_TOKEN_PATH = config.sops.secrets.github_token.path;
  };

  # Enable homebrew
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
      lockfiles = true;
    };
    # Add GUI applications that aren't available or work better from homebrew
    casks = [ "raycast" "alt-tab" "rectangle" ];
  };

  # Security settings (Darwin-specific)
  security = {
    pam = {
      enableSudoTouchIdAuth = true; # Enable Touch ID for sudo
    };
  };

  # Services available on Darwin
  services = {
    nix-daemon.enable = true;
    # Yabai (window manager) configuration if needed
    # yabai = {
    #   enable = true;
    #   config = {};
    # };
  };

  # System version
  system.stateVersion = 4;
}

