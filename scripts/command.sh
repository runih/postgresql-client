#!/usr/bin/env bash

SCRIPT_FOLDER=$(dirname "$(readlink -f "$0")")
SOURCE_FOLDER=$(readlink -f "$SCRIPT_FOLDER/../.")

DOCKER_CONTEXT=""
if [ "$PG_DOCKER_CONTEXT" != "" ];then
  DOCKER_CONTEXT="--context $PG_DOCKER_CONTEXT"
fi

if [ "$1" = "--update" ];then
  cd "$SOURCE_FOLDER" || exit 1
  git pull
  echo "Rebuilding Docker image with Nix..."
  docker $DOCKER_CONTEXT rmi "okkara.net/postgresql-clients" > /dev/null 2>&1 || true
  docker load < "$(nix-build "$SOURCE_FOLDER/docker-image.nix" --no-out-link)"
  exit 0
fi

if [ -z "$PG_VERSION" ];then
  PG_VERSION=18
fi

if [ -z "$PG_NETWORK" ];then
  PG_NETWORK=bridge
fi

if [ -z "$PG_PASS" ];then
  MOUNT_PGPASS=""
else
  MOUNT_PGPASS="-v$PG_PASS:/root/.pgpass"
fi

if [ -z "$PG_HISTORY" ];then
  PG_HISTORY="$HOME/.psql_history"
fi
[ -e "$PG_HISTORY" ] || touch "$PG_HISTORY"
MOUNT_PGHISTORY="-v$PG_HISTORY:/root/.psql_history"

if [ -z "$PG_CERTFOLDER" ];then
  MOUNT_PGCERTFOLDER=""
else
  MOUNT_PGCERTFOLDER="-v$PG_CERTFOLDER:/certs"
fi

MOUNT_DATA=""

if [ -z "PG_SSLCERT" ];then
  ENV_PGSSLCERT=""
else
  ENV_PGSSLCERT="-e PGSSLCERT=/certs/$PG_SSLCERT"
fi

if [ -z "PG_SSLKEY" ];then
  ENV_PGSSLKEY=""
else
  ENV_PGSSLKEY="-e PGSSLKEY=/certs/$PG_SSLKEY"
fi

if [ -z "PG_SSLROOTCERT" ];then
  ENV_PGSSLROOTCERT=""
else
  ENV_PGSSLROOTCERT="-e PGSSLROOTCERT=/certs/$PG_SSLROOTCERT"
fi

if [ -z "$PG_SSLMODE" ]; then
  PG_SSLMODE="require"
fi
ENV_PGSSLMODE="-e PGSSLMODE=$PG_SSLMODE"

if [ -t 0 ];then
  TERMINAL="t"
else
  TERMINAL=""
fi

command=$(basename "$0")
version="${command##*.}"
case "$version" in
  96|10|11|12|13|14|15|16|17|18)
    command="${command%.*}"
    PG_VERSION="$version"
    ;;
esac

case "$command" in
  pg_dump|pg_dumpall|pg_basebackup|pg_restore)
    if [ -z "$PG_DATA" ];then
      echo "PG_DATA is not set"
      exit 1
    fi

    if [ ! -d "$PG_DATA" ];then
      echo "PG_DATA is not a directory!"
      exit 2
    fi
    ;;
esac

if [ "$PG_DATA" != "" ];then
  MOUNT_DATA="-v$PG_DATA:/data"
fi

# Docker mounting points
MOUNTS="$MOUNT_DATA $MOUNT_PGPASS $MOUNT_PGHISTORY $MOUNT_PGCERTFOLDER"
# Docker environments
ENVS="$ENV_PGSSLCERT $ENV_PGSSLKEY $ENV_PGSSLROOTCERT $ENV_PGSSLMODE -e PSQL_HISTORY=/root/.psql_history -e HOME=/root -e PSQLRC=/root/.psqlrc"

docker $DOCKER_CONTEXT run -i"$TERMINAL" --rm --network "$PG_NETWORK" -v"$SOURCE_FOLDER/neovim:/root/.config/nvim" $MOUNTS $ENVS -e PG_VERSION="$PG_VERSION" okkara.net/postgresql-clients "$command" "$@"
error=$?
# Docker's MakeRaw leaves the host terminal in raw mode on abnormal exit.
stty sane 2>/dev/null || true
if [ $error = 125 ];then
  echo "$error: Docker image missing"
  echo "Building Docker image with Nix (this may take a while)..."
  docker load < "$(nix-build "$SOURCE_FOLDER/docker-image.nix" --no-out-link)"
  docker $DOCKER_CONTEXT run -i"$TERMINAL" --rm --network "$PG_NETWORK" -v"$SOURCE_FOLDER/neovim:/root/.config/nvim" $MOUNTS $ENVS -e PG_VERSION="$PG_VERSION" okkara.net/postgresql-clients "$command" "$@"
  stty sane 2>/dev/null || true
fi
