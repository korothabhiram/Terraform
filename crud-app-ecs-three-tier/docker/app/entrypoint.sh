#!/bin/sh
set -e

# If DB_HOST is set, wait for the database to start accepting connections
# before handing off to Apache. This avoids the classic race where the app
# container starts faster than the database and every request 500s at boot.
if [ -n "$DB_HOST" ]; then
    DB_PORT="${DB_PORT:-3306}"
    echo "Waiting for MySQL at $DB_HOST:$DB_PORT..."

    until php -r "exit(@fsockopen('$DB_HOST', $DB_PORT) ? 0 : 1);" 2>/dev/null; do
        sleep 1
    done

    echo "MySQL is up - continuing startup"

    # On ECS the database is RDS, which (unlike the mysql image in
    # docker-compose) does not run schema.sql for us. Every task runs this; it
    # is idempotent and serialised with a MySQL advisory lock.
    if [ "${DB_INIT_SCHEMA:-false}" = "true" ]; then
        php /opt/app/init-schema.php /opt/app/schema.sql
    fi
fi

# Hand off to the container's CMD (apache2-foreground by default)
exec "$@"
