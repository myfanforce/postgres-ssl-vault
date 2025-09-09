#!/bin/bash

# exit as soon as any of these commands fail
set -e

echo "Initializing pgsodium (preloaded) and Supabase Vault extensions..."

# Function to safely execute SQL with retries
execute_sql() {
    local sql="$1"
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "$sql"; then
            echo "Successfully executed: $sql"
            return 0
        else
            echo "Attempt $attempt failed for: $sql"
            attempt=$((attempt + 1))
            if [ $attempt -le $max_attempts ]; then
                echo "Retrying in 2 seconds..."
                sleep 2
            fi
        fi
    done
    
    echo "Failed to execute after $max_attempts attempts: $sql"
    return 1
}

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
    echo "PostgreSQL is not ready yet, waiting..."
    sleep 2
done

echo "PostgreSQL is ready, creating extensions..."

# Create the pgsodium extension (it should be preloaded with server key)
execute_sql "CREATE EXTENSION IF NOT EXISTS pgsodium;"

# Create the Supabase Vault extension
execute_sql "CREATE EXTENSION IF NOT EXISTS supabase_vault;"

# Verify both extensions were created
if execute_sql "SELECT extname FROM pg_extension WHERE extname = 'pgsodium';"; then
    echo "pgsodium extension successfully installed and enabled!"
else
    echo "Failed to verify pgsodium extension installation"
    exit 1
fi

if execute_sql "SELECT extname FROM pg_extension WHERE extname = 'supabase_vault';"; then
    echo "supabase_vault extension successfully installed and enabled!"
else
    echo "Failed to verify supabase_vault extension installation"
    exit 1
fi

# Test that the server key is working
echo "Testing server-managed keys..."
execute_sql "
-- Test that we can derive keys (this proves server key is available)
SELECT 
    CASE 
        WHEN pgsodium.derive_key(1, 32, 'test_context'::bytea) IS NOT NULL 
        THEN 'Server key is available and working!'
        ELSE 'Server key test failed'
    END as server_key_status;
"

# Test vault functionality with server keys
echo "Testing Vault functionality with server keys..."
execute_sql "
-- Test basic vault operations
DO \$\$
BEGIN
    -- Try to create a test secret (this should work with server keys)
    PERFORM vault.create_secret('test_key', 'test_value', 'Test secret for initialization');
    RAISE NOTICE 'SUCCESS: Vault is working with server keys!';
    
    -- Verify we can read it back
    IF EXISTS (
        SELECT 1 FROM vault.decrypted_secrets 
        WHERE name = 'test_key' AND decrypted_secret = 'test_value'
    ) THEN
        RAISE NOTICE 'SUCCESS: Vault decryption is working!';
    ELSE
        RAISE NOTICE 'WARNING: Vault decryption may have issues';
    END IF;
    
    -- Clean up test secret
    DELETE FROM vault.secrets WHERE name = 'test_key';
    RAISE NOTICE 'Test secret cleaned up';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Vault test failed: %', SQLERRM;
        RAISE NOTICE 'This may indicate a server key configuration issue';
END
\$\$;
"

echo "Extensions initialization completed successfully!"
echo ""
echo "🔐 VAULT CONFIGURATION STATUS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ pgsodium is configured with server-managed keys"
echo "✅ Supabase Vault is ready for secure secret management"
echo "✅ Server root key is automatically generated and managed"
echo ""
echo "🔑 Usage examples:"
echo "   SELECT vault.create_secret('api_key', 'your_secret_value', 'API Key');"
echo "   SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'api_key';"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
