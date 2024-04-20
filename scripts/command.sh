#!/usr/bin/env bash

SCRIPT_FOLDER=$(dirname "$(readlink -f "$0")")
SOURCE_FOLDER=$(readlink -f "$SCRIPT_FOLDER/../.")
if [ -z "$PG_ENVIRONMENT_COLORS" ];then
  PG_ENVIRONMENT_COLORS=(
    ["dev"]="bg=#183548 fg=#9df397"
    ["staging"]="bg=#0000dd fg=#dddd00"
    ["prod"]="bg=#990000 fg=#ffffff"
  )
fi

if [ -z "$PG_HOST_REGEX" ];then
  PG_HOST_REGEX='s|^([a-z]+)\..*|\1|'
fi

HOST=""
for i in "$@"
do
  if [ "$HOST" != "" ];then
    HOST=$i
    break
  fi
  case $i in
    --host*)
      HOST=$(echo "$i" | cut -f2 -d=)
      break
    ;;
    -h*)
      if [ "$i" != "-h" ];then
        HOST="${i/-h/}"
        break
      else
        HOST="SET HOST"
      fi
    ;;
  esac
  echo "$i"
done

echo "Host: $HOST"
ENV=$(echo "$HOST" | sed -E "$PG_HOST_REGEX")
echo "Env: $ENV"
for e in "${!PG_ENVIRONMENT_COLORS[@]}";do
  echo "$e = ${PG_ENVIRONMENT_COLORS[$e]}"
done
COLORS=${PG_ENVIRONMENT_COLORS[$ENV]}
echo "Colors: $COLORS"
if [ "$COLORS" = "" ];then
  COLORS='bg=#183548 fg=#9df397'
fi

change_color() {
  # change the color of the tmux pane
  if [ "$TMUX_PANE" != "" ]; then
    if [ "$1" = "" ]; then
      tmux select-pane -t "$TMUX_PANE" -P 'bg=default fg=default'
    else
      tmux select-pane -t "$TMUX_PANE" -P "$1 $2"
    fi
  fi
}

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

MOUNT_DATA=""

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

change_color "$COLORS"
docker run -i"$TERMINAL" --rm --network "$PG_NETWORK" -v"$SOURCE_FOLDER/docker/vimrc:/root/.vimrc" -v"$SOURCE_FOLDER/docker/vim:/root/.vim" $MOUNT_DATA $MOUNT_PGPASS okkara.net/postgresql"$PG_VERSION"-client "$command" "$@"
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
  docker run -i"$TERMINAL" --rm --network "$PG_NETWORK" -v"$SOURCE_FOLDER/docker/vimrc:/root/.vimrc" -v"$SOURCE_FOLDER/docker/vim:/root/.vim" $MOUNT_DATA $MOUNT_PGPASS okkara.net/postgresql"$PG_VERSION"-client "$command" "$@"
fi
change_color

