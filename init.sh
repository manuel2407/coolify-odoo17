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

# Check if database needs initialization
DB_INITIALIZED=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='ir_module_module' LIMIT 1;" 2>/dev/null || echo "")

if [ -z "$DB_INITIALIZED" ]; then
    echo "Database needs initialization. Installing base modules..."
    # Initialize database with essential modules
    /entrypoint.sh odoo -d "$DB_NAME" -i base,web --stop-after-init --no-http
    echo "Database initialization completed successfully"
fi

# Start Odoo application
echo "Starting Odoo server..."
exec /entrypoint.sh odoo
