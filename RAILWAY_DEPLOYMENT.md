# Deploying to Railway

This guide explains how to deploy the SSL-enabled PostgreSQL with pgsodium to Railway.

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

## Using the pgsodium Extension

Once deployed, you can connect to your database and start using the pgsodium extension:

```sql
-- Encrypt data
SELECT pgsodium.crypto_secretbox('your-secret-data', pgsodium.randombytes_buf(32));

-- Generate random keys
SELECT pgsodium.randombytes_buf(32);

-- Hash passwords securely
SELECT pgsodium.crypto_pwhash('your-password');

-- List available functions
SELECT proname FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pgsodium');
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
5. Migrate any secrets using pgsodium's cryptographic functions

The pgsodium extension provides robust cryptographic capabilities for secure data handling, making migration from Supabase straightforward.
