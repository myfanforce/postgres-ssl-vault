#!/bin/bash

# pgsodium key generation script for server-managed keys
# This script generates and returns a root key for pgsodium

KEY_FILE=$PGDATA/pgsodium_root.key

# Create the key file if it doesn't exist
if [ ! -f "$KEY_FILE" ]; then
    # Generate a 32-byte (256-bit) random key and convert to hex
    head -c 32 /dev/urandom | od -A n -t x1 | tr -d ' \n' > "$KEY_FILE"
    
    # Set proper permissions for the key file
    chmod 600 "$KEY_FILE"
    chown postgres:postgres "$KEY_FILE"
    
    echo "Generated new pgsodium root key at $KEY_FILE" >&2
fi

# Output the key (this is what pgsodium will use)
cat "$KEY_FILE"
