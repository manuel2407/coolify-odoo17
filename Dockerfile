FROM odoo:17

# Switch to root to install additional packages
USER root

# Install required system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gettext-base \
        curl \
        wget \
        nano \
        git \
        unzip \
        zip \
        tar \
        net-tools \
        gh \
        dnsutils \
        iputils-ping \
        && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration template and initialization script
COPY ./odoo.conf /etc/odoo/odoo.conf.template
COPY ./init.sh /init.sh

# Set executable permissions
RUN chmod +x /init.sh

# Configure healthcheck for Coolify
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -f http://localhost:8069/web/database/selector || exit 1

# Switch back to odoo user for security
USER odoo

# Use custom initialization script
CMD ["/init.sh"]