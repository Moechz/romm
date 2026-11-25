#!/bin/sh
# RomM wrapper entrypoint.
#
# The upstream image is built to run as root and expects its secrets in the
# environment. This package runs it as uid/gid 1000, so the wrapper
#   1. waits (up to 60 s) for the database password the MariaDB container
#      generates into the shared /run/creds volume, and exports DB_PASSWD;
#   2. creates/persists the RomM auth secret in the config volume, so sessions
#      and encrypted values survive restarts;
#   3. keeps both secrets at mode 0600 (umask 077 + explicit chmod);
#   4. hands over to the upstream entrypoint unchanged.
set -u
set -e
umask 077

F=/run/creds/db_password
i=0
while [ ! -s "$F" ] && [ "$i" -lt 60 ]; do
  i=$((i + 1))
  sleep 1
done
if [ -s "$F" ]; then
  DB_PASSWD="$(cat "$F")"
  export DB_PASSWD
else
  echo "rommdocker: $F was not created by the database container within 60s" >&2
  exit 1
fi

A=/romm/config/auth_secret
if [ ! -s "$A" ]; then
  head -c 32 /dev/urandom | base64 | tr -d '\n' > "$A"
fi
chmod 600 "$A" 2>/dev/null || true
ROMM_AUTH_SECRET_KEY="$(cat "$A")"
export ROMM_AUTH_SECRET_KEY

exec /docker-entrypoint.sh /init
