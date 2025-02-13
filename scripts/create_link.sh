#!/usr/bin/env sh

scriptpath=$(dirname "$(readlink -f "$0")")
if [ "$1" = "" ];then
  echo "USAGE: $0 <psql[.version]|pg_dump[.version]|pg_dumpall[.version]|pg_restore[.version]>"
  echo "Version can be: 96, 10, 11, 12, 13, 14, 15, 16, 17"
  exit 0
fi

command=$1
version="${command##*.}"
case "$version" in
  96|10|11|12|13|14|15|16|17)
      if [ -x "$HOME/bin/$command" ];then
        echo "Link exists for $command!"
        exit 1
      fi
      ln -s "$scriptpath/command.sh" "$HOME/bin/$command"
    ;;
  psql|pg_dump|pg_dumpall|pg_restore)
      if [ -x "$HOME/bin/$command" ];then
        echo "Link exists for $command!"
        exit 1
      fi
      ln -s "$scriptpath/command.sh" "$HOME/bin/$command"
    ;;
  *)
    echo "Don't support version: $version"
    exit 2
    ;;
esac
