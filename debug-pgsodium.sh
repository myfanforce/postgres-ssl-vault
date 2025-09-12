#!/bin/bash

# Debug script to test pgsodium configuration
# Usage: ./debug-pgsodium.sh [container_name_or_id]

set -e

CONTAINER=${1:-postgres-ssl-vault}

echo "🔍 Debugging pgsodium configuration in container: $CONTAINER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "1. Checking if getkey script exists and is executable..."
docker exec $CONTAINER ls -la /usr/local/bin/pgsodium_getkey.sh

echo "2. Testing getkey script manually..."
docker exec $CONTAINER bash -c "PGDATA=/var/lib/postgresql/data /usr/local/bin/pgsodium_getkey.sh"

echo "3. Checking PostgreSQL configuration..."
docker exec $CONTAINER psql -U postgres -c "
SELECT name, setting, source 
FROM pg_settings 
WHERE name IN ('shared_preload_libraries', 'pgsodium.getkey_script')
ORDER BY name;
"

echo "4. Checking if pgsodium extension is loaded..."
docker exec $CONTAINER psql -U postgres -c "
SELECT extname, extversion 
FROM pg_extension 
WHERE extname = 'pgsodium';
"

echo "5. Testing server key functionality..."
docker exec $CONTAINER psql -U postgres -c "
-- Test key derivation
SELECT 
    CASE 
        WHEN pgsodium.derive_key(1, 32, 'test'::bytea) IS NOT NULL 
        THEN '✅ Server key derivation working'
        ELSE '❌ Server key derivation failed'
    END as derivation_test;
"

echo "6. Testing server-managed encryption..."
docker exec $CONTAINER psql -U postgres -c "
-- Test server-managed encryption
SELECT 
    CASE 
        WHEN pgsodium.crypto_secretbox_new('test message') IS NOT NULL 
        THEN '✅ Server-managed encryption working'
        ELSE '❌ Server-managed encryption failed'
    END as encryption_test;
"

echo "7. Testing Supabase Vault with server keys..."
docker exec $CONTAINER psql -U postgres -c "
-- Test vault operations
DO \$\$
DECLARE
    test_result BOOLEAN := FALSE;
BEGIN
    -- Clean up any existing test data
    DELETE FROM vault.secrets WHERE name = 'debug_test_key';
    
    -- Test creating a secret
    PERFORM vault.create_secret('debug_test_key', 'debug_test_value', 'Debug test');
    
    -- Check if we can decrypt it
    SELECT EXISTS (
        SELECT 1 FROM vault.decrypted_secrets 
        WHERE name = 'debug_test_key' AND decrypted_secret = 'debug_test_value'
    ) INTO test_result;
    
    IF test_result THEN
        RAISE NOTICE '✅ Vault encryption/decryption with server keys working!';
    ELSE
        RAISE NOTICE '❌ Vault encryption/decryption test failed';
    END IF;
    
    -- Clean up
    DELETE FROM vault.secrets WHERE name = 'debug_test_key';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ ERROR in Vault test: %', SQLERRM;
END
\$\$;
"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Debug completed!"
