## ---------------------------------------------------------------------
## Stage 1: builder — compiles the pdo_mysql PHP extension
## ---------------------------------------------------------------------
FROM php:8.2-apache AS builder

# pdo_mysql isn't bundled by default; compile it here so the final
# stage doesn't need to carry any build tooling.
RUN docker-php-ext-install pdo_mysql

## ---------------------------------------------------------------------
## Stage 2: final — lean runtime image
## ---------------------------------------------------------------------
FROM php:8.2-apache AS final

# Pull just the compiled extension + its enabling ini from the builder
# stage, instead of re-running the build tools in the final image.
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

RUN a2enmod rewrite

WORKDIR /var/www/html

# Copy application source into Apache's document root. Only src/ goes in there,
# so the Dockerfile, entrypoint and schema are not downloadable over HTTP.
COPY src/ /var/www/html/

# DB bootstrap lives outside the document root: init-schema.php applies
# schema.sql to RDS at container start (idempotent, see the script).
COPY schema.sql init-schema.php /opt/app/

# Entrypoint script: waits for the DB, applies the schema, then starts Apache
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD php -r "exit(@fsockopen('localhost', 80) ? 0 : 1);"

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
