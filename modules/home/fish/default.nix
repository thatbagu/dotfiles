{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.fish;
in {
  options.modules.fish = { enable = mkEnableOption "fish"; };
  config = mkIf cfg.enable {

    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        # Load Anthropic API key from the path stored in ANTHROPIC_API_KEY_LOAD
        function load_anthropic_key --on-variable ANTHROPIC_API_KEY_LOAD
            if test -n "$ANTHROPIC_API_KEY_LOAD" -a -r "$ANTHROPIC_API_KEY_LOAD"
                set -gx ANTHROPIC_API_KEY (cat $ANTHROPIC_API_KEY_LOAD)
            end
        end

        # Run the function once at startup to load the key
        if test -n "$ANTHROPIC_API_KEY_LOAD" -a -r "$ANTHROPIC_API_KEY_LOAD"
            set -gx ANTHROPIC_API_KEY (cat $ANTHROPIC_API_KEY_LOAD)
        end

        # Load GitHub token from the path stored in GITHUB_TOKEN_PATH
        function load_github_token --on-variable GITHUB_TOKEN_PATH
            if test -n "$GITHUB_TOKEN_PATH" -a -r "$GITHUB_TOKEN_PATH"
                set -gx GITHUB_TOKEN (cat $GITHUB_TOKEN_PATH)
            end
        end

        # Run the function once at startup to load the token
        if test -n "$GITHUB_TOKEN_PATH" -a -r "$GITHUB_TOKEN_PATH"
            set -gx GITHUB_TOKEN (cat $GITHUB_TOKEN_PATH)
        end

        # Improve contrast for command line text
        set -g fish_color_command brwhite --bold
        set -g fish_color_param brwhite
        set -g fish_color_quote yellow
        set -g fish_color_redirection cyan --bold
        set -g fish_color_end green
        set -g fish_color_error red --bold
        set -g fish_color_comment brblack
        set -g fish_color_autosuggestion brblack
        set -g fish_color_valid_path --underline
        set -g fish_color_cwd green --bold
        set -g fish_color_user brgreen
        set -g fish_color_host brblue
      '';
      shellAliases = {
        ls = "ls --color=auto";
        ll = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        vi = "nvim";
        vim = "nvim";
      };

      # Add custom functions
      functions = {
        fish_prompt = ''
          # Custom prompt with higher contrast
          set -l last_status $status

          # User and host with better contrast
          set_color brgreen --bold
          printf '%s' $USER
          set_color normal
          printf '@'
          set_color brblue --bold
          printf '%s ' (hostname)

          # Current directory with better contrast
          set_color green --bold
          printf '%s' (prompt_pwd)

          # Git status if available
          if type -q git
              set -l git_branch (git branch 2>/dev/null | sed -n '/\* /s///p')
              if test -n "$git_branch"
                  set_color normal
                  printf ' ('
                  set_color yellow --bold
                  printf '%s' $git_branch
                  set_color normal
                  printf ')'
              end
          end

          # Status indicator
          if test $last_status -eq 0
              set_color green
          else
              set_color red --bold
          end
          printf ' ❯ '
          set_color normal
        '';
      };
    };
  };
}
