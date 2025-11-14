#!/bin/bash

# Script to validate config.json structure and content
# Can be run standalone or sourced by other scripts

set -e

VALID=true

echo "Validating config.json..."
echo ""

# Check if config.json exists
if [ ! -f "config.json" ]; then
    echo "❌ config.json not found!"
    echo "   Run: npm run setup"
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is not installed"
    echo "   macOS: brew install jq"
    echo "   Ubuntu/Debian: sudo apt-get install jq"
    exit 1
fi

# Validate JSON syntax
if ! jq empty config.json >/dev/null 2>&1; then
    echo "❌ config.json contains invalid JSON"
    VALID=false
else
    echo "✓ Valid JSON syntax"
fi

# Check for required top-level keys
if ! jq -e '.github' config.json >/dev/null 2>&1; then
    echo "❌ Missing 'github' key in config.json"
    VALID=false
else
    echo "✓ 'github' key present"
fi

if ! jq -e '.customLinks' config.json >/dev/null 2>&1; then
    echo "❌ Missing 'customLinks' key in config.json"
    VALID=false
else
    echo "✓ 'customLinks' key present"
fi

# Validate github structure
GITHUB_ENABLED=$(jq -r '.github.enabled // true' config.json)
GITHUB_PAGINATE=$(jq -r '.github.paginate // true' config.json)
GITHUB_LIMIT=$(jq -r '.github.limit // 1000' config.json)
ORG_COUNT=$(jq -r '.github.organizations | length' config.json 2>/dev/null || echo "0")

echo ""
echo "GitHub Configuration:"
echo "  Enabled: $GITHUB_ENABLED"
echo "  Pagination: $GITHUB_PAGINATE"
echo "  Page Size: $GITHUB_LIMIT"
echo "  Organizations: $ORG_COUNT"

if [ "$GITHUB_PAGINATE" = "true" ]; then
    echo "  Mode: Fetch ALL repositories (paginated with page size: $GITHUB_LIMIT)"
else
    echo "  Mode: Fetch up to $GITHUB_LIMIT repositories per org"
fi

if [ "$GITHUB_ENABLED" = "true" ] && [ "$ORG_COUNT" -eq 0 ]; then
    echo "  ⚠️  Warning: GitHub is enabled but no organizations are configured"
fi

# Validate organizations are strings
if [ "$ORG_COUNT" -gt 0 ]; then
    INVALID_ORGS=$(jq -r '.github.organizations[] | select(type != "string")' config.json 2>/dev/null | wc -l)
    if [ "$INVALID_ORGS" -gt 0 ]; then
        echo "  ❌ Some organizations are not strings"
        VALID=false
    fi
fi

# Validate customLinks structure
LINKS_COUNT=$(jq -r '.customLinks | length' config.json 2>/dev/null || echo "0")
echo ""
echo "Custom Links Configuration:"
echo "  Total links: $LINKS_COUNT"

if [ "$LINKS_COUNT" -gt 0 ]; then
    # Check each link has name and url
    INVALID_LINKS=$(jq -r '[.customLinks[] | select(.name == null or .url == null)] | length' config.json)
    if [ "$INVALID_LINKS" -gt 0 ]; then
        echo "  ❌ $INVALID_LINKS link(s) missing 'name' or 'url' field"
        VALID=false
    else
        echo "  ✓ All links have required fields"
    fi
    
    # Warn about empty names or URLs
    EMPTY_NAMES=$(jq -r '[.customLinks[] | select(.name == "")] | length' config.json)
    EMPTY_URLS=$(jq -r '[.customLinks[] | select(.url == "")] | length' config.json)
    
    if [ "$EMPTY_NAMES" -gt 0 ]; then
        echo "  ⚠️  Warning: $EMPTY_NAMES link(s) have empty names"
    fi
    
    if [ "$EMPTY_URLS" -gt 0 ]; then
        echo "  ⚠️  Warning: $EMPTY_URLS link(s) have empty URLs"
    fi
fi

# Check if gh CLI is available when GitHub is enabled
if [ "$GITHUB_ENABLED" = "true" ] && [ "$ORG_COUNT" -gt 0 ]; then
    echo ""
    if command -v gh >/dev/null 2>&1; then
        echo "✓ GitHub CLI (gh) is installed"
        
        # Check if authenticated
        if gh auth status >/dev/null 2>&1; then
            echo "✓ GitHub CLI is authenticated"
        else
            echo "⚠️  Warning: GitHub CLI is not authenticated"
            echo "   Run: gh auth login"
        fi
    else
        echo "⚠️  Warning: GitHub CLI (gh) is not installed"
        echo "   Install: https://cli.github.com/"
    fi
fi

echo ""
if [ "$VALID" = true ]; then
    echo "✅ Configuration is valid!"
    exit 0
else
    echo "❌ Configuration has errors. Please fix and try again."
    exit 1
fi

