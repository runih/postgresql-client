#!/usr/bin/env bash

SCRIPT_FOLDER=$(dirname "$(readlink -f "$0")")
SOURCE_FOLDER=$(readlink -f "$SCRIPT_FOLDER/../.")

if [ "$1" = "--update" ];then
  cd "$SOURCE_FOLDER" || exit 1
  git pull
  SHA=$(cat $SOURCE_FOLDER/docker/Dockerfile.v* "$SOURCE_FOLDER/docker/entrypoint.sh" "$SOURCE_FOLDER/docker/inputrc" "$SOURCE_FOLDER/docker/PostgreSQL96.txt" "$SOURCE_FOLDER/docker/psqlrc" | sha1sum | cut -f 1 -d\ )
  if [ ! -f "$SOURCE_FOLDER/.sha.txt" ] || [ "$SHA" != "$(cat "$SOURCE_FOLDER/.sha.txt")" ];then
    IMAGES=(
      "postgresql96-client"
      "postgresql10-client"
      "postgresql11-client"
      "postgresql12-client"
      "postgresql13-client"
      "postgresql14-client"
      "postgresql15-client"
      "postgresql16-client"
    )
    echo -n "Remove old images..."
    for image in "${IMAGES[@]}"; do
      docker rmi "okkara.net/$image" > /dev/null 2>&1
    done
    echo "Done"
    echo -n "$SHA" > "$SOURCE_FOLDER/.sha.txt"
  fi
  exit 0
fi

if [ -z "$PG_VERSION" ];then
  PG_VERSION=16
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
  MOUNT_PGHISTORY=""
else
  MOUNT_PGHISTORY="-v$PG_HISTORY:/root/.psql_history"
fi

if [ -z "$PG_CERTFOLDER" ];then
  MOUNT_PGCERTFOLDER=""
else
  MOUNT_PGCERTFOLDER="-V $PG_CERTFOLDER:/certs"
fi

MOUNT_DATA=""

if [ -z "PG_SSLCERT" ];then
  ENV_PGSSLCERT=""
else
  ENV_PGSSLCERT="-e PGSSLCERT=$PG_SSLCERT"
fi

if [ -z "PG_SSLKEY" ];then
  ENV_PGSSLKEY=""
else
  ENV_PGSSLKEY="-e PGSSLKEY=$PG_SSLKEY"
fi

if [ -z "PG_SSLROOTCERT" ];then
  ENV_PGSSLROOTCERT=""
else
  ENV_PGSSLROOTCERT="-e PGSSLROOTCERT=$PG_SSLROOTCERT"
fi


# Docker mounting points
MOUNTS="$MOUNT_DATA $MOUNT_PGPASS $MOUNT_PGHISTORY $MOUNT_PGCERTFOLDER"
# Docker environments
ENVS="$ENV_PGSSLCERT $ENV_PGSSLKEY $ENV_PGSSLROOTCERT"

if [ -t 0 ];then
  TERMINAL="t"
else
  TERMINAL=""
fi

command=$(basename "$0")
version="${command##*.}"
case "$version" in
  96|10|11|12|13|14|15|16)
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

docker run -i"$TERMINAL" --rm --network "$PG_NETWORK" -v"$SOURCE_FOLDER/docker/vimrc:/root/.vimrc" -v"$SOURCE_FOLDER/docker/vim:/root/.vim" $MOUNTS okkara.net/postgresql"$PG_VERSION"-client "$command" "$@"
error=$?
if [ $error = 125 ];then
  echo "$error: Docker image missing"
  script=$(readlink "$0")
  scriptpath=$(dirname "$script")
  dockerpath="$scriptpath/../docker"
  echo "Script: $script"
  echo "Scriptpath: $scriptpath"
  echo "Dockerpath: $dockerpath"
  cd "$dockerpath" || exit 1
  docker build -t okkara.net/postgresql"$PG_VERSION"-client -f Dockerfile.v"$PG_VERSION" .
  docker run -i"$TERMINAL" --rm --network "$PG_NETWORK" -v"$SOURCE_FOLDER/docker/vimrc:/root/.vimrc" -v"$SOURCE_FOLDER/docker/vim:/root/.vim" $MOUNTS $ENVS okkara.net/postgresql"$PG_VERSION"-client "$command" "$@"
fi
