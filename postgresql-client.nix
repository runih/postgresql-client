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
      # --disable-thread-safety skips configure's thread test (a run-test that
      # aborts native Nix-sandbox builds). Honored on <= 15, ignored on 16+.
      # Harmless for these single-threaded CLI tools.
      configureFlags = [ "--without-server" "--with-openssl" "--disable-thread-safety" ];
      # EOL releases (9.6/10/11) never received the upstream libpq fix that 12+
      # carry: they stash the PGconn pointer in the BIO's internal data field
      # (BIO_set_data/BIO_get_data), which OpenSSL 3.x uses for its own socket
      # BIO -> the collision corrupts the heap during the TLS handshake, so
      # sslmode=require crashes ("no user name specified" + free(): invalid
      # pointer). Backport the fix: use the separate app-data slot instead.
      postPatch = pkgs.lib.optionalString (builtins.elem majorVersion [ "96" "10" "11" ]) ''
        substituteInPlace src/interfaces/libpq/fe-secure-openssl.c \
          --replace 'BIO_get_data(h)' 'BIO_get_app_data(h)' \
          --replace 'BIO_set_data(bio, conn)' 'BIO_set_app_data(bio, conn)'
      '';
      preConfigure = ''
        export ac_cv_file__dev_urandom=yes
        # GCC 15 defaults to -std=gnu23, whose bool/true/false keywords collide
        # with PostgreSQL's `typedef char bool` (<= 14). Pin to gnu17: same C17
        # standard, but WITHOUT __STRICT_ANSI__, so glibc keeps exposing its
        # _DEFAULT_SOURCE/_GNU_SOURCE prototypes (e.g. strdup, getpwuid_r).
        # Strict -std=c17 sets __STRICT_ANSI__, which hides those prototypes ->
        # implicit declarations truncate 64-bit pointer returns to int -> heap
        # corruption (free(): invalid pointer, mangled username in startup pkt).
        # gnu17 is a superset of what every version already compiled under (c17),
        # so it is applied uniformly rather than reverting newer versions to gnu23.
        export CFLAGS="''${CFLAGS:+$CFLAGS }-std=gnu17"
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
    { major = "12"; version = "12.22"; sha256 = "0fvsaba7vrkjdqyc3nvf11ld255xn4rm2jrpdwy9sn428x3w1wwd"; }
    { major = "13"; version = "13.23"; sha256 = "1mhz0h7b3dmc0nnxz1wp46j95jhyi3girykkr3gbg4mg4qkwihvf"; }
    { major = "14"; version = "14.23"; sha256 = "19clihp73ak2p5di90jhg50lqjkkr0iy349gkki30qsl5f11cwnc"; }
    { major = "15"; version = "15.18"; sha256 = "1d13qckpslfqamdmp23q3rbzxlp1rqwszylilyllpsp3gzwhvpqi"; }
    { major = "16"; version = "16.3"; sha256 = "1185wrj8fldr26a8a586ff6cnsvdnr0gljd02r1ayk6wsgan669k"; }
    { major = "17"; version = "17.0"; sha256 = "1ph9j60nxwcslpdji4q0snc3932bn8xrpbfvi0jvdmpxq0qn29vy"; }
    { major = "18"; version = "18.0"; sha256 = "0y30dppgv03p9ry3bcb68arkwxrkk58hg5dalyy63qsz3qxr0nqd"; }
  ];

in
builtins.listToAttrs (map (v: {
  name = "psql_${v.major}";
  value = mkPsqlClients v.major v.version v.sha256;
}) versions)
