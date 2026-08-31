# S13 additional Documenter visual audit — 2026-08-31

## Scope and provenance

- **Repository inspected:** `/private/tmp/drm-parity-20260830/integration/DRM.jl`
- **Current checkout at audit:** `2de4435c6826b1fa9d77c1897f2a0ec172bf2172`.
- **Rendered artifact inspected:** `docs/build/integration-production-002/1`.
- **Build provenance:** `production-docs-20260831/green-002-receipt.json` records a strict, production-navigation build at `5d56524b7d7c8bf11f4128ce30ec71f105f72ac4`, exit 0, 52 source pages and 134 example blocks. It is older than the current working checkout and is intentionally retained rather than rebuilt.
- **Server:** a temporary, local read-only `python3 -m http.server` on `127.0.0.1:51337`; no deployment, build, fit, installation, or source edit.
- **Known raw-output limitation observed again:** the retained strict split-render build does not contain `versions.js` or `siteinfo.js`; requests for those files returned 404. This repeats the already retained raw-render metadata boundary, rather than creating a new page-layout verdict.
- **Auditor:** Pat visual/reader audit. Requested routing was Terra/medium; the active model/routing was not exposed through the available audit tools, so it is not asserted here.
- **Prior sample excluded:** homepage, model-fitting/reference navigation, engine internals, and finite-state reference coverage recorded in `production-docs-20260831/visual-001.json`.

## Pages newly sampled

| Area | URL | Desktop light | Additional mode |
|---|---|---|---|
| Tutorial | `/tutorials/location-scale.html` | `01-location-scale-desktop-light.png` | mobile light and dark (`07`, `06`) |
| Tutorial | `/tutorials/bivariate-nongaussian.html` | `02-bivariate-nongaussian-desktop-light.png` | desktop light |
| Reference | `/reference/model-specification.html` | `03-model-specification-desktop-light.png` | mobile light/dark (`09`, retained `06-model-specification-mobile-dark`) |
| Developer navigation | `/developer-notes/formula-grammar.html` | `04-formula-grammar-desktop-light.png` | desktop dark (`05`) and expanded mobile navigation (`10`) |

## Viewports and observations

- Desktop: 1280 x 720. Each four newly sampled page had a readable page title, active section navigation and table of contents, and `documentElement.scrollWidth == innerWidth` (no document horizontal overflow). Browser console had no warning or error entries while sampling.
- Phone: 390 x 844. The location-scale and model-specification pages exposed the mobile navigation control and stayed within the viewport (`documentElement.scrollWidth == 390`). Light and dark appearance both rendered successfully; the explicit viewport override was reset after testing.
- On the formula-grammar page, the mobile navigation button opened successfully (`aria-expanded=true`) and exposed the expected Start here, Model guides, Tutorials, Diagnostics, and Reference links without page overflow or console messages.
- Long code blocks are horizontally scrollable at phone width. That is controlled overflow, not page overflow. The first, third, fifth and seventh location-scale examples have `pre.scrollWidth` 686–813 px at a 390 px viewport.

## Findings

1. **P2 — improve phone readability of short teaching expressions.** `tutorials/location-scale.md:33-34` and `:47-48` are compact instructional comparisons but require horizontal scrolling at 390 px. Consider splitting the `drm(...)` call across lines and putting the response-scale expressions on separate short blocks or prose. This preserves code copyability while letting a reader see the full teaching point without a horizontal gesture. Longer simulation blocks can remain scrollable.
2. **No new blocking visual/accessibility finding in this four-page sample.** Desktop navigation, sidebar/TOC presence, light/dark rendering, mobile navigation affordance, and page-level overflow checks passed for the stated pages. The raw build's missing `versions.js` / `siteinfo.js` resources remain a separate known metadata failure. This is sample evidence only; it does not establish full G6, an all-page visual audit, a fresh candidate build, deployed-site correctness, keyboard traversal, or an assistive-technology audit.

## Screenshot checksums

All screenshots are PNGs in this directory. SHA-256 values are in `SHA256SUMS.txt`.
