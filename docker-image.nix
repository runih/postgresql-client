{ pkgs ? import <nixpkgs> {} }:

let
  pkgsLinux = pkgs.pkgsCross.aarch64-multiplatform;

  clients = import ./postgresql-client.nix { pkgs = pkgsLinux; };
  allClientPackages = builtins.attrValues clients;

  dataDir = pkgs.runCommand "data-dir" {} ''
    mkdir -p $out/data $out/tmp
  '';

  configFiles = pkgs.runCommand "psql-config-files" {} ''
    mkdir -p $out/root
    cp ${./docker/psqlrc} $out/root/.psqlrc
    cp ${./docker/inputrc} $out/root/.inputrc
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

  entrypoint = pkgsLinux.writeShellScriptBin "entrypoint" ''
    cd /data

    command=$1
    shift

    export PSQL_EDITOR="nvim"
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
    paths = allClientPackages ++ [ pkgsLinux.bash pkgsLinux.coreutils neovim entrypoint dataDir configFiles ];
    pathsToLink = [ "/bin" "/data" "/tmp" "/root" "/share" ];
  };
  config = {
    Entrypoint = [ "/bin/entrypoint" ];
    WorkingDir = "/data";
    Env = [ "PG_VERSION=18" "HOME=/root" "VIMRUNTIME=/share/nvim/runtime" ];
  };
}
