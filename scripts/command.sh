#!/usr/bin/env sh

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

docker run -i"$TERMINAL" --rm --network "$PG_NETWORK" $MOUNT_PGPASS okkara.net/postgresql"$PG_VERSION"-client "$command" "$@"
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
  docker run -i"$TERMINAL" --rm --network "$PG_NETWORK" $MOUNT_PGPASS okkara.net/postgresql"$PG_VERSION"-client "$command" "$@"
fi
