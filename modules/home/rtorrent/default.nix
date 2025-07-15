{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.rtorrent;
in {
  options.modules.rtorrent = { enable = mkEnableOption "rtorrent"; };

  config = mkIf cfg.enable {
    # Install rtorrent
    home.packages = [ pkgs.rtorrent ];

    # Create optimized rtorrent configuration (based on working version)
    xdg.configFile."rtorrent/rtorrent.rc".text = ''
      # rtorrent configuration file

      # === DIRECTORIES ===
      directory.default.set = ~/Downloads/torrents
      session.path.set = ~/.local/share/rtorrent/session

      # Create session directory if it doesn't exist
      execute.throw = sh, -c, "mkdir -p ~/.local/share/rtorrent/session"

      # === NETWORK SETTINGS ===
      # Port range for incoming connections (forward this port in your router)
      network.port_range.set = 49164-49164
      network.port_random.set = no

      # Enable DHT and peer exchange for maximum peer discovery
      dht.mode.set = auto
      dht.port.set = 6881
      protocol.pex.set = yes
      trackers.use_udp.set = yes

      # === OPTIMIZED CONNECTION LIMITS ===
      # Increased global download/upload slots for better performance
      throttle.max_downloads.global.set = 25
      throttle.max_uploads.global.set = 20

      # Optimized per-torrent peer limits
      throttle.min_peers.normal.set = 30
      throttle.max_peers.normal.set = 150
      throttle.min_peers.seed.set = 20
      throttle.max_peers.seed.set = 100

      # Increased uploads per torrent
      throttle.max_uploads.set = 15

      # Request more peers from trackers
      trackers.numwant.set = 100

      # === BANDWIDTH SETTINGS ===
      # Unlimited bandwidth for maximum speed
      throttle.global_down.max_rate.set_kb = 0
      throttle.global_up.max_rate.set_kb = 0

      # === ENHANCED MEMORY AND PERFORMANCE ===
      # Increased memory allocation for better performance
      pieces.memory.max.set = 512M

      # Enhanced file handling for higher throughput
      network.max_open_files.set = 2048
      network.max_open_sockets.set = 1024
      network.http.max_open.set = 128

      # Optimized preloading for faster transfers
      pieces.preload.type.set = 2
      pieces.preload.min_size.set = 524288
      pieces.preload.min_rate.set = 10240

      # === PROTOCOL SETTINGS ===
      # Encryption for security
      protocol.encryption.set = allow_incoming,try_outgoing,enable_retry

      # Optimized network buffers
      network.http.dns_cache_timeout.set = 60
      network.send_buffer.size.set = 32M
      network.receive_buffer.size.set = 8M
      network.xmlrpc.size_limit.set = 8M

      # === WATCH DIRECTORIES ===
      # Automatically load and start torrents from watch directory
      schedule2 = watch_directory,5,5,load.start=~/Downloads/torrents/*.torrent

      # === HASH CHECKING ===
      # Disable on completion for faster performance (optional)
      pieces.hash.on_completion.set = no

      # === LOGGING ===
      # Minimal logging for performance
      log.execute = ~/.local/share/rtorrent/execute.log

      # === SCGI/WEB INTERFACE ===
      # Enable SCGI for web frontends like ruTorrent
      network.scgi.open_local = ~/.local/share/rtorrent/rpc.socket
      execute.nothrow = chmod,g+w,~/.local/share/rtorrent/rpc.socket
      execute.nothrow = chmod,o+w,~/.local/share/rtorrent/rpc.socket

      # === ADVANCED PERFORMANCE SETTINGS ===
      # Optimize sync behavior for speed
      pieces.sync.always_safe.set = no

      # === SCHEDULER TASKS ===
      # Save session less frequently for performance
      schedule2 = session_save,1800,1800,session.save=

      # Low disk space handling
      schedule2 = low_diskspace,5,60,close_low_diskspace=500M

      # === HELPERS ===
      # Data path helper method
      method.insert = d.data_path, simple, "if=(d.is_multi_file), (cat,(d.directory),/), (cat,(d.directory),/,(d.name))"
    '';

    # Create necessary directories
    home.activation.rtorrentDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/Downloads/torrents"
      mkdir -p "$HOME/Downloads/completed"
      mkdir -p "$HOME/.local/share/rtorrent/session"
    '';
  };
}
