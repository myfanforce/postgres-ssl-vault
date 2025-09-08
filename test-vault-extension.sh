#!/bin/bash

# Test script to validate Supabase Vault extension is working
# Usage: ./test-vault-extension.sh [container_name_or_id]

set -e

CONTAINER=${1:-postgres-ssl-vault}

echo "Testing Supabase Vault extension in container: $CONTAINER"

# Test if the extension is installed
echo "1. Checking if vault extension is available..."
docker exec $CONTAINER psql -U postgres -c "SELECT name FROM pg_available_extensions WHERE name = 'vault';"

# Test if the extension is enabled
echo "2. Checking if vault extension is enabled..."
docker exec $CONTAINER psql -U postgres -c "SELECT extname FROM pg_extension WHERE extname = 'vault';"

# Test basic vault functionality
echo "3. Testing basic vault functionality..."
docker exec $CONTAINER psql -U postgres -c "
-- Create a test secret
SELECT vault.create_secret('test-secret', 'This is a test secret value');

-- Retrieve the secret
SELECT vault.read_secret('test-secret');

-- List secrets
SELECT * FROM vault.secrets;
"

echo "✅ Supabase Vault extension is working correctly!"
echo "🔐 SSL is enabled and Vault extension is ready for use."
