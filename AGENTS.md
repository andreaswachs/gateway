# Repository Guidelines

## Project Structure & Module Organization
The Vue 3 + Vite client lives in `src/`, where `main.ts` mounts `App.vue` and styles live in `src/assets/main.css`. Shell helpers under `scripts/` (`fetch-data.sh`, `setup.sh`, `validate-config.sh`) populate `src/assets/data.json` from `config.json`; share reusable defaults through `config.example.json`. Static assets that bypass bundling go in `public/`, while Docker and Caddy files in the repo root define deployment paths.

## Build, Test, and Development Commands
- `npm run dev`: refresh data then launch Vite on `localhost:5173`.
- `npm run build`: run `vue-tsc --build` plus `vite build`, emitting `dist/`.
- `npm run preview`: serve the production bundle for smoke tests.
- `npm run type-check`: run TypeScript compiler to verify type correctness.
- `npm run lint`: apply the repo ESLint rules; fix issues before committing.
- `npm run fetch-data`, `npm run setup`, `npm run validate`: execute the helper scripts without starting Vite; reuse them in CI or Docker steps.

## Testing Guidelines
Automated tests are absent, so rely on `npm run type-check`, `npm run lint`, and `npm run preview` to prevent regressions. If you add coverage, favor Vitest + Vue Test Utils colocated under `src/` (e.g., `App.spec.ts`). When tests exist:
- Run all tests: `npm test`
- Run single test file: `npm test App.spec.ts`
- Run tests in watch mode: `npm test -- --watch`
- Run tests with coverage: `npm test -- --coverage`

Manual QA should confirm `npm run fetch-data` regenerates `src/assets/data.json`, keyboard navigation works, and the Tailwind layout holds up in dark and light themes; document any untested cases in your PR.

## Coding Style & Naming Conventions

### TypeScript & Vue Components
- Use TypeScript with strict mode enabled via `@vue/tsconfig`.
- All components use `<script setup>` syntax with two-space indentation.
- Component files must end in `.vue` and use PascalCase for both filename and export.
- Composables and utilities use camelCase (e.g., `useSearch`, `formatUrl`).
- Reactive refs mirror trie entities: use `searchResults`, `selectedIndex`, etc.
- Define interfaces for complex types (e.g., `DataItem { name, url }`).

### Import Ordering
Organize imports in this order:
1. Vue core imports (`import { ref, onMounted } from 'vue'`)
2. Third-party libraries (`import TrieSearch from 'trie-search'`)
3. Local imports (`import jsonData from '@/assets/data.json'`)

### Styling & Tailwind
- Prefer Tailwind utility classes over ad-hoc CSS.
- Use `@/` alias for imports from `src/` directory.
- Only extend `tailwind.config.js` when a token is reused across components.
- Use two-space indentation for all files.

### Shell Scripting
- All shell scripts must start with `#!/bin/bash` and `set -e` for error handling.
- Use meaningful variable names in uppercase (`GITHUB_ENABLED`, `ORGANIZATIONS`).
- Always validate JSON with `jq empty` before processing.
- Use temporary files with `mktemp` and clean up on exit.
- Provide clear error messages with context and fix suggestions.

## Error Handling & Validation
- Shell scripts must validate dependencies (`jq`, `gh`) before execution.
- Check `config.json` exists and is valid JSON before processing.
- Generate `data.json` with atomic writes (write to temp, then `mv`).
- TypeScript should leverage strict type checking—no `any` unless absolutely necessary.
- Use optional chaining (`?.`) and nullish coalescing (`??`) for safe property access.

## Security & Configuration Tips
Never commit personalized `config.json` contents or generated `src/assets/data.json` that expose internal URLs. Use `config.example.json` plus `npm run setup` to share reproducible settings, keep tokens outside the repo, and log out of `gh` on shared workstations. Review shell script diffs carefully—they run before the dev server and affect every contributor.

## Commit & Pull Request Guidelines
History uses concise imperative subjects ("first commit"); continue that tone, reference related issues, and keep each commit focused on a single concern. Pull requests should summarize scope, list the validation commands run, and include screenshots or GIFs for UI updates. Call out config or script changes so reviewers know when to rerun `npm run fetch-data` or `npm run validate`, and mention host/port expectations for Docker or Caddy edits.

## Development Workflow
1. Run `npm run fetch-data` after modifying `config.json`.
2. Use `npm run type-check` and `npm run lint` before committing.
3. Preview changes with `npm run build && npm run preview`.
4. Test keyboard navigation (Arrow Up/Down, Enter) in the search interface.
5. Verify Tailwind layout in both light and dark themes.

## TypeScript Configuration
- Paths: `@/*` maps to `./src/*` for cleaner imports.
- Exclude `src/**/__tests__/*` from build to avoid test inclusion.
- Use `tsBuildInfoFile` in `node_modules/.tmp/` for incremental builds.

## Vite Configuration
- `@/` alias resolves to `src/` directory.
- Vue DevTools plugin loads only in dev mode (`command === 'serve'`).
- Build outputs to `dist/` via `vite build`.

## ESLint Configuration
- Extends `pluginVue.configs['flat/essential']` and `vueTsConfigs.recommended`.
- Lints all `.ts`, `.mts`, `.tsx`, and `.vue` files.
- Ignores `dist/`, `dist-ssr/`, and `coverage/` directories.
