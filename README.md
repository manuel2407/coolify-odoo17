# Odoo 17 Docker Image for Coolify

Docker Compose stack for **Odoo 17 Community Edition** on [Coolify](https://coolify.io), with an **integrated PostgreSQL 15** database.

Based on the official `odoo:17` image, plus a custom startup script, environment-driven configuration, and a Coolify-friendly healthcheck.

## Features

- Odoo 17 Community Edition
- Integrated PostgreSQL 15 (`db` service in `docker-compose.yml`)
- Wait-for-database startup with timeout
- Auto-initialization of an empty database (`base` + `web`)
- Configuration generated from environment variables (`envsubst`)
- Reverse-proxy ready (`proxy_mode = True` for Coolify / Traefik)
- Healthcheck on Odoo (`8069`) and PostgreSQL (`pg_isready`)
- Persistent volumes for Odoo data, PostgreSQL data, and custom addons

## Project Structure

```
.
├── Dockerfile           # Odoo image build definition
├── docker-compose.yml   # Odoo + PostgreSQL stack (use this in Coolify)
├── .env.example         # Example environment variables
├── odoo.conf            # Odoo config template (env placeholders)
├── init.sh              # Odoo container entrypoint / startup script
├── requirements.txt     # Optional Python packages (not installed by default)
├── addons/              # Custom addons (mounted at /mnt/extra-addons)
└── README.md
```

## Architecture

```
┌─────────────────────────────────────┐
│           docker-compose            │
│                                     │
│  ┌────────────┐    ┌─────────────┐  │
│  │    odoo    │───▶│     db      │  │
│  │  (build .) │    │ postgres:15 │  │
│  │   :8069    │    │  (internal) │  │
│  └────────────┘    └─────────────┘  │
│         │                  │        │
│   odoo-data            db-data      │
└─────────────────────────────────────┘
```

PostgreSQL is **not** baked into the Odoo image. It runs as a sibling service on the same Docker network. Deploy this project as **Docker Compose** in Coolify so both services start together.

## How Odoo Starts

On container start, `/init.sh` runs:

1. Wait for PostgreSQL (`DB_HOST` / `DB_PORT`, default timeout 120s).
2. Render `odoo.conf` from the template with `envsubst` into a writable path.
3. If the database is empty (no `ir_module_module` table), install `base` and `web`.
4. Start Odoo with the generated config.

## Coolify Deployment

### 1. Repository

Push this project to Git. Keep files at the repository root.

### 2. Create the application

1. In Coolify, create a new application.
2. Choose **Docker Compose** (required for the integrated database).
3. Connect the repository and deploy.

Do **not** deploy as Dockerfile-only if you want the bundled PostgreSQL service.

### 3. Environment variables

Copy from `.env.example` and set strong values in Coolify:

```env
DB_USER=odoo
DB_PASSWORD=your_secure_password
DB_NAME=odoo
ADMIN_PASSWD=your_super_secure_master_password
```

`DB_HOST` is set to `db` by compose and should not be changed when using the integrated database.

`ADMIN_PASSWD` is the Odoo master password for `/web/database/manager`.

### 4. Ports

| Port   | Purpose                          |
|--------|----------------------------------|
| `8069` | Odoo HTTP (expose / proxy this)  |
| `5432` | PostgreSQL (internal only)       |

### 5. Persistent volumes

| Volume / path         | Content                         |
|-----------------------|---------------------------------|
| `odoo-data` → `/var/lib/odoo` | Filestore, sessions, config |
| `db-data`             | PostgreSQL data                 |
| `./addons` → `/mnt/extra-addons` | Custom addons            |

## Local Testing

```bash
git clone <your-repository>
cd coolify-odoo17

cp .env.example .env
# edit .env with your passwords

mkdir -p addons
docker-compose up -d --build

docker-compose logs -f odoo
# Open http://localhost:8069
```

### Local defaults

| Item     | Value                    |
|----------|--------------------------|
| URL      | http://localhost:8069    |
| Database | `odoo`                   |
| Login    | `admin` / `admin`        |

Change the admin password immediately after first login.

## Using an External Database Instead

If you prefer an external PostgreSQL:

1. Remove or stop the `db` service from compose (or override it).
2. Point Odoo at your server:

```env
DB_HOST=your-postgresql-server.com
DB_PORT=5432
DB_USER=your_odoo_user
DB_PASSWORD=your_secure_password
DB_NAME=your_odoo_database
ADMIN_PASSWD=your_master_password
```

## Configuration Notes

### Generated Odoo settings

- HTTP port: `8069`
- `proxy_mode = True`
- `dbfilter` restricted to `DB_NAME`
- Addons: official path + `/mnt/extra-addons`
- Workers: `0` (adjust in `odoo.conf` for larger hosts)

### Custom addons

1. Place modules under `addons/`.
2. Restart the stack.
3. In Odoo: **Apps → Update Apps List**.

### Optional Python packages

`requirements.txt` is not installed by the current Dockerfile. Add a `pip install` step if you need those packages.

## Troubleshooting

### Odoo waits for the database then exits

1. Confirm you deployed with **Docker Compose**, not Dockerfile-only.
2. Check `docker-compose logs db`.
3. Verify `DB_USER` / `DB_PASSWORD` / `DB_NAME` match on both services.

### Cannot connect after deploy

1. Ensure volumes are persistent across redeploys.
2. Inspect `docker-compose logs odoo`.
3. Confirm Coolify proxies port `8069`.

### Addons do not appear

1. Confirm files are under `/mnt/extra-addons`.
2. Restart and update the apps list in Odoo.

## Resources

- [Odoo 17 Documentation](https://www.odoo.com/documentation/17.0/)
- [Coolify Documentation](https://coolify.io/docs)
- [PostgreSQL setup for Odoo](https://www.odoo.com/documentation/17.0/administration/install/install.html#postgresql)
