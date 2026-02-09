# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Quartz v4 is a static site generator that transforms Markdown files (from an Obsidian vault) into a website. Built with TypeScript, Preact, and unified (remark/rehype). The content directory uses PARA methodology (Projects, Areas, Resources, Archive).

## Common Commands

```bash
npm run check          # Type-check (tsc --noEmit) + format check (prettier)
npm run format         # Auto-format with Prettier
npm test               # Run tests (tsx --test, finds *.test.ts files)
npx quartz build -d content          # Build the site from content/
npx quartz build --serve -d content  # Build + serve with hot reload
npx quartz build --serve -d docs     # Serve the Quartz documentation
```

Node >= 22 and npm >= 10.9.2 required (`.node-version` pinned to 22.16.0).

## Code Style

- **No semicolons**, 100-char line width, trailing commas, 2-space indentation (Prettier)
- JSX uses **Preact** (`jsxImportSource: "preact"`), not React
- ESM modules (`"type": "module"`)
- Strict TypeScript with `noUnusedLocals` and `noUnusedParameters`
- No ESLint -- only `tsc` + `prettier` for checking

## Architecture

### Three-Phase Content Pipeline

1. **Parse** (`quartz/processors/parse.ts`): Glob `*.md` files -> text transforms -> remark (MD AST) -> remarkRehype -> rehype (HTML AST). Uses a worker pool for parallel processing.
2. **Filter** (`quartz/processors/filter.ts`): Each filter plugin's `shouldPublish()` decides if content reaches output.
3. **Emit** (`quartz/processors/emit.ts`): Emitter plugins generate HTML pages, RSS, sitemap, CSS/JS bundles, OG images, etc. Emitters run in parallel.

Build orchestration lives in `quartz/build.ts`. The CLI (`quartz/bootstrap-cli.mjs` -> `quartz/cli/handlers.js`) uses esbuild to transpile the build system into `.quartz-cache/` before execution.

### Plugin System (`quartz/plugins/types.ts`)

Three plugin types, all factory functions `(opts?) => PluginInstance`:

- **Transformers** (`quartz/plugins/transformers/`): Process content during parsing. Can hook into `textTransform()`, `markdownPlugins()` (remark), `htmlPlugins()` (rehype), and `externalResources()`.
- **Filters** (`quartz/plugins/filters/`): Boolean `shouldPublish()` gate.
- **Emitters** (`quartz/plugins/emitters/`): Generate output files. Support `emit()` for full builds and `partialEmit()` for incremental rebuilds.

Plugins are configured in `quartz.config.ts`. Page layout (which components go in sidebar/header/footer) is configured in `quartz.layout.ts`.

### Component System (`quartz/components/`)

`QuartzComponent` extends Preact's `ComponentType` with optional `css`, `beforeDOMLoaded`, and `afterDOMLoaded` static properties for component-specific styles and client-side scripts.

Components are **constructor functions** (`QuartzComponentConstructor`): called with options to produce a configured component (e.g., `Component.Footer({ links: {...} })`).

Client-side scripts use the `*.inline.ts` naming convention and are bundled separately by esbuild as minified browser code.

Page rendering (`quartz/components/renderPage.tsx`) clones the HAST tree, resolves transclusions, assembles the layout, and renders to HTML via `preact-render-to-string`.

### Path System (`quartz/util/path.ts`)

Uses branded types (`FullSlug`, `SimpleSlug`, `RelativeURL`, `FilePath`) with runtime typeguards. Supports three link resolution strategies: `absolute`, `shortest`, `relative`.

### Content Representation (`quartz/plugins/vfile.ts`)

- `MarkdownContent = [MdRoot, VFile]` -- after markdown parsing
- `ProcessedContent = [HtmlRoot, VFile]` -- after HTML processing
- VFile `data` carries slug, filePath, frontmatter, etc.

## Testing

Tests are co-located with source files using `.test.ts` suffix. Uses Node.js built-in test runner (`node:test` with `node:assert`), executed via `tsx --test`.

## CI

Runs on push/PR to `v4` branch across Windows, macOS, Ubuntu: `npm run check` -> `npm test` -> `npx quartz build --bundleInfo -d docs`.
