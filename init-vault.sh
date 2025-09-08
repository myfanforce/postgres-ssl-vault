#!/bin/bash

# exit as soon as any of these commands fail
set -e

echo "Initializing Supabase Vault extension..."

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

echo "PostgreSQL is ready, creating Vault extension..."

# Create the vault extension
execute_sql "CREATE EXTENSION IF NOT EXISTS vault;"

# Verify the extension was created
if execute_sql "SELECT extname FROM pg_extension WHERE extname = 'vault';"; then
    echo "Supabase Vault extension successfully installed and enabled!"
else
    echo "Failed to verify Vault extension installation"
    exit 1
fi

echo "Vault extension initialization completed successfully!"
