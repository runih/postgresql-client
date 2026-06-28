{ pkgs ? import <nixpkgs> {} }:

let
  mkPsqlClients = majorVersion: version: sha256:
    pkgs.stdenv.mkDerivation {
      pname = "postgresql-clients-${majorVersion}";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://ftp.postgresql.org/pub/source/v${version}/postgresql-${version}.tar.bz2";
        inherit sha256;
      };
      nativeBuildInputs = (with pkgs.buildPackages; [ bison flex perl pkg-config ]);
      buildInputs = [ pkgs.icu pkgs.readline pkgs.zlib pkgs.openssl ];
      configureFlags = [ "--without-server" "--with-openssl" "--disable-thread-safety" ];
      preConfigure = ''
        export ac_cv_file__dev_urandom=yes
        export CFLAGS="''${CFLAGS:+$CFLAGS }-std=c17"
      '';
      buildPhase = ''
        make -C src/interfaces/libpq
        [ -d src/fe_utils ] && make -C src/fe_utils
        make -C src/bin/psql
        make -C src/bin/pg_dump
        make -C src/bin/pg_basebackup
      '';
      installPhase = ''
        mkdir -p $out/bin $out/lib
        cp src/bin/psql/psql $out/bin/psql${majorVersion}
        cp src/bin/pg_dump/pg_dump $out/bin/pg_dump${majorVersion}
        cp src/bin/pg_dump/pg_dumpall $out/bin/pg_dumpall${majorVersion}
        cp src/bin/pg_dump/pg_restore $out/bin/pg_restore${majorVersion}
        [ -f src/bin/pg_basebackup/pg_basebackup ] && \
          cp src/bin/pg_basebackup/pg_basebackup $out/bin/pg_basebackup${majorVersion}
        cp -a src/interfaces/libpq/libpq.so* $out/lib/
      '';
    };

  versions = [
    { major = "96"; version = "9.6.24"; sha256 = "1kiak2pgri79kd4afzflil87q612jzrnbxbf8ykx3giypsba3dxf"; }
    { major = "10"; version = "10.23"; sha256 = "1sgfssjc9lnzijhn108r6z26fri655k413f1c9b8wibjhd9b594l"; }
    { major = "11"; version = "11.22"; sha256 = "1w71xf97i3hha6vl05xqf960k75nczs6375w3f2phwhdg9ywkdrc"; }
    { major = "12"; version = "12.17"; sha256 = "1xn5q7cnbnrfdr3gm53ivgj1qk0q51xzfqspdhyg1mc176rf3s4k"; }
    { major = "13"; version = "13.13"; sha256 = "0x546w5hi2cpkr33x32djlbg3bii87n6hzan8v92lyh4k4jrrxla"; }
    { major = "14"; version = "14.10"; sha256 = "16c3ri77g9w4695xrd1g1h9ikkd384hynimr186hniwxiv233569"; }
    { major = "15"; version = "15.5"; sha256 = "19hhkcyb4h7m8aimmxmllfxl4fvrhy0vcipa6qjyif4fsyasllwg"; }
    { major = "16"; version = "16.3"; sha256 = "1185wrj8fldr26a8a586ff6cnsvdnr0gljd02r1ayk6wsgan669k"; }
    { major = "17"; version = "17.0"; sha256 = "1ph9j60nxwcslpdji4q0snc3932bn8xrpbfvi0jvdmpxq0qn29vy"; }
    { major = "18"; version = "18.0"; sha256 = "0y30dppgv03p9ry3bcb68arkwxrkk58hg5dalyy63qsz3qxr0nqd"; }
  ];

in
builtins.listToAttrs (map (v: {
  name = "psql_${v.major}";
  value = mkPsqlClients v.major v.version v.sha256;
}) versions)
