# Scripts Directory

## Available Scripts

### `fetch-data.sh`

Fetches GitHub repositories and custom links based on your `config.json` configuration.

**Usage:**
```bash
./scripts/fetch-data.sh
# or
npm run fetch-data
```

**What it does:**
1. Validates that `config.json` exists and is valid JSON
2. Fetches repositories from all configured GitHub organizations
   - **With pagination (default):** Fetches ALL repositories page-by-page
   - **Without pagination:** Fetches up to the limit
3. Merges in custom links from your config
4. Generates `src/assets/data.json` for the application

**Features:**
- **Pagination support** - Automatically fetches ALL repos using pagination
- **Progress tracking** - Shows real-time progress as pages are fetched
- **Multi-organization** - Handles multiple orgs efficiently
- **Error handling** - Gracefully handles failures and continues

**Requirements:**
- `jq` - JSON processor
- `gh` - GitHub CLI (only if fetching from GitHub)

**See also:** [PAGINATION_FEATURE.md](../PAGINATION_FEATURE.md) for detailed pagination documentation

---

### `setup.sh`

Interactive setup wizard to create your initial `config.json`.

**Usage:**
```bash
./scripts/setup.sh
# or
npm run setup
```

**What it does:**
1. Creates `config.json` from the example template
2. Guides you through adding GitHub organizations
3. Helps you add initial custom links
4. Provides next steps to get started

---

### `validate-config.sh`

Validates your `config.json` structure and content.

**Usage:**
```bash
./scripts/validate-config.sh
# or
npm run validate
```

**What it checks:**
- JSON syntax validity
- Required keys presence (github, customLinks)
- GitHub configuration (enabled, limit, organizations)
- Custom links structure (name and url fields)
- GitHub CLI installation and authentication status
- Data type validation

**Exit codes:**
- `0` - Configuration is valid
- `1` - Configuration has errors or doesn't exist

---

### `backup-config.sh`

Creates a timestamped backup of your `config.json`.

**Usage:**
```bash
./scripts/backup-config.sh
```

**What it does:**
1. Creates a backup file named `config.backup.YYYYMMDD_HHMMSS.json`
2. Provides restore instructions

**When to use:**
- Before making major configuration changes
- Before running the setup wizard again
- Before upgrading to a new version
- Regular backups of your configuration

---

### `export-template.sh`

Exports a sanitized template from your config for sharing.

**Usage:**
```bash
./scripts/export-template.sh [output-file]
# Default output: config.template.json
```

**What it does:**
1. Creates a sanitized version of your config
2. Replaces organization names with placeholders
3. Removes all custom links
4. Preserves GitHub settings structure

**When to use:**
- Sharing your config structure with team members
- Creating templates for different use cases (work, personal, etc.)
- Contributing example configs to the project

**Example:**
```bash
# Export as default template
./scripts/export-template.sh

# Export with custom name
./scripts/export-template.sh my-work-template.json
```

---

## Script Dependencies

All scripts require:
- `bash` - Shell interpreter
- `jq` - JSON processor ([install](https://stedolan.github.io/jq/))

Some scripts additionally require:
- `gh` - GitHub CLI ([install](https://cli.github.com/)) - only for `fetch-data.sh` when GitHub fetching is enabled

## Common Workflows

### Initial Setup
```bash
# 1. Run setup wizard
npm run setup

# 2. Validate configuration
npm run validate

# 3. Fetch data
npm run fetch-data
```

### Configuration Changes
```bash
# 1. Backup current config
./scripts/backup-config.sh

# 2. Edit config.json manually
# ... make your changes ...

# 3. Validate changes
npm run validate

# 4. Refresh data
npm run fetch-data
```

### Sharing Configuration
```bash
# Export sanitized template
./scripts/export-template.sh team-template.json

# Share team-template.json with colleagues
# They can use it as their starting point
```

## Deprecation Notice

### `custom_data.json` (DEPRECATED)

⚠️ **This file is deprecated and no longer used.**

The old system used:
- Hardcoded organization in `fetch-data.sh`
- Separate `custom_data.json` for custom links

The new system uses:
- `config.json` in the project root
- Supports multiple organizations
- Custom links within the config

**To migrate:** See [MIGRATION.md](../MIGRATION.md)

If you have an existing `custom_data.json`, you can safely delete it after migrating your custom links to `config.json`.

