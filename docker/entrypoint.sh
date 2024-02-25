#!/usr/bin/env sh

command=$1
shift

case "$command" in
  ls|psql|pg_dump|pg_dumpall|pg_basebackup|pg_restore)
    "$command" "$@"
    exit 0
    ;;
esac
echo "I don't know '$command', sorry! =c/"
exit 0
