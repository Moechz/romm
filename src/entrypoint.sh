#!/bin/sh
set -u
set -e
F=/run/creds/db_password
if [ -s "$F" ]; then export DB_PASSWD="$(cat "$F")"; fi
A=/romm/config/auth_secret
if [ ! -s "$A" ]; then head -c 32 /dev/urandom | base64 | tr -d '\n' > "$A"; fi
export ROMM_AUTH_SECRET_KEY="$(cat "$A")"
exec /docker-entrypoint.sh /init
