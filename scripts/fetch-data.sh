#!/bin/bash
set -e

# Check for required dependencies
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is not installed. Please install jq to continue."
    echo "  macOS: brew install jq"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    exit 1
fi

# Check if config.json exists
if [ ! -f "config.json" ]; then
    echo "ERROR: config.json not found!"
    echo ""
    echo "Please create a config.json file based on config.example.json"
    echo "Run: cp config.example.json config.json"
    echo "Then edit config.json with your GitHub organizations and custom links."
    exit 1
fi

# Validate config.json format
if ! jq empty config.json >/dev/null 2>&1; then
    echo "ERROR: config.json is not valid JSON"
    exit 1
fi

# Read configuration
GITHUB_ENABLED=$(jq -r '.github.enabled // true' config.json)
GITHUB_PAGINATE=$(jq -r '.github.paginate // true' config.json)
GITHUB_LIMIT=$(jq -r '.github.limit // 1000' config.json)
ORGANIZATIONS=$(jq -r '.github.organizations[]?' config.json)

# Create output directory if it doesn't exist
mkdir -p src/assets

# Initialize with empty array
echo "[]" > src/assets/data.json

# Fetch GitHub repositories if enabled
if [ "$GITHUB_ENABLED" = "true" ]; then
    if ! command -v gh >/dev/null 2>&1; then
        echo "WARNING: GitHub CLI (gh) is not installed, but GitHub fetching is enabled."
        echo "Install gh: https://cli.github.com/"
        echo "Skipping GitHub repository fetching..."
    elif [ -z "$ORGANIZATIONS" ]; then
        echo "INFO: No GitHub organizations specified in config.json"
    else
        echo "Fetching repositories from GitHub organizations..."
        
        # Temporary file for all GitHub data
        TEMP_GITHUB_DATA=$(mktemp)
        echo "[]" > "$TEMP_GITHUB_DATA"
        
        # Fetch from each organization
        for org in $ORGANIZATIONS; do
            echo "  Fetching from organization: $org"
            ORG_DATA=$(mktemp)
            
            # Build gh command with appropriate flags
            GH_CMD="gh repo list $org --json name,url"
            
            if [ "$GITHUB_PAGINATE" = "true" ]; then
                echo "    Using pagination to fetch all repositories..."
                GH_CMD="$GH_CMD --limit $GITHUB_LIMIT"
                
                # Fetch all pages
                PAGE=1
                TOTAL_FETCHED=0
                echo "[]" > "$ORG_DATA"
                
                while true; do
                    PAGE_DATA=$(mktemp)
                    
                    # Fetch one page
                    if gh repo list "$org" --limit "$GITHUB_LIMIT" --json name,url -q '[.[] | {name: .name, url: .url}]' > "$PAGE_DATA" 2>/dev/null; then
                        PAGE_COUNT=$(jq 'length' "$PAGE_DATA")
                        
                        if [ "$PAGE_COUNT" -eq 0 ]; then
                            rm "$PAGE_DATA"
                            break
                        fi
                        
                        # Merge with org data
                        PAGE_MERGED=$(mktemp)
                        jq -s 'add' "$ORG_DATA" "$PAGE_DATA" > "$PAGE_MERGED"
                        mv "$PAGE_MERGED" "$ORG_DATA"
                        rm "$PAGE_DATA"
                        
                        TOTAL_FETCHED=$((TOTAL_FETCHED + PAGE_COUNT))
                        echo "    Page $PAGE: $PAGE_COUNT repos (total: $TOTAL_FETCHED)"
                        
                        # If we got fewer repos than the limit, we've reached the end
                        if [ "$PAGE_COUNT" -lt "$GITHUB_LIMIT" ]; then
                            break
                        fi
                        
                        PAGE=$((PAGE + 1))
                    else
                        echo "    WARNING: Failed to fetch page $PAGE from $org"
                        rm "$PAGE_DATA"
                        break
                    fi
                done
                
                # Merge this org's data with accumulated data
                MERGED=$(mktemp)
                jq -s 'add' "$TEMP_GITHUB_DATA" "$ORG_DATA" > "$MERGED"
                mv "$MERGED" "$TEMP_GITHUB_DATA"
                rm "$ORG_DATA"
                
                REPO_COUNT=$(jq 'length' "$TEMP_GITHUB_DATA")
                echo "    ✓ Organization complete. Total repositories: $TOTAL_FETCHED"
                echo "    Running total (all orgs): $REPO_COUNT"
            else
                # Non-paginated: fetch only up to limit
                echo "    Fetching up to $GITHUB_LIMIT repositories..."
                if gh repo list "$org" --limit "$GITHUB_LIMIT" --json name,url -q '[.[] | {name: .name, url: .url}]' > "$ORG_DATA" 2>/dev/null; then
                    # Merge this org's data with accumulated data
                    MERGED=$(mktemp)
                    jq -s 'add' "$TEMP_GITHUB_DATA" "$ORG_DATA" > "$MERGED"
                    mv "$MERGED" "$TEMP_GITHUB_DATA"
                    rm "$ORG_DATA"
                    
                    REPO_COUNT=$(jq 'length' "$TEMP_GITHUB_DATA")
                    echo "    ✓ Found repositories (total so far: $REPO_COUNT)"
                else
                    echo "    WARNING: Failed to fetch from $org (check permissions/authentication)"
                    rm "$ORG_DATA"
                fi
            fi
        done
        
        # Copy GitHub data to main data file
        mv "$TEMP_GITHUB_DATA" src/assets/data.json
        
        TOTAL_REPOS=$(jq 'length' src/assets/data.json)
        echo "Total repositories fetched: $TOTAL_REPOS"
    fi
else
    echo "GitHub fetching is disabled in config.json"
fi

# Add custom links from config
CUSTOM_LINKS=$(jq '.customLinks // []' config.json)
if [ "$CUSTOM_LINKS" != "[]" ]; then
    echo "Adding custom links from config.json..."
    TEMP_FILE=$(mktemp)
    CUSTOM_FILE=$(mktemp)
    echo "$CUSTOM_LINKS" > "$CUSTOM_FILE"
    jq -s 'add' src/assets/data.json "$CUSTOM_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" src/assets/data.json
    rm "$CUSTOM_FILE"
    
    CUSTOM_COUNT=$(echo "$CUSTOM_LINKS" | jq 'length')
    echo "Added $CUSTOM_COUNT custom links"
fi

# Final validation
if ! jq empty src/assets/data.json >/dev/null 2>&1; then
    echo "ERROR: Generated data.json is not valid JSON"
    exit 1
fi

TOTAL_ITEMS=$(jq 'length' src/assets/data.json)
echo ""
echo "✓ Success! Data file generated at src/assets/data.json"
echo "  Total items: $TOTAL_ITEMS" 