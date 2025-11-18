{
  description = "Standalone nixvim build";

  inputs = {
    # Use the parent flake's inputs
    parent.url = "path:../../..";
    nixpkgs.follows = "parent/nixpkgs";
    nixvim.follows = "parent/nixvim";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { nixpkgs, nixvim, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, system, ... }:
        let
          nixvimLib = nixvim.lib.${system};
          nixvim' = nixvim.legacyPackages.${system};
          nixvimModule = {
            inherit pkgs;
            module = import ./config;
            extraSpecialArgs = { };
          };
          nvim = nixvim'.makeNixvimWithModule nixvimModule;
        in {
          packages = {
            default = nvim;
            nvim = nvim;
          };
        };
    };
}
