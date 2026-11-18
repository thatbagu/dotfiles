# Extras for the homelab nodes, on top of nixlab's (extraNixosModules in
# flake.nix): the shell setup. Takes this flake's inputs: the `inputs` nixlab
# passes to modules are its own.
inputs:
{ lib, pkgs, username, hostname, ... }:

{
  imports = [
    inputs.stylix.nixosModules.stylix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Shell setup: fish, nixvim, zellij, k9s, …
  programs.fish.enable = true;
  users.users.${username}.shell = pkgs.fish;
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "-backup";
    extraSpecialArgs = {
      inherit inputs;
      claude-code = inputs.claude-code.packages.x86_64-linux.default;
    };
    users.${username}.imports = [
      (./. + "/${hostname}/user.nix")
      inputs.nixvim.homeModules.nixvim
    ];
  };

  # Let the N100s ramp up only under real load: with the default
  # balance_performance, Kubernetes' constant small wakeups keep them near
  # turbo (~70 °C at idle).
  systemd.tmpfiles.rules = [
    "w /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference - - - - balance_power"
  ];

  # The locales the nodes were installed with: changing them restarts nearly
  # every service. Drop this line at a planned reboot.
  i18n.supportedLocales = lib.mkForce [ "en_US.UTF-8/UTF-8" "ja_JP.UTF-8/UTF-8" ];
}
