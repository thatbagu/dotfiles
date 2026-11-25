{ lib, rustPlatform, fetchFromGitHub, stdenvNoCC }:
let
  version = "0.4.4";
  src = fetchFromGitHub {
    owner = "kuroahna";
    repo = "mpv_websocket";
    tag = version;
    hash = "sha256-e8t8R+SMcMAKyfL1SwKcUuW1qRBXNtx/LPJrqNbRyw4=";
  };

  server = rustPlatform.buildRustPackage {
    pname = "mpv_websocket";
    inherit version src;
    cargoHash = "sha256-fcYucTUP9fDqO7zdCjZvSmB16gFpbBXAo1DPhDBw4z0=";
    meta.mainProgram = "mpv_websocket";
  };

in
# mpv script that streams subtitle lines to ws://localhost:6677 for a texthooker page
stdenvNoCC.mkDerivation {
  pname = "mpv-websocket";
  inherit version src;
  dontBuild = true;
  postPatch = ''
    substituteInPlace mpv/scripts/run_websocket_server.lua \
      --replace-fail \
        'utils.join_path(config_folder_path, platform == "windows" and "mpv_websocket.exe" or "mpv_websocket")' \
        '"${lib.getExe server}"' \
      --replace-fail \
        'local mpv_socket = find_mpv_socket(config_file_path)' \
        'local mpv_socket = mp.get_property("input-ipc-server")'
  '';
  installPhase = ''
    install -Dm644 mpv/scripts/run_websocket_server.lua \
      $out/share/mpv/scripts/run_websocket_server.lua
  '';
  passthru.scriptName = "run_websocket_server.lua";
  meta = {
    description = "WebSocket plugin for mpv";
    homepage = "https://github.com/kuroahna/mpv_websocket";
    license = lib.licenses.mit;
  };
}
