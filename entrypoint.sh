#!/bin/bash

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

# Allow the container to be started with `--user`
if [ "$1" = 'odoo' ] && [ "$(id -u)" = '0' ]; then
    exec gosu odoo "$0" "$@"
fi

# Set default values for database connection
: ${DB_HOST:=db}
: ${DB_PORT:=5432}
: ${DB_USER:=odoo}
: ${DB_NAME:=postgres}

# Support Docker secrets
file_env 'DB_PASSWORD'

# Wait for database to be ready
if [ "$1" = 'odoo' ]; then
    echo "Waiting for database connection..."
    until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q'; do
        >&2 echo "Database is unavailable - sleeping"
        sleep 1
    done
    
    >&2 echo "Database is up - executing command"
    
    # Replace environment variables in odoo.conf
    envsubst < /etc/odoo/odoo.conf > /tmp/odoo.conf
    cp /tmp/odoo.conf /etc/odoo/odoo.conf
fi

# Initialize database if needed
if [ "$1" = 'odoo' ]; then
    # Check if database exists and has tables
    DB_EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='ir_module_module' LIMIT 1;" 2>/dev/null || echo "")
    
    if [ -z "$DB_EXISTS" ]; then
        echo "Database appears to be empty, initializing Odoo database..."
        exec odoo -d "$DB_NAME" -i base --stop-after-init --no-http
        echo "Database initialization completed"
    fi
fi

# Execute the main command
exec "$@"
