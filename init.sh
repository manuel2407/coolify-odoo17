#!/bin/bash
set -e

# Set default values for database connection
: ${DB_HOST:=db}
: ${DB_PORT:=5432}
: ${DB_USER:=odoo}
: ${DB_NAME:=postgres}

echo "Waiting for database connection..."
until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; do
    >&2 echo "Database is unavailable - sleeping"
    sleep 1
done

>&2 echo "Database is up - preparing configuration"

# Process configuration template with environment variables
envsubst < /etc/odoo/odoo.conf.template > /etc/odoo/odoo.conf

# Start Odoo with the original entrypoint
exec /entrypoint.sh odoo
