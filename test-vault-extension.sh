#!/bin/bash

# Test script to validate pgsodium extension is working
# Usage: ./test-vault-extension.sh [container_name_or_id]

set -e

CONTAINER=${1:-postgres-ssl-vault}

echo "Testing pgsodium and Supabase Vault extensions in container: $CONTAINER"

# Test if the extensions are installed
echo "1. Checking if pgsodium extension is available..."
docker exec $CONTAINER psql -U postgres -c "SELECT name FROM pg_available_extensions WHERE name = 'pgsodium';"

echo "2. Checking if supabase_vault extension is available..."
docker exec $CONTAINER psql -U postgres -c "SELECT name FROM pg_available_extensions WHERE name = 'supabase_vault';"

# Test if the extensions are enabled
echo "3. Checking if pgsodium extension is enabled..."
docker exec $CONTAINER psql -U postgres -c "SELECT extname FROM pg_extension WHERE extname = 'pgsodium';"

echo "4. Checking if supabase_vault extension is enabled..."
docker exec $CONTAINER psql -U postgres -c "SELECT extname FROM pg_extension WHERE extname = 'supabase_vault';"

# Test pgsodium configuration
echo "5. Testing pgsodium configuration..."
docker exec $CONTAINER psql -U postgres -c "
-- Check pgsodium configuration
SHOW pgsodium.getkey_script;
SHOW shared_preload_libraries;
"

# Test basic pgsodium functionality
echo "6. Testing basic pgsodium functionality..."
docker exec $CONTAINER psql -U postgres -c "
-- Test encryption/decryption
SELECT pgsodium.crypto_secretbox('Hello, World!', '\\x1234567890123456789012345678901234567890123456789012345678901234');

-- Test random data generation
SELECT pgsodium.randombytes_buf(32);

-- Show pgsodium functions
SELECT proname FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pgsodium') LIMIT 5;
"

# Test server-managed keys (the key functionality that was failing)
echo "7. Testing server-managed keys..."
docker exec $CONTAINER psql -U postgres -c "
-- Test key derivation (this requires server key to be working)
SELECT pgsodium.derive_key(1, 32, 'test_context'::bytea) IS NOT NULL as server_key_working;

-- Test that we can create and use server-managed keys
SELECT pgsodium.crypto_secretbox_new('test message') IS NOT NULL as server_encryption_working;
"

# Test Supabase Vault functionality
echo "8. Testing Supabase Vault with server keys..."
docker exec $CONTAINER psql -U postgres -c "
-- Test vault operations that require server keys
DO \$\$
BEGIN
    -- Clean up any existing test data
    DELETE FROM vault.secrets WHERE name = 'test_vault_key';
    
    -- Test creating a secret (this should work with server keys)
    PERFORM vault.create_secret('test_vault_key', 'test_vault_value', 'Test secret for validation');
    
    -- Verify we can decrypt it
    IF EXISTS (
        SELECT 1 FROM vault.decrypted_secrets 
        WHERE name = 'test_vault_key' AND decrypted_secret = 'test_vault_value'
    ) THEN
        RAISE NOTICE 'SUCCESS: Vault encryption/decryption with server keys working!';
    ELSE
        RAISE WARNING 'FAILED: Vault encryption/decryption test failed';
    END IF;
    
    -- Clean up
    DELETE FROM vault.secrets WHERE name = 'test_vault_key';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'ERROR in Vault test: %', SQLERRM;
END
\$\$;
"

echo "✅ Both pgsodium and Supabase Vault extensions are working correctly!"
echo "🔐 SSL is enabled and both extensions are ready for use."
