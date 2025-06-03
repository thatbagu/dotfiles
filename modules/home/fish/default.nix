{ lib, config, ... }:
with lib;
let cfg = config.modules.fish;
in {
  options.modules.fish = { enable = mkEnableOption "fish"; };
  config = mkIf cfg.enable {

    programs.fish = {
      enable = true;
      interactiveShellInit = ''
                # Generic function to load secrets from files
                function load_secret_from_file --argument-names var_name env_var_path
                    if test -n "$$env_var_path" -a -r "$$env_var_path"
                        set -gx $var_name (cat $$env_var_path)
                    end
                end

                # Define secret mappings (path variable -> environment variable)
                set -g __secret_mappings
                set -a __secret_mappings ANTHROPIC_API_KEY_LOAD ANTHROPIC_API_KEY
                set -a __secret_mappings GITHUB_TOKEN_PATH GITHUB_TOKEN
                set -a __secret_mappings CLOUDFLARE_EMAIL_PATH CLOUDFLARE_EMAIL
                set -a __secret_mappings GIT_USER_EMAIL_PATH GIT_USER_EMAIL

                # Special handling for Git email configuration
                function update_git_email --on-variable GIT_USER_EMAIL
                    if test -n "$GIT_USER_EMAIL"
                        set -gx GIT_AUTHOR_EMAIL $GIT_USER_EMAIL
                        set -gx GIT_COMMITTER_EMAIL $GIT_USER_EMAIL
                    end
                end

                # Load all secrets at startup
                for i in (seq 1 2 (count $__secret_mappings))
                    set -l path_var $__secret_mappings[$i]
                    set -l env_var $__secret_mappings[(math $i + 1)]
                    load_secret_from_file $env_var $path_var
                end

                # Generic event handler for all path variables
                # Create individual event handlers for each path variable
                for i in (seq 1 2 (count $__secret_mappings))
                    set -l path_var $__secret_mappings[$i]
                    set -l env_var $__secret_mappings[(math $i + 1)]
                    
                    # Create a function with the correct event handler syntax
                    eval "function __handle_"$path_var"_change --on-variable "$path_var"
                        load_secret_from_file "$env_var" "$path_var"
                    end"
                end

                # Custom greeting function
                function fish_greeting
                    set -l hour (date +%H)
                    set -l day (date +%u)
                    set -l username $USER
                    
                    # ASCII art for the greeting
                    set -l ascii_art "
              |\      _,,,---,,_
        ZZZzz /,`.-'`'    -.  ;-;;,_
             |,4-  ) )-,_. ,\ (  `'-'
            '---'\'(_/--'  `-'\_)

                    "
                    
                    # Time-based greetings
                    if test $hour -ge 5 -a $hour -lt 12
                        set -l morning_greetings \
                            "Good morning, $username! Ready to conquer the day?" \
                            "Rise and shine, $username! The code awaits." \
                            "Morning has broken! Time to break some code." \
                            "Top of the morning to you, $username!"
                        set greeting (random choice $morning_greetings)
                    else if test $hour -ge 12 -a $hour -lt 18
                        set -l afternoon_greetings \
                            "Good afternoon, $username! How's your day going?" \
                            "Afternoon delight! Time for some coding magic." \
                            "The day is still young, $username. What will you accomplish?" \
                            "Afternoon, $username! Coffee time?"
                        set greeting (random choice $afternoon_greetings)
                    else if test $hour -ge 18 -a $hour -lt 22
                        set -l evening_greetings \
                            "Good evening, $username! Productive day?" \
                            "Evening has arrived. Time for the real work to begin!" \
                            "The night is still young, $username." \
                            "Evening, $username! Dinner before code or code before dinner?"
                        set greeting (random choice $evening_greetings)
                    else
                        set -l night_greetings \
                            "Working late, $username? Don't forget to rest!" \
                            "The night owl catches the bug." \
                            "Midnight coding session? Remember to blink occasionally." \
                            "Burning the midnight oil, $username?"
                        set greeting (random choice $night_greetings)
                    end
                    
                    # Day-specific messages for Friday and Monday
                    if test $day -eq 5
                        set -l friday_messages \
                            "It's Friday! Weekend is approaching!" \
                            "Friday vibes! Almost there!" \
                            "Happy Friday, $username!"
                        set friday_msg (random choice $friday_messages)
                        set greeting "$greeting $friday_msg"
                    else if test $day -eq 1
                        set -l monday_messages \
                            "It's Monday! Let's start the week strong!" \
                            "New week, new opportunities!" \
                            "Monday: A fresh start!"
                        set monday_msg (random choice $monday_messages)
                        set greeting "$greeting $monday_msg"
                    end
                    
                    # Display the greeting with some color
                    set_color yellow
                    echo $ascii_art
                    set_color brgreen
                    set_color yellow
                    echo $greeting
                    set_color normal
                    
                    # Show system info
                    echo ""
                    set_color cyan
                    echo "System: "(uname -rs)
                    echo "Uptime: "(uptime | cut -d ',' -f1 | cut -d ' ' -f4-)
                    set_color normal
                    echo ""
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
          # Custom 2-layer prompt with higher contrast
          set -l last_status $status

          # First line with user, host, directory, git, and kubeconfig info
          echo -n ""  # Start with a newline for better separation

          # User and host with better contrast
          set_color brgreen --bold
          printf '%s' $USER
          set_color normal
          printf '@'
          set_color brblue --bold
          printf '%s' (hostname)

          # Current directory with better contrast
          set_color normal
          printf ' in '
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

          # Kubernetes context if available
          if set -q KUBECONFIG
              set -l kube_context (kubectl config current-context 2>/dev/null)
              if test -n "$kube_context"
                  set_color normal
                  printf ' ['
                  set_color cyan --bold
                  printf 'k8s: %s' $kube_context
                  set_color normal
                  printf ']'
              end
          end

          # Add a newline to separate the two layers
          echo

          # Second line with status indicator
          if test $last_status -eq 0
              set_color green
          else
              set_color red --bold
          end
          printf '❯ '
          set_color normal
        '';
      };
    };
  };
}
