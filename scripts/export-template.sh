#!/bin/bash

# Script to export a sanitized template from your config
# Useful for sharing with others without exposing private links

if [ ! -f "config.json" ]; then
    echo "❌ No config.json found to export"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is required"
    exit 1
fi

OUTPUT_FILE="${1:-config.template.json}"

# Create a sanitized template
# - Keep GitHub settings but anonymize org names
# - Remove all custom links (user should add their own)
jq '{
  github: {
    organizations: (if .github.organizations | length > 0 then ["your-org-name"] else [] end),
    limit: .github.limit,
    enabled: .github.enabled
  },
  customLinks: []
}' config.json > "$OUTPUT_FILE"

echo "✓ Template exported to: $OUTPUT_FILE"
echo ""
echo "This template has been sanitized:"
echo "  - Organization names replaced with placeholder"
echo "  - Custom links removed"
echo ""
echo "You can share this template with others as a starting point."

