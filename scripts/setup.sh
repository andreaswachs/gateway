#!/bin/bash

echo "================================================"
echo "Gateway Setup Script"
echo "================================================"
echo ""

# Check if config.json already exists
if [ -f "config.json" ]; then
    echo "⚠️  config.json already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Your existing config.json is unchanged."
        exit 0
    fi
fi

# Copy the example config
if [ ! -f "config.example.json" ]; then
    echo "ERROR: config.example.json not found!"
    exit 1
fi

cp config.example.json config.json
echo "✓ Created config.json from template"
echo ""

# Interactive configuration
echo "Let's configure your Gateway!"
echo ""

# Ask for GitHub organizations
echo "GitHub Organizations"
echo "--------------------"
read -p "Do you want to fetch repositories from GitHub? (Y/n): " -n 1 -r
echo
FETCH_GITHUB=true
if [[ $REPLY =~ ^[Nn]$ ]]; then
    FETCH_GITHUB=false
fi

if [ "$FETCH_GITHUB" = true ]; then
    echo "Enter your GitHub organization names (one per line, empty line to finish):"
    ORGS=()
    while true; do
        read -p "  Organization: " org
        if [ -z "$org" ]; then
            break
        fi
        ORGS+=("\"$org\"")
    done
    
    if [ ${#ORGS[@]} -eq 0 ]; then
        echo "No organizations entered. GitHub fetching will be disabled."
        FETCH_GITHUB=false
    else
        ORG_JSON=$(IFS=,; echo "${ORGS[*]}")
        
        # Update config.json with organizations
        jq ".github.organizations = [$ORG_JSON]" config.json > config.json.tmp
        mv config.json.tmp config.json
        
        echo "✓ Added ${#ORGS[@]} organization(s)"
    fi
fi

# Update GitHub enabled status
if [ "$FETCH_GITHUB" = true ]; then
    jq '.github.enabled = true' config.json > config.json.tmp
    mv config.json.tmp config.json
    
    # Ask about pagination
    echo ""
    echo "Pagination Settings"
    echo "-------------------"
    echo "With pagination enabled, ALL repositories will be fetched (recommended)."
    echo "With pagination disabled, only up to the limit will be fetched."
    read -p "Enable pagination to fetch all repositories? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        jq '.github.paginate = false' config.json > config.json.tmp
        mv config.json.tmp config.json
        echo "✓ Pagination disabled (will fetch up to limit)"
    else
        jq '.github.paginate = true' config.json > config.json.tmp
        mv config.json.tmp config.json
        echo "✓ Pagination enabled (will fetch all repositories)"
    fi
else
    jq '.github.enabled = false' config.json > config.json.tmp
    mv config.json.tmp config.json
fi

echo ""
echo "Custom Links"
echo "------------"
read -p "Do you want to add custom links now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Enter custom links (empty name to finish):"
    LINKS=()
    while true; do
        read -p "  Link name: " name
        if [ -z "$name" ]; then
            break
        fi
        read -p "  Link URL: " url
        if [ -z "$url" ]; then
            echo "  Skipping (no URL provided)"
            continue
        fi
        LINKS+=("{\"name\": \"$name\", \"url\": \"$url\"}")
    done
    
    if [ ${#LINKS[@]} -gt 0 ]; then
        LINKS_JSON=$(IFS=,; echo "${LINKS[*]}")
        jq ".customLinks = [$LINKS_JSON]" config.json > config.json.tmp
        mv config.json.tmp config.json
        echo "✓ Added ${#LINKS[@]} custom link(s)"
    fi
else
    # Clear custom links
    jq '.customLinks = []' config.json > config.json.tmp
    mv config.json.tmp config.json
fi

echo ""
echo "================================================"
echo "✓ Setup complete!"
echo "================================================"
echo ""
echo "Your configuration has been saved to config.json"
echo ""
echo "Next steps:"
echo "  1. Review and edit config.json if needed"
echo "  2. Run 'npm run fetch-data' to fetch repositories and generate data"
echo "  3. Run 'npm run dev' to start the development server"
echo ""
echo "You can always re-run this setup script or manually edit config.json"
echo ""

