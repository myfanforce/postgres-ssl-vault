# Deploying to Railway

This guide explains how to deploy the SSL-enabled PostgreSQL with Supabase Vault to Railway.

## Quick Deployment

1. **Create a new project** in Railway
2. **Choose "Deploy from Docker Image"**
3. **Enter the image URL**:
   ```
   ghcr.io/yourusername/postgres-ssl-vault:16
   ```
   (Replace `yourusername` with your actual GitHub username)

## Environment Variables

Set the following environment variables in Railway:

### Required Variables
- `POSTGRES_USER`: Database username (default: `postgres`)
- `POSTGRES_PASSWORD`: Database password (set a strong password)
- `POSTGRES_DB`: Database name (default: `postgres`)

### Optional Variables
- `SSL_CERT_DAYS`: Certificate expiry in days (default: `820`)
- `LOG_TO_STDOUT`: Set to `true` to enable logging to stdout

## Volume Configuration

Make sure your Railway volume is mounted to:
```
/var/lib/postgresql/data
```

This is crucial for data persistence and proper SSL certificate management.

## Using the Vault Extension

Once deployed, you can connect to your database and start using the Vault extension:

```sql
-- Create a secret
SELECT vault.create_secret('api_key', 'your-secret-api-key');

-- Read a secret
SELECT vault.read_secret('api_key');

-- List all secrets
SELECT * FROM vault.secrets;
```

## Connection Examples

### Using Railway's Internal Network
```
postgresql://postgres:password@postgres-ssl-vault.railway.internal:5432/postgres?sslmode=require
```

### Using Railway's Public Network
```
postgresql://postgres:password@your-app.railway.app:5432/postgres?sslmode=require
```

## Migrating from Supabase

If you're migrating from Supabase to Railway:

1. Export your existing data from Supabase
2. Deploy this PostgreSQL image to Railway
3. Import your data
4. Update your application connection strings
5. Migrate any vault secrets to the new system

The Vault extension provides similar functionality to Supabase's secret management, making migration straightforward.
