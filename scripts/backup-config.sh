#!/bin/bash

# Script to backup your config.json
# Useful before making major changes

if [ ! -f "config.json" ]; then
    echo "❌ No config.json found to backup"
    exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="config.backup.$TIMESTAMP.json"

cp config.json "$BACKUP_FILE"

echo "✓ Backup created: $BACKUP_FILE"
echo ""
echo "To restore this backup later:"
echo "  cp $BACKUP_FILE config.json"

