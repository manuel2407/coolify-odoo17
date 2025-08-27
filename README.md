# Odoo 17 Docker Image for Coolify

This Docker image is optimized to run Odoo 17 on Coolify with an external database.

## Features

- ✅ Odoo 17 Community Edition
- ✅ All necessary dependencies included
- ✅ Optimized configuration for external database
- ✅ Full environment variables support
- ✅ Automatic initialization script
- ✅ Persistent volumes for addons and data
- ✅ Proxy configuration for reverse proxies
- ✅ Docker secrets support

## Project Structure

```
odoo17/
├── Dockerfile              # Main Odoo 17 image
├── docker-compose.yml      # For local testing
├── odoo.conf              # Odoo configuration
├── init.sh                # Initialization script
├── requirements.txt       # Additional Python dependencies
├── addons/                # Directory for custom addons (create if needed)
└── README.md              # This file
```

## Coolify Deployment

### 1. Repository Setup

1. Upload this project to your Git repository (GitHub, GitLab, etc.)
2. Make sure all files are in the repository root

### 2. Coolify Configuration

1. **Create new application:**
   - Go to your Coolify panel
   - Create a new application
   - Select "Docker Compose" or "Dockerfile"
   - Connect your repository

2. **Required environment variables:**
   ```
   DB_HOST=your-postgresql-server.com
   DB_PORT=5432
   DB_USER=your_odoo_user
   DB_PASSWORD=your_secure_password
   DB_NAME=your_odoo_database
   ```

3. **Recommended environment variables:**
   ```
   # Master admin password (HIGHLY RECOMMENDED)
   ADMIN_PASSWD=your_super_secure_master_password
   ```

4. **Optional environment variables:**
   ```
   # Email configuration (optional)
   EMAIL_FROM=noreply@yourdomain.com
   SMTP_SERVER=smtp.gmail.com
   SMTP_PORT=587
   SMTP_SSL=True
   SMTP_USER=your_email@gmail.com
   SMTP_PASSWORD=your_app_password
   ```

5. **Ports:**
   - Main port: `8069`
   - Live chat port: `8072` (optional)

6. **Persistent volumes:**
   - `/var/lib/odoo` - Odoo data (filestore, sessions, etc.)
   - `/mnt/extra-addons` - Custom addons

### 3. External Database

Make sure your PostgreSQL database:

- ✅ Is accessible from Coolify
- ✅ Has a dedicated user for Odoo
- ✅ Has a database created for Odoo
- ✅ Allows connections from Coolify's IP

**SQL commands to prepare the database:**

```sql
-- Create user for Odoo
CREATE USER odoo_user WITH PASSWORD 'secure_password';

-- Create database
CREATE DATABASE odoo_production OWNER odoo_user;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE odoo_production TO odoo_user;
GRANT CREATE ON SCHEMA public TO odoo_user;
```

## Local Testing

To test the image locally before deployment:

```bash
# Clone the repository
git clone <your-repository>
cd odoo17

# Create directory for addons (if it doesn't exist)
mkdir -p addons

# Run with docker-compose (includes local database)
docker-compose up -d

# View logs
docker-compose logs -f odoo

# Access Odoo
# http://localhost:8069
```

**Default credentials for local testing:**
- URL: http://localhost:8069
- Database: postgres
- Email: admin@example.com
- Password: admin

## Access Credentials

### Default Administrator User
- **Username:** `admin`
- **Password:** `admin`

⚠️ **IMPORTANT:** Change this password immediately after first access.

### Master Password (Admin Password)
If you configured the `ADMIN_PASSWD` variable, this password will allow you to:
- Create and delete databases
- Access advanced administrative functions
- Manage backups and restorations
- Full system access

**Access:** Go to `/web/database/manager` to use the master password.

## Advanced Configuration

### Custom Addons

1. Create an `addons` folder in your repository
2. Place your custom addons there
3. Coolify will automatically mount them to `/mnt/extra-addons`

### Workers Configuration

For high-traffic sites, modify `odoo.conf`:

```ini
workers = 4
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
```

### Email Configuration

Configure SMTP environment variables in Coolify to enable email sending.

## Troubleshooting

### Problem: Cannot connect to database

**Solution:**
1. Verify database environment variables
2. Make sure the database is accessible
3. Check logs: `docker logs <container-name>`

### Problem: Odoo doesn't start

**Solution:**
1. Verify that the database has correct permissions
2. Check container logs
3. Make sure port 8069 is available

### Problem: Addons don't load

**Solution:**
1. Verify they are in the `addons` folder
2. Restart the container
3. Update the module list in Odoo

## Additional Resources

- [Official Odoo Documentation](https://www.odoo.com/documentation/17.0/)
- [Coolify Documentation](https://coolify.io/docs)
- [PostgreSQL Configuration for Odoo](https://www.odoo.com/documentation/17.0/administration/install/install.html#postgresql)

## Support

If you encounter issues:

1. Check container logs
2. Verify database configuration
3. Make sure all environment variables are set
4. Consult official Odoo and Coolify documentation