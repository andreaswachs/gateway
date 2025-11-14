# Gateway - Personal Spotlight Search

A beautiful, fast, and portable Gateway page that provides a Spotlight-like search interface for your GitHub repositories and custom links. Perfect for quickly navigating to your frequently accessed projects, tools, and services.

## Features

- 🔍 **Fast Fuzzy Search** - Instantly find repositories and links as you type
- 🎨 **Modern UI** - Sleek macOS Spotlight-inspired design with glassmorphism
- ⚡ **Lightning Fast** - Built with Vue 3 and Vite for optimal performance
- 🔧 **Highly Configurable** - Easy JSON-based configuration for organizations and custom links
- 🚀 **Multiple Organizations** - Fetch repositories from multiple GitHub organizations
- 🔗 **Custom Links** - Add any tools, dashboards, or services you frequently use
- 🐳 **Docker Ready** - Includes Docker setup for easy deployment

## Quick Start

### Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher)
- [jq](https://stedolan.github.io/jq/) - JSON processor
- [GitHub CLI](https://cli.github.com/) (optional, only needed if fetching from GitHub)

### Installation

1. **Clone and install dependencies:**

```bash
git clone <your-repo-url>
cd Gateway
npm install
```

2. **Customize your configuration (optional):**

Edit `config.json` to add your GitHub organizations or modify custom links:

```bash
# Edit config.json with your preferred editor
nano config.json
```

Or run the interactive setup script:

```bash
./scripts/setup.sh
```

3. **Fetch your data:**

```bash
npm run fetch-data
```

5. **Start the development server:**

```bash
npm run dev
```

## Configuration

Your `config.json` file (included in the repository) controls what appears in your Gateway page. Here's the default configuration:

```json
{
  "github": {
    "organizations": [],
    "paginate": true,
    "limit": 1000,
    "enabled": false
  },
  "customLinks": [
    {
      "name": "calendar",
      "url": "https://calendar.google.com/calendar/u/0/r/week"
    },
    {
      "name": "mail",
      "url": "https://mail.google.com/mail/u/0/#inbox"
    },
    {
      "name": "gemini",
      "url": "https://gemini.google.com/app"
    }
  ]
}
```

### Configuration Options

- **`github.organizations`** - Array of GitHub organization names to fetch repositories from
- **`github.paginate`** - Set to `true` to fetch ALL repositories using pagination (default: true)
- **`github.limit`** - Page size for pagination, or max repos if pagination is disabled (default: 1000)
- **`github.enabled`** - Set to `false` to skip GitHub fetching entirely
- **`customLinks`** - Array of custom links with `name` and `url` properties

#### Pagination Details

When `paginate` is `true` (recommended):
- Fetches **ALL repositories** from each organization
- Uses `limit` as the page size for each request (1000 is efficient)
- Shows progress as it fetches each page
- No repository limit - gets everything!

When `paginate` is `false`:
- Fetches only up to `limit` repositories per organization
- Single request per organization (faster but may miss repos)
- Use this if you have many repos and only want the most recent ones

### Updating Your Data

Whenever you want to refresh your repositories or have updated your config:

```bash
npm run fetch-data
```

This script will:
1. Fetch repositories from all configured GitHub organizations
2. Merge in your custom links
3. Generate `src/assets/data.json` for the application to use

## Development

### Available Commands

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run preview      # Preview production build
npm run fetch-data   # Fetch repositories and generate data
npm run lint         # Lint code with ESLint
```

### Project Structure

```
Gateway/
├── config.json              # Your personal configuration (gitignored)
├── config.example.json      # Example configuration template
├── scripts/
│   ├── fetch-data.sh       # Script to fetch GitHub repos and generate data
│   └── setup.sh            # Interactive setup script
├── src/
│   ├── App.vue             # Main application component
│   ├── assets/
│   │   └── data.json       # Generated data file (created by fetch-data.sh)
│   └── main.ts
└── ...
```

## Docker Deployment

Build and run with Docker:

```bash
make build    # Build the Docker image
make launch   # Start the container
```

Or manually:

```bash
npm run fetch-data
npm run build
docker build -t Gateway-page .
docker run -p 5678:8080 Gateway-page
```

Access at `http://localhost:5678`

## GitHub Authentication

If you're fetching from private repositories or organizations, authenticate with GitHub CLI:

```bash
gh auth login
```

Follow the prompts to authenticate. The `fetch-data.sh` script will use your authenticated session.

## Tips & Tricks

- **Keyboard Navigation**: Use ↑/↓ arrow keys to navigate results, Enter to open
- **Fast Search**: The search starts working after 2 characters
- **Multiple Orgs**: You can fetch from as many GitHub organizations as you have access to
- **Mix Public & Private**: Works with both public and private repositories (if authenticated)
- **Pure Custom Links**: Set `github.enabled` to `false` to use only custom links
- **Auto-focus**: The search input automatically focuses when you load the page

## Browser New Tab Integration

Gateway works perfectly as your custom new tab page in modern browsers! Integrate it with these extensions:

### Chrome

Install the [Custom New Tab](https://chromewebstore.google.com/detail/custom-new-tab/lfjnnkckddkopjfgmbcpdiolnmfobflj) extension:

1. Add the extension to Chrome
2. Open the extension settings
3. Set your Gateway URL (e.g., `http://localhost:5678` for local, or your deployed URL)
4. That's it! Your new tabs will now open directly to Gateway

### Firefox

Install the [Custom New Tab Page](https://addons.mozilla.org/en-US/firefox/addon/custom-new-tab-page/) extension:

1. Add the extension to Firefox
2. Right-click the extension icon and select "Options"
3. Enter your Gateway URL in the "New Tab URL" field
4. Click "Save"
5. All new tabs will now use your Gateway page

### Benefits

- **Instant Access**: Open a new tab and immediately access all your repositories and tools
- **Search-Ready**: Focus is automatically in the search field - just start typing
- **No Configuration**: Unlike default new tab pages, Gateway is lightweight and fast
- **Keyboard-Friendly**: Navigate and open items without leaving the keyboard

## Troubleshooting

**"gh not installed" warning**
- Install GitHub CLI: https://cli.github.com/
- Or disable GitHub fetching: set `github.enabled` to `false` in `config.json`

**"jq not installed" error**
- macOS: `brew install jq`
- Ubuntu/Debian: `sudo apt-get install jq`

**"Failed to fetch from organization" warning**
- Check you have access to the organization
- Authenticate with `gh auth login`
- Verify the organization name is correct

**No search results appearing**
- Make sure you ran `npm run fetch-data` successfully
- Check that `src/assets/data.json` exists and contains data
- Verify your `config.json` has valid organizations or custom links

## Customization

### Styling

The app uses Tailwind CSS. Customize the appearance by editing `src/App.vue`.

### Search Behavior

The search algorithm in `src/App.vue` uses a trie-based fuzzy search. You can adjust:
- Minimum search length (currently 2 characters)
- Similarity scoring weights
- Maximum results displayed

## Contributing

Feel free to fork this project and customize it for your needs! This is designed to be a personal tool, so make it your own.

## License

MIT

## Acknowledgments

Built with:
- [Vue 3](https://vuejs.org/)
- [Vite](https://vitejs.dev/)
- [Tailwind CSS](https://tailwindcss.com/)
- [trie-search](https://www.npmjs.com/package/trie-search)
