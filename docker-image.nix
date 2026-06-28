{ pkgs ? import <nixpkgs> {} }:

let
  pkgsLinux = pkgs.pkgsCross.aarch64-multiplatform;

  # Packages that cannot cross-compile from macOS (they execute target-arch
  # binaries during build) are sourced from a native aarch64-linux evaluation
  # so Nix fetches pre-built substitutes from cache.nixos.org instead.
  pkgsLinuxNative = import <nixpkgs> {
    system = "aarch64-linux";
    config.allowUnsupportedSystem = true;
  };

  localeArchive = pkgs.runCommand "locale-archive" {} ''
    mkdir -p $out/share/locale
    cp ${pkgsLinuxNative.glibcLocales.override {
      allLocales = false;
      locales = [ "en_US.UTF-8/UTF-8" ];
    }}/lib/locale/locale-archive $out/share/locale/locale-archive
  '';

  clients = import ./postgresql-client.nix { pkgs = pkgsLinux; };
  allClientPackages = builtins.attrValues clients;

  dataDir = pkgs.runCommand "data-dir" {} ''
    mkdir -p $out/data $out/tmp
  '';

  configFiles = pkgs.runCommand "psql-config-files" {} ''
    mkdir -p $out/root $out/root/.config/nvim
    cp ${./docker/psqlrc} $out/root/.psqlrc
    cp ${./docker/inputrc} $out/root/.inputrc
    cp ${./neovim/init.lua} $out/root/.config/nvim/init.lua
  '';

  neovim = pkgs.runCommand "neovim-0.12.0" {
    nativeBuildInputs = [ pkgs.patchelf ];
  } ''
    mkdir -p $out
    tar -xzf ${pkgs.fetchurl {
      url = "https://github.com/neovim/neovim/releases/download/v0.12.0/nvim-linux-arm64.tar.gz";
      sha256 = "1cin6y5x6s6iy8y39mjbwhp6fdiv7vmv20n0x448yg7gw9xlw0l9";
    }} --strip-components=1 -C $out
    patchelf \
      --set-interpreter "${pkgsLinux.glibc}/lib/ld-linux-aarch64.so.1" \
      --set-rpath "${pkgsLinux.glibc}/lib:${pkgsLinux.stdenv.cc.cc.lib}/lib" \
      $out/bin/nvim
  '';

  clearBin = pkgsLinux.writeShellScriptBin "clear" ''
    printf '\033[H\033[2J'
  '';

  resetBin = pkgsLinux.writeShellScriptBin "reset" ''
    printf '\033c'
    stty sane 2>/dev/null || true
  '';

  nvimEditor = pkgsLinux.writeShellScriptBin "nvim-psql" ''
    nvim "$@"
    # Restore terminal after neovim's raw mode via /dev/tty (stdin may not be
    # the controlling terminal when psql calls us as an editor subprocess).
    stty sane </dev/tty 2>/dev/null || true
  '';

  entrypoint = pkgsLinux.writeShellScriptBin "entrypoint" ''
    # Fix \n → ^J in Docker: two complementary approaches.
    # 1. stty sane sets onlcr on the container PTY so the PTY driver translates
    #    \n → \r\n before Docker reads it.  Try stdin first, then /dev/tty.
    stty sane 2>/dev/null || stty sane </dev/tty 2>/dev/null || true
    # 2. ESC[20h enables LNM (Linefeed/Newline Mode) in the terminal emulator
    #    directly, so bare \n is treated as \r\n even if the PTY fix above fails
    #    (e.g. Docker Desktop on macOS strips the extra \r between VM and host).
    #    Only sent when stdout is a terminal so it doesn't pollute piped output.
    [ -t 1 ] && printf '\033[20h'

    cd /data

    command=$1
    shift

    export PSQL_EDITOR="nvim-psql"
    PG_VERSION="''${PG_VERSION:-18}"

    if [ "$PG_VERSION" = "96" ] && [ "$command" != "psql" ]; then
      echo "PostgreSQL 9.6 only supports psql"
      exit 1
    fi

    case "$command" in
      psql|pg_dump|pg_dumpall|pg_basebackup|pg_restore)
        exec "''${command}''${PG_VERSION}" "$@"
        ;;
    esac
    echo "I don't know '$command', sorry! =c/"
    exit 1
  '';

in
pkgs.dockerTools.buildImage {
  name = "okkara.net/postgresql-clients";
  tag = "latest";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = allClientPackages ++ [ pkgsLinux.bash pkgsLinux.coreutils pkgsLinuxNative.gitMinimal pkgsLinuxNative.curl pkgsLinuxNative.ripgrep neovim nvimEditor clearBin resetBin entrypoint dataDir configFiles localeArchive ];
    pathsToLink = [ "/bin" "/data" "/tmp" "/root" "/share" ];
  };
  config = {
    Entrypoint = [ "/bin/entrypoint" ];
    WorkingDir = "/data";
    Env = [ "PG_VERSION=18" "HOME=/root" "VIMRUNTIME=/share/nvim/runtime" "LANG=en_US.UTF-8" "LOCALE_ARCHIVE=/share/locale/locale-archive" ];
  };
}
