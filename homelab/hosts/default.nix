# Extras for the homelab nodes, on top of nixlab's (extraNixosModules in
# flake.nix): the shell setup and this flake's overlays; meowth also gets the
# cv GitHub runner (meowth/cv-runner.nix). Takes this flake's inputs: the
# `inputs` nixlab passes to modules are its own.
inputs:
{ lib, pkgs, username, hostname, ... }:

{
  imports = [
    inputs.stylix.nixosModules.stylix
    inputs.home-manager.nixosModules.home-manager
  ] ++ lib.optional (hostname == "meowth") ./meowth/cv-runner.nix;

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

  # This flake's package overlays too (e.g. the newer github-runner); nixlab
  # only applies its own.
  nixpkgs.overlays = builtins.attrValues (import ../../overlays/default.nix);

  # The locales the nodes were installed with: changing them restarts nearly
  # every service. Drop this line at a planned reboot.
  i18n.supportedLocales = lib.mkForce [ "en_US.UTF-8/UTF-8" "ja_JP.UTF-8/UTF-8" ];
}
