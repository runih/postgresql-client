#!/usr/bin/env sh

# Change to the data directory
cd /data

command=$1
shift

export PSQL_EDITOR="/usr/bin/vim"

# Postgresql Client v96 only supports psql
if [ -f /PostgreSQL96.txt ] && [ "$command" != "psql" ];then
  cat /PostgreSQL96.txt
  exit 1
fi

case "$command" in
  psql|pg_dump|pg_dumpall|pg_basebackup|pg_restore)
    "$command" "$@"
    exit 0
    ;;
esac
echo "I don't know '$command', sorry! =c/"
exit 1
