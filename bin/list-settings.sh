#! /bin/sh
#
#
if [ $# -lt 1 ]
then
  echo "specify some files" >&2
  exit 1
fi

grep -E -h '[^_]read_[a-z0-9_]*setting \"' "$@" | \
   sed 's/^[^`]*`\(.*\)$/\1/' | \
   sed 's/^[ \t]*\(.*\)/\1/'  | \
   LC_ALL=C sort | \
   LC_ALL=C sort -u