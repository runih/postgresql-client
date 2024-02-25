#!/usr/bin/env sh

if [ -z "$PG_VERSION" ];then
  PG_VERSION=16
fi



command=$(basename "$0")
version="${command##*.}"
case "$version" in
  96|10|11|12|13|14|15|16)
    command="${command%.*}"
    PG_VERSION="$version"
    ;;
esac

docker run -it --rm okkara.net/postgresql"$PG_VERSION"-client "$command" "$@"
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
  docker run -it --rm okkara.net/postgresql"$PG_VERSION"-client "$command" "$@"
fi
