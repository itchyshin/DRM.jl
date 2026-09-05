# After-task — reader journey and visual identity

## 1. Goal

Make the DRM.jl documentation landing path clearer and more polished while
preserving every existing documentation route, capability boundary, and
source/generated-output separation.

## 2. Implemented

- Reordered the first navigation label to **Start** and renamed the capabilities
  entry **Evidence & limits**, without moving its route.
- Reframed the landing page around the reader sequence: first model, what a
  parameter-specific fit estimates, evidence/limits, and the drmTMB relation.
- Added a compact three-card route chooser, shared VitePress CSS tokens,
  responsive rules, light/dark tokens, and an editable convergence SVG mark.
- Added two non-destructive SVG candidates and a documented palette,
  accessibility, and maintenance rationale.
- Added a Claude coordination note and a review receipt; no external action was
  taken.

## 3a. Decisions and Rejected Alternatives

The selected convergence mark represents mean, spread, and association joining
in one fitted distribution. The axis and density candidates remain reviewable
but were not promoted: they are less distinctive at small sizes. The CSS is an
override file rather than a fork of the DocumenterVitepress theme. GLLVM.jl was
used as a finish benchmark, not copied; drmTMB wording and GPL source were not
imported.

## 4. Files Touched

- `docs/make.jl`
- `docs/src/index.md`
- `docs/src/.vitepress/theme/style.css`
- `docs/src/assets/logo.svg`
- `docs/src/assets/identity/drm-mark-convergence.svg`
- `docs/src/assets/identity/candidates/drm-mark-axis.svg`
- `docs/src/assets/identity/candidates/drm-mark-density.svg`
- `docs/design/visual-identity.md`
- `docs/dev-log/handover/2026-09-05-claude-reader-journey-visual-review.md`
- `docs/dev-log/check-log.d/2026-09-05-reader-journey-identity.md`
- this report

## 5. Checks Run

- `cd docs && julia --project=. make.jl` — exit 0. Documenter completed
  doctests, cross-references, document checks, Markdown generation, and
  VitePress static rendering.
- Built output inspection confirmed `build/1/logo.svg`, the raw linked route
  cards, and the five preserved navigation groups.
- Browser inspection at desktop, **390 × 844**, and dark mode confirmed the
  mark, readable action buttons, responsive one-column cards, and mobile
  navigation drawer.
- `git diff --check` — no whitespace errors.

## 6. Tests of the Tests

The first render exposed two real integration failures: a root-working-directory
run made existing examples seek `build/...` in the wrong place, and the first
version used an asset path that DocumenterVitepress did not publish plus escaped
HTML cards. Running from `docs/`, using the supported `logo.svg` public path,
and marking the card block as raw HTML changed those failures into a fully
rendered site.

## 7a. Issue Ledger

No issue was opened or closed. This is a reviewable docs-only enhancement, not
a release or capability promotion.

## 8. Consistency Audit

Read the current DRM.jl README, `HANDOVER.md`, `ROADMAP.md`, document config,
home page, capabilities page, drmTMB public docs/configuration, and GLLVM.jl
presentation. The copy preserves the optional Julia bridge, the default R TMB
engine, model-specific performance/inference evidence, and the MIT/GPL boundary.
All existing page entries stayed in `docs/make.jl`.

## 9. What Did Not Go Smoothly

The initial command was launched from the repository root rather than `docs/`;
Documenter's existing executable examples then looked for relative `build/`
paths in the wrong location. A first pass also revealed that this
DocumenterVitepress version only promotes logo/favicon assets to VitePress
public output and escapes ordinary HTML. Both were corrected without loosening
the strict build gate.

## 10. Known Residuals

The mark is a proposal pending human visual review, not a public default or
registered trademark. No durable PNG screenshot files were committed: the
review captures were inspected in the local browser, and ignored `docs/build/`
is intentionally not versioned. The build reports a non-blocking VitePress
chunk-size advisory and expected local no-deployment/no-favicon warnings.

## 11. Team Learning

Route an editable SVG through `docs/src/assets/logo.svg` when using this
DocumenterVitepress setup; other arbitrary `assets/` files do not automatically
reach the final VitePress public directory. Use `@raw html` for semantic landing
components so Documenter does not escape them. Model-specific evidence language
belongs on the first screen, where it helps users choose a route before they
copy an example.

## 12. Cross-Product Coverage

This slice covers ✓ the landing-page reader path, navigation labels, responsive
route cards, light/dark theme tokens, accessible SVG alt text, and local static
rendering. It does NOT cover release readiness, deployment, registry status,
API changes, source-engine changes, a new capability claim, interval coverage,
all browser/device combinations, a human trademark decision, or a persisted
screenshot artifact.

Memory receipt: `route.py` returned no worktree manifest; the lightweight
memory lookup was used only to preserve the DRM.jl Gaussian-only REML and
claim-boundary guard. No Golden-Set or engine/model-family change was in scope.
Golden Set: not in scope; this lane changed documentation presentation only and
the full strict documentation render was the applicable product check.
