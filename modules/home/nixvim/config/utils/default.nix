{ lib, config, ... }: {
  imports = [
    ./baleia.nix
    ./cloak.nix
    ./esp-rs.nix
    ./harpoon.nix
    ./markdown-preview.nix
    ./mini.nix
    ./neotest.nix
    ./nvim-autopairs.nix
    ./nvim-colorizer.nix
    ./nvim-surround.nix
    ./nvterm.nix
    ./oil.nix
    ./persistence.nix
    ./plenary.nix
    ./project-nvim.nix
    ./sidebar.nix
    ./todo-comments.nix
    ./ultimate-autopair.nix
    ./undotree.nix
    ./which-key.nix
    ./wilder.nix
    ./leap.nix
    ./multicursors.nix
    ./venv-selector.nix
    ./firenvim.nix
  ];

  options = { utils.enable = lib.mkEnableOption "Enable utils module"; };
  config = lib.mkIf config.utils.enable {
    baleia.enable = lib.mkDefault true;
    cloak.enable = lib.mkDefault true;
    esp-rs.enable = lib.mkDefault true;
    harpoon.enable = lib.mkDefault true;
    markdown-preview.enable = lib.mkDefault true;
    mini.enable = lib.mkDefault true;
    neotest.enable = lib.mkDefault true;
    nvim-autopairs.enable = lib.mkDefault true;
    nvim-colorizer.enable = lib.mkDefault true;
    nvim-surround.enable = lib.mkDefault true;
    nvterm.enable = lib.mkDefault true;
    oil.enable = lib.mkDefault true;
    persistence.enable = lib.mkDefault true;
    plenary.enable = lib.mkDefault true;
    project-nvim.enable = lib.mkDefault true;
    sidebar.enable = lib.mkDefault true;
    todo-comments.enable = lib.mkDefault true;
    ultimate-autopair.enable = lib.mkDefault true;
    undotree.enable = lib.mkDefault true;
    which-key.enable = lib.mkDefault true;
    wilder.enable = lib.mkDefault true;
    leap.enable = lib.mkDefault true;
    multicursors.enable = lib.mkDefault true;
    venv-selector.enable = lib.mkDefault true;
    firenvim.enable = lib.mkDefault true;
  };
}
