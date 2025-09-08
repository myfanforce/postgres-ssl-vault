# SSL-enabled Postgres DB image with Supabase Vault

This repository contains the logic to build SSL-enabled Postgres images with the Supabase Vault extension pre-installed.

By default, when you deploy Postgres from the official Postgres template on
Railway, the image that is used is built from this repository!

[![Deploy on
Railway](https://railway.app/button.svg)](https://railway.app/template/postgres)

### Why though?

The official Postgres image in Docker hub does not come with SSL baked in, and the Supabase Vault extension is not included.

Since this could pose a problem for applications or services attempting to
connect to Postgres services securely or requiring secret management capabilities, we decided to roll our own Postgres image with:
- SSL enabled right out of the box
- Supabase Vault extension pre-installed for secure secret management

### How does it work?

The Dockerfiles contained in this repository start with the official Postgres
image as base. During the build process:

1. The Supabase Vault extension is compiled and installed from source
2. The `init-ssl.sh` script is copied into the `docker-entrypoint-initdb.d/` directory for SSL configuration
3. The `init-vault.sh` script is copied into the `docker-entrypoint-initdb.d/` directory to enable the Vault extension

Both scripts are executed upon database initialization.

### Certificate expiry

By default, the cert expiry is set to 820 days. You can control this by
configuring the `SSL_CERT_DAYS` environment variable as needed.

### Certificate renewal

When a redeploy or restart is done the certificates expiry is checked, if it has
expired or will expire in 30 days a new certificate is automatically generated.

### Supabase Vault Extension

The [Supabase Vault](https://github.com/supabase/vault) extension provides secure secret management capabilities within PostgreSQL. It allows you to:

- Store and retrieve secrets securely within your database
- Encrypt sensitive data at rest
- Manage API keys, passwords, and other sensitive information
- Integrate with your application's secret management workflow

The extension is automatically enabled during database initialization and is ready to use immediately.

#### Testing the Vault Extension

You can test that the Vault extension is working properly by using the included test script:

```bash
# Run the test against a running container
./test-vault-extension.sh your-container-name
```

Or manually verify the extension:

```sql
-- Check if the extension is available
SELECT name FROM pg_available_extensions WHERE name = 'vault';

-- Check if the extension is enabled
SELECT extname FROM pg_extension WHERE extname = 'vault';

-- Test basic functionality
SELECT vault.create_secret('test-key', 'test-value');
SELECT vault.read_secret('test-key');
```

### Available image tags

Images are automatically built weekly and tagged with multiple version levels
for flexibility:

- **Major version tags** (e.g., `:17`, `:16`, `:15`): Always points to the
  latest minor version for that major release
- **Minor version tags** (e.g., `:17.6`, `:16.10`): Pins to specific minor
  version for stability
- **Latest tag** (`:latest`): Currently points to PostgreSQL 16

Example usage:

```bash
# Auto-update to latest minor versions (recommended for development)
docker run ghcr.io/railwayapp-templates/postgres-ssl:17

# Pin to specific minor version (recommended for production)
docker run ghcr.io/railwayapp-templates/postgres-ssl:17.6
```

All images include both SSL support and the Supabase Vault extension pre-installed.

### A note about ports

By default, this image is hardcoded to listen on port `5432` regardless of what
is set in the `PGPORT` environment variable. We did this to allow connections
to the postgres service over the `RAILWAY_TCP_PROXY_PORT`. If you need to
change this behavior, feel free to build your own image without passing the
`--port` parameter to the `CMD` command in the Dockerfile.
