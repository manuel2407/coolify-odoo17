#!/bin/bash
set -e

# Defaults match the integrated PostgreSQL service in docker-compose.yaml
: ${DB_HOST:=db}
: ${DB_PORT:=5432}
: ${DB_USER:=odoo}
: ${DB_NAME:=odoo}
: ${DB_PASSWORD:=odoo_password}
: ${ADMIN_PASSWD:=changeme}
: ${DB_WAIT_TIMEOUT:=120}

echo "Waiting for database at ${DB_HOST}:${DB_PORT} (timeout: ${DB_WAIT_TIMEOUT}s)..."
elapsed=0
until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; do
    if [ "$elapsed" -ge "$DB_WAIT_TIMEOUT" ]; then
        echo "ERROR: Database is still unavailable after ${DB_WAIT_TIMEOUT}s" >&2
        exit 1
    fi
    echo "Database is unavailable - sleeping" >&2
    sleep 1
    elapsed=$((elapsed + 1))
done

echo "Database is up - preparing configuration" >&2

# Prefer a writable config path (odoo user may not write to /etc/odoo)
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
