#!/bin/bash

# pgsodium key generation script for server-managed keys
# This script generates and returns a root key for pgsodium

set -e

# Ensure PGDATA is set
if [ -z "$PGDATA" ]; then
    PGDATA="/var/lib/postgresql/data"
fi

KEY_FILE="$PGDATA/pgsodium_root.key"

# Create the key file if it doesn't exist
if [ ! -f "$KEY_FILE" ]; then
    # Ensure the directory exists and has proper permissions
    mkdir -p "$(dirname "$KEY_FILE")"
    
    # Generate a 32-byte (256-bit) random key and convert to hex
    head -c 32 /dev/urandom | od -A n -t x1 | tr -d ' \n' > "$KEY_FILE"
    
    # Set proper permissions for the key file
    chmod 600 "$KEY_FILE"
    chown postgres:postgres "$KEY_FILE" 2>/dev/null || true
    
    echo "Generated new pgsodium root key at $KEY_FILE" >&2
fi

# Verify the key file exists and is readable
if [ ! -r "$KEY_FILE" ]; then
    echo "ERROR: Key file $KEY_FILE is not readable" >&2
    exit 1
fi

# Verify the key is the correct length (64 hex characters = 32 bytes)
KEY_CONTENT=$(cat "$KEY_FILE")
if [ ${#KEY_CONTENT} -ne 64 ]; then
    echo "ERROR: Key file contains invalid key (expected 64 hex chars, got ${#KEY_CONTENT})" >&2
    exit 1
fi

# Output the key (this is what pgsodium will use)
echo "$KEY_CONTENT"
