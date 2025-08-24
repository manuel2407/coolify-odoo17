# Odoo 17 Docker Image for Coolify

Esta imagen de Docker está optimizada para ejecutar Odoo 17 en Coolify con una base de datos externa.

## Características

- ✅ Odoo 17 Community Edition
- ✅ Todas las dependencias necesarias incluidas
- ✅ Configuración optimizada para base de datos externa
- ✅ Soporte para variables de entorno
- ✅ Script de inicialización automática
- ✅ Volúmenes persistentes para addons y datos
- ✅ Configuración de proxy para reverse proxies
- ✅ Soporte para Docker secrets

## Estructura del Proyecto

```
odoo17/
├── Dockerfile              # Imagen principal de Odoo 17
├── docker-compose.yml      # Para pruebas locales
├── odoo.conf              # Configuración de Odoo
├── entrypoint.sh          # Script de inicialización
├── requirements.txt       # Dependencias Python adicionales
├── addons/                # Directorio para addons personalizados (crear si es necesario)
└── README.md              # Este archivo
```

## Despliegue en Coolify

### 1. Preparación del Repositorio

1. Sube este proyecto a tu repositorio Git (GitHub, GitLab, etc.)
2. Asegúrate de que todos los archivos estén en la raíz del repositorio

### 2. Configuración en Coolify

1. **Crear nueva aplicación:**
   - Ve a tu panel de Coolify
   - Crea una nueva aplicación
   - Selecciona "Docker Compose" o "Dockerfile"
   - Conecta tu repositorio

2. **Variables de entorno requeridas:**
   ```
   DB_HOST=tu-servidor-postgresql.com
   DB_PORT=5432
   DB_USER=tu_usuario_odoo
   DB_PASSWORD=tu_password_seguro
   DB_NAME=tu_base_datos_odoo
   ```

3. **Variables de entorno opcionales:**
   ```
   # Configuración de email (opcional)
   EMAIL_FROM=noreply@tudominio.com
   SMTP_SERVER=smtp.gmail.com
   SMTP_PORT=587
   SMTP_SSL=True
   SMTP_USER=tu_email@gmail.com
   SMTP_PASSWORD=tu_app_password
   
   # Configuración adicional
   ADMIN_PASSWD=tu_password_admin_odoo
   ```

4. **Puertos:**
   - Puerto principal: `8069`
   - Puerto de chat en vivo: `8072` (opcional)

5. **Volúmenes persistentes:**
   - `/var/lib/odoo` - Datos de Odoo (filestore, sesiones, etc.)
   - `/mnt/extra-addons` - Addons personalizados

### 3. Base de Datos Externa

Asegúrate de que tu base de datos PostgreSQL:

- ✅ Sea accesible desde Coolify
- ✅ Tenga un usuario dedicado para Odoo
- ✅ Tenga una base de datos creada para Odoo
- ✅ Permita conexiones desde la IP de Coolify

**Comandos SQL para preparar la base de datos:**

```sql
-- Crear usuario para Odoo
CREATE USER odoo_user WITH PASSWORD 'password_seguro';

-- Crear base de datos
CREATE DATABASE odoo_production OWNER odoo_user;

-- Otorgar permisos
GRANT ALL PRIVILEGES ON DATABASE odoo_production TO odoo_user;
GRANT CREATE ON SCHEMA public TO odoo_user;
```

## Pruebas Locales

Para probar la imagen localmente antes del despliegue:

```bash
# Clonar el repositorio
git clone <tu-repositorio>
cd odoo17

# Crear directorio para addons (si no existe)
mkdir -p addons

# Ejecutar con docker-compose (incluye base de datos local)
docker-compose up -d

# Ver logs
docker-compose logs -f odoo

# Acceder a Odoo
# http://localhost:8069
```

**Credenciales por defecto para pruebas locales:**
- URL: http://localhost:8069
- Base de datos: postgres
- Email: admin@example.com
- Password: admin

## Configuración Avanzada

### Addons Personalizados

1. Crea una carpeta `addons` en tu repositorio
2. Coloca tus addons personalizados ahí
3. Coolify los montará automáticamente en `/mnt/extra-addons`

### Configuración de Workers

Para sitios con mucho tráfico, modifica `odoo.conf`:

```ini
workers = 4
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
```

### Configuración de Email

Configura las variables de entorno de SMTP en Coolify para habilitar el envío de emails.

## Troubleshooting

### Problema: No se puede conectar a la base de datos

**Solución:**
1. Verifica las variables de entorno de base de datos
2. Asegúrate de que la base de datos sea accesible
3. Revisa los logs: `docker logs <container-name>`

### Problema: Odoo no inicia

**Solución:**
1. Verifica que la base de datos tenga los permisos correctos
2. Revisa los logs del contenedor
3. Asegúrate de que el puerto 8069 esté disponible

### Problema: Los addons no se cargan

**Solución:**
1. Verifica que estén en la carpeta `addons`
2. Reinicia el contenedor
3. Actualiza la lista de módulos en Odoo

## Recursos Adicionales

- [Documentación oficial de Odoo](https://www.odoo.com/documentation/17.0/)
- [Documentación de Coolify](https://coolify.io/docs)
- [Configuración de PostgreSQL para Odoo](https://www.odoo.com/documentation/17.0/administration/install/install.html#postgresql)

## Soporte

Si encuentras problemas:

1. Revisa los logs del contenedor
2. Verifica la configuración de la base de datos
3. Asegúrate de que todas las variables de entorno estén configuradas
4. Consulta la documentación oficial de Odoo y Coolify
