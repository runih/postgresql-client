{ pkgs ? import <nixpkgs> {} }:

let
  isDarwin = pkgs.stdenv.isDarwin;

  # Cross-compile to aarch64-linux when building from macOS.
  # On Linux, build natively for the host architecture instead.
  pkgsLinux = if isDarwin
    then pkgs.pkgsCross.aarch64-multiplatform
    else pkgs;

  # On macOS, packages that execute target-arch binaries during build
  # are sourced from a native aarch64-linux evaluation so Nix fetches
  # pre-built substitutes from cache.nixos.org instead.
  # On Linux, native packages work fine.
  pkgsLinuxNative = if isDarwin
    then import <nixpkgs> {
      system = "aarch64-linux";
      config.allowUnsupportedSystem = true;
    }
    else pkgs;

  # On macOS, the tic tool emits hex-encoded subdirectory names (e.g. 78/xterm)
  # to avoid case-collision on the case-insensitive filesystem, but the
  # cross-compiled Linux ncurses binary uses the standard single-char lookup
  # (x/xterm). On Linux, terminfo is already in single-char format.
  terminfo = pkgs.runCommand "terminfo" {} (
    if isDarwin then ''
      mkdir -p $out/share/terminfo
      for hexdir in ${pkgsLinux.ncurses}/share/terminfo/*/; do
        hexname=$(basename "$hexdir")
        # Only process 2-char hex names
        echo "$hexname" | grep -qE '^[0-9a-f]{2}$' || continue
        charcode=$((16#$hexname))
        # Skip non-printable and uppercase A-Z (65-90) to avoid macOS conflicts
        [ $charcode -lt 32 ] || [ $charcode -gt 126 ] && continue
        [ $charcode -ge 65 ] && [ $charcode -le 90 ] && continue
        char=$(printf "\\$(printf '%03o' $charcode)")
        mkdir -p "$out/share/terminfo/$char"
        for f in "$hexdir"*; do
          [ -e "$f" ] || continue
          cp -L "$f" "$out/share/terminfo/$char/" 2>/dev/null || cp "$f" "$out/share/terminfo/$char/"
        done
      done
    ''
    else ''
      mkdir -p $out/share/terminfo
      cp -r ${pkgsLinux.ncurses}/share/terminfo/. $out/share/terminfo/
    ''
  );

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

  # On macOS, fetch and patch a pre-built aarch64 neovim tarball (cross-compiled
  # binaries need their ELF interpreter set to the Nix-managed glibc path).
  # On Linux, use nixpkgs' neovim built natively for the host architecture.
  neovim = if isDarwin
    then pkgs.runCommand "neovim-0.12.0" {
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
    ''
    else pkgsLinux.neovim;

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
    stty sane 2>/dev/null || stty sane </dev/tty 2>/dev/null || true

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
    paths = allClientPackages ++ [ pkgsLinux.bash pkgsLinux.coreutils pkgsLinuxNative.gitMinimal pkgsLinuxNative.curl pkgsLinuxNative.ripgrep neovim clearBin resetBin nvimEditor entrypoint dataDir configFiles localeArchive terminfo ];
    pathsToLink = [ "/bin" "/data" "/tmp" "/root" "/share" ];
  };
  config = {
    Entrypoint = [ "/bin/entrypoint" ];
    WorkingDir = "/data";
    Env = [ "PG_VERSION=18" "HOME=/root" "VIMRUNTIME=/share/nvim/runtime" "LANG=en_US.UTF-8" "LOCALE_ARCHIVE=/share/locale/locale-archive" "TERMINFO=/share/terminfo" ];
  };
}
