FROM odoo:17.0

USER root

# Keep runtime lean: envsubst (gettext) + psql checks + curl for healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gettext-base \
        postgresql-client \
        curl \
    && rm -rf /var/lib/apt/lists/*

COPY ./odoo.conf /etc/odoo/odoo.conf.template
COPY ./init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 8069

# Coolify healthcheck: app must actually serve HTTP
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=10 \
    CMD curl -fsS -o /dev/null http://localhost:8069/web/login || exit 1

USER odoo

CMD ["/init.sh"]
