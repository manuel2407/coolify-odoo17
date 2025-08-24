FROM python:3.11-slim-bullseye

LABEL maintainer="Odoo S.A. <info@odoo.com>"

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-num2words \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
        git \
        build-essential \
        libxml2-dev \
        libxslt1-dev \
        libevent-dev \
        libsasl2-dev \
        libldap2-dev \
        libpq-dev \
        libjpeg-dev \
        libfreetype6-dev \
        zlib1g-dev \
        && \
    # Install wkhtmltopdf from official source without MD5 verification
    curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb && \
    apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    rm -rf wkhtmltox.deb && \
    rm -rf /var/lib/apt/lists/*

# Install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' > /etc/apt/sources.list.d/pgdg.list && \
    GNUPGHOME="$(mktemp -d)" && \
    export GNUPGHOME && \
    repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' && \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" && \
    gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc && \
    gpgconf --kill all && \
    rm -rf "$GNUPGHOME" && \
    apt-get update  && \
    apt-get install --no-install-recommends -y postgresql-client && \
    rm -f /etc/apt/sources.list.d/pgdg.list && \
    rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian, use npm)
RUN npm install -g rtlcss

# Install Odoo
ENV ODOO_VERSION 17.0
ARG ODOO_RELEASE=20240909
ARG ODOO_SHA=6e3d6b2e5b3f3e3b8b8b8b8b8b8b8b8b8b8b8b8b
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb && \
    dpkg --force-depends -i odoo.deb && \
    apt-get update && \
    apt-get -y install -f --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* odoo.deb

# Copy configuration
COPY ./odoo.conf /etc/odoo/
COPY ./entrypoint.sh /

# Set permissions and prepare directories
RUN chown odoo /etc/odoo/odoo.conf && \
    mkdir -p /mnt/extra-addons && \
    chown -R odoo:odoo /mnt/extra-addons && \
    chmod +x /entrypoint.sh

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /var/lib/odoo && \
    chown -R odoo:odoo /var/lib/odoo

VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
