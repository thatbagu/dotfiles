{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.modules.memento;

  # nixpkgs ships 1.7.0; 2.x moved the UI to QML and renamed the CMake options
  memento = pkgs.memento.overrideAttrs (old: rec {
    version = "2.0.2";
    src = pkgs.fetchFromGitHub {
      owner = "ripose-jp";
      repo = "Memento";
      tag = "v${version}";
      hash = "sha256-PVGzPd9t8FNZ3kLLueDIzIKAgagW7avDMFp6NKtSCD0=";
    };
    # QCoro6::Qml links Qt6::QmlPrivate, which must be found first
    postPatch = (old.postPatch or "") + ''
      substituteInPlace CMakeLists.txt --replace-fail \
        'find_package(QCoro6 REQUIRED' \
        'find_package(Qt6 REQUIRED COMPONENTS QmlPrivate)
      find_package(QCoro6 REQUIRED'
    '';
    cmakeFlags = [
      (lib.cmakeBool "MEMENTO_RELEASE_BUILD" true)
      (lib.cmakeBool "MEMENTO_SYSTEM_QCORO" true)
    ];
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.qt6Packages.qttools ];
    buildInputs = old.buildInputs ++ (with pkgs.qt6Packages; [ qtdeclarative qttools ]);
  });

in {
  options.modules.memento = { enable = mkEnableOption "memento"; };
  config = mkIf cfg.enable { home.packages = [ memento ]; };
}
