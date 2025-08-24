FROM odoo:17

# Switch to root to install additional packages
USER root

# Install additional packages if needed
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gettext-base \
        curl \
        && \
    rm -rf /var/lib/apt/lists/*

# Copy custom configuration
COPY ./odoo.conf /etc/odoo/
COPY ./entrypoint.sh /

# Set permissions
RUN chmod +x /entrypoint.sh && \
    chown odoo:odoo /etc/odoo/odoo.conf

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -f http://localhost:8069/web/database/selector || exit 1

# Switch back to odoo user
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]