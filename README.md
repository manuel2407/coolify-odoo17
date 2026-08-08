# Odoo 17 for Coolify — Plug & Play

Production-ready **Odoo 17 Community** stack for [Coolify](https://coolify.io) with an **integrated PostgreSQL 15** database.

Goal: **deploy once, set a domain, done.**

## What “plug and play” means here

- Deploys as **Docker Compose** (Odoo + PostgreSQL in one project).
- Requires **only two secrets**: `DB_PASSWORD` and `ADMIN_PASSWD`.
- Everything else has safe defaults; database is initialized automatically.
- Coolify assigns the domain; Odoo is proxied on port `8069`.

## Quick start (Coolify)

1. **Push this repo** to Git.
2. In Coolify, create a new application → **Docker Compose** → connect the repo.
3. **Environment Variables** (or a `.env`):

```env
DB_PASSWORD=your_db_password
ADMIN_PASSWD=your_master_password
```

4. **Domain:** in the `odoo` service, set your domain (e.g. `https://odoo.example.com`) **or** set `DOMAIN=https://odoo.example.com`.
5. Deploy. First run installs `base` and `web`; Odoo is then ready on your domain.

### Odoo admin login

- Login: `admin` / `admin` (change it after first login).
- Master password (for `/web/database/manager`): your `ADMIN_PASSWD`.

## Optional

| Variable   | Default | Notes                                    |
|------------|---------|------------------------------------------|
| `DB_USER`  | `odoo`  | PostgreSQL user                          |
| `DB_NAME`  | `odoo`  | Database name                            |
| `DB_HOST`  | `db`    | Only change for an **external** database |

Secrets via files are supported: `DB_PASSWORD_FILE`, `ADMIN_PASSWD_FILE`.

## Local

```bash
cp .env.example .env
# edit .env passwords
docker compose up -d --build
# http://localhost:8069
```

## External database

To use your own PostgreSQL instead of the bundled one:

- Remove/stop the `db` service.
- Set `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` to your server.

## Structure

```
.
├── Dockerfile            # Odoo image
├── docker-compose.yaml   # Odoo + PostgreSQL (deploy this in Coolify)
├── .env.example          # Required variables
├── odoo.conf             # Odoo config template (env-driven)
├── init.sh               # Startup: wait DB, render config, init, run
└── addons/               # Custom addons -> /mnt/extra-addons
```

## Notes

- `proxy_mode` is enabled for Coolify/Traefik.
- `list_db` is `False`; `dbfilter` restricts Odoo to your `DB_NAME`.
- PostgreSQL is **not** exposed to the host by default.

## Troubleshooting

**Odoo exits waiting for database**  
Make sure `DB_PASSWORD` matches on both services and is set in Coolify (or `.env`).

**No domain assigned**  
Set the domain on the `odoo` service in Coolify (or `DOMAIN=...`), and ensure the server has a wildcard domain if you want automatic generation.
