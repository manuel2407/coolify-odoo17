#!/bin/bash
set -e

# ------------------------------------------------------------------------------
# Plug-and-play defaults
#
# Works out of the box with docker-compose (integrated PostgreSQL).
# In Coolify, prefer setting real values via environment variables:
#   DB_PASSWORD, ADMIN_PASSWD (or *_FILE secrets)
# If not set, secure random values are generated once per container start and
# printed to logs so you can copy them into Coolify.
# ------------------------------------------------------------------------------

: ${DB_HOST:=db}
: ${DB_PORT:=5432}
: ${DB_USER:=odoo}
: ${DB_NAME:=odoo}
: ${DB_WAIT_TIMEOUT:=120}

# Read *_FILE secrets if present (Docker/Coolify secrets pattern)
if [ -n "$DB_PASSWORD_FILE" ] && [ -f "$DB_PASSWORD_FILE" ] && [ -z "$DB_PASSWORD" ]; then
  DB_PASSWORD="$(cat "$DB_PASSWORD_FILE")"
fi
if [ -n "$ADMIN_PASSWD_FILE" ] && [ -f "$ADMIN_PASSWD_FILE" ] && [ -z "$ADMIN_PASSWD" ]; then
  ADMIN_PASSWD="$(cat "$ADMIN_PASSWD_FILE")"
fi

# Auto-generate missing secrets for true plug-and-play
if [ -z "$DB_PASSWORD" ]; then
  DB_PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"
  echo "==> DB_PASSWORD was not set; generated random value (also needed by db service):" >&2
  echo "DB_PASSWORD=${DB_PASSWORD}" >&2
fi
if [ -z "$ADMIN_PASSWD" ]; then
  ADMIN_PASSWD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"
  echo "==> ADMIN_PASSWD was not set; generated random value:" >&2
  echo "ADMIN_PASSWD=${ADMIN_PASSWD}" >&2
fi

export DB_HOST DB_PORT DB_USER DB_NAME DB_PASSWORD ADMIN_PASSWD

echo "Waiting for database at ${DB_HOST}:${DB_PORT} (timeout: ${DB_WAIT_TIMEOUT}s)..."
elapsed=0
until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; do
    if [ "$elapsed" -ge "$DB_WAIT_TIMEOUT" ]; then
        echo "ERROR: Database is still unavailable after ${DB_WAIT_TIMEOUT}s" >&2
        echo "Hint: if using docker-compose, ensure POSTGRES_PASSWORD matches DB_PASSWORD." >&2
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

envsubst < /etc/odoo/odoo.conf.template > "$CONFIG_FILE"

DB_INITIALIZED=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='ir_module_module' LIMIT 1;" 2>/dev/null || echo "")

if [ -z "$DB_INITIALIZED" ]; then
    echo "Database needs initialization. Installing base modules..."
    /entrypoint.sh odoo -c "$CONFIG_FILE" -d "$DB_NAME" -i base,web --stop-after-init --no-http
    echo "Database initialization completed successfully"
fi

echo "Starting Odoo server..."
exec /entrypoint.sh odoo -c "$CONFIG_FILE"
