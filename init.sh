#!/bin/bash
set -e

# ------------------------------------------------------------------------------
# Plug-and-play defaults
#
# The official Odoo 17 entrypoint expects these env vars:
#   HOST, PORT, USER, PASSWORD
# Our config/compose uses DB_* names; map them here so both paths agree.
# ------------------------------------------------------------------------------

: ${DB_HOST:=db}
: ${DB_PORT:=5432}
: ${DB_USER:=odoo}
: ${DB_NAME:=odoo}
: ${DB_WAIT_TIMEOUT:=120}

# Map DB_* to the names the official entrypoint uses
: ${HOST:=$DB_HOST}
: ${PORT:=$DB_PORT}
: ${USER:=$DB_USER}

# Read *_FILE secrets if present
if [ -n "$DB_PASSWORD_FILE" ] && [ -f "$DB_PASSWORD_FILE" ] && [ -z "$DB_PASSWORD" ]; then
  DB_PASSWORD="$(cat "$DB_PASSWORD_FILE")"
fi
if [ -n "$ADMIN_PASSWD_FILE" ] && [ -f "$ADMIN_PASSWD_FILE" ] && [ -z "$ADMIN_PASSWD" ]; then
  ADMIN_PASSWD="$(cat "$ADMIN_PASSWD_FILE")"
fi

# Auto-generate missing secrets for plug-and-play (print once to logs)
if [ -z "$DB_PASSWORD" ]; then
  DB_PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"
  echo "==> DB_PASSWORD was not set; generated random value (must match POSTGRES_PASSWORD in db service):" >&2
  echo "DB_PASSWORD=${DB_PASSWORD}" >&2
fi
if [ -z "$ADMIN_PASSWD" ]; then
  ADMIN_PASSWD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"
  echo "==> ADMIN_PASSWD was not set; generated random value:" >&2
  echo "ADMIN_PASSWD=${ADMIN_PASSWD}" >&2
fi

: ${PASSWORD:=$DB_PASSWORD}

export HOST PORT USER PASSWORD DB_NAME DB_PASSWORD ADMIN_PASSWD

echo "Waiting for database at ${HOST}:${PORT} (timeout: ${DB_WAIT_TIMEOUT}s)..."
elapsed=0
until PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB_NAME" -c '\q' 2>/dev/null; do
    if [ "$elapsed" -ge "$DB_WAIT_TIMEOUT" ]; then
        echo "ERROR: Database is still unavailable after ${DB_WAIT_TIMEOUT}s" >&2
        echo "Hint: in docker-compose, POSTGRES_PASSWORD must equal DB_PASSWORD." >&2
        exit 1
    fi
    echo "Database is unavailable - sleeping" >&2
    sleep 1
    elapsed=$((elapsed + 1))
done

echo "Database is up - preparing configuration" >&2

# Writable config path (odoo user cannot write /etc/odoo at runtime)
CONFIG_FILE=/var/lib/odoo/odoo.conf
if ! touch "$CONFIG_FILE" 2>/dev/null; then
    CONFIG_FILE=/tmp/odoo.conf
fi

# Render template using DB_* names in odoo.conf
envsubst < /etc/odoo/odoo.conf.template > "$CONFIG_FILE"

DB_INITIALIZED=$(PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB_NAME" -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='ir_module_module' LIMIT 1;" 2>/dev/null || echo "")

if [ -z "$DB_INITIALIZED" ]; then
    echo "Database needs initialization. Installing base modules..."
    /entrypoint.sh odoo -c "$CONFIG_FILE" -d "$DB_NAME" -i base,web --stop-after-init --no-http
    echo "Database initialization completed successfully"
fi

echo "Starting Odoo server..."
exec /entrypoint.sh odoo -c "$CONFIG_FILE"
