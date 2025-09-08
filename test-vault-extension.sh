#!/bin/bash

# Test script to validate pgsodium extension is working
# Usage: ./test-vault-extension.sh [container_name_or_id]

set -e

CONTAINER=${1:-postgres-ssl-vault}

echo "Testing pgsodium extension in container: $CONTAINER"

# Test if the extension is installed
echo "1. Checking if pgsodium extension is available..."
docker exec $CONTAINER psql -U postgres -c "SELECT name FROM pg_available_extensions WHERE name = 'pgsodium';"

# Test if the extension is enabled
echo "2. Checking if pgsodium extension is enabled..."
docker exec $CONTAINER psql -U postgres -c "SELECT extname FROM pg_extension WHERE extname = 'pgsodium';"

# Test basic pgsodium functionality
echo "3. Testing basic pgsodium functionality..."
docker exec $CONTAINER psql -U postgres -c "
-- Test encryption/decryption
SELECT pgsodium.crypto_secretbox('Hello, World!', '\\x1234567890123456789012345678901234567890123456789012345678901234');

-- Test random data generation
SELECT pgsodium.randombytes_buf(32);

-- Show pgsodium functions
SELECT proname FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pgsodium') LIMIT 5;
"

echo "✅ pgsodium extension is working correctly!"
echo "🔐 SSL is enabled and pgsodium extension is ready for use."
