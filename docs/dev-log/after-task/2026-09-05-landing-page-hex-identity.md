# After-task — landing page and hex-badge identity

Date: 2026-09-05 · Lane: `claude/landing-page-opus-20260905` · Platform: Claude Code (Opus)
Worktree: `local-scratch/lanes/DRM.jl-landing-opus-20260905` · Base: `d3efbad2f`

## 1. Goal
Give the docs site a landing page and a visual identity of its own, at a finish
comparable to GLLVM.jl, without copying its content or widening any capability
claim.

## 2. What landed
`2d621cef6` — 7 files: `docs/src/index.md`, `docs/src/.vitepress/theme/overrides.css`,
`docs/make.jl` (two nav labels), and four new assets under `docs/src/assets/`.

## 3. Identity
Two density curves sharing one mean, one narrow and one wide, on a hexagonal
badge — *same mean, different spread*, which is the package's own subject.
`drmjl-mark.svg` is the editable master; `logo.png` is the published asset and
DocumenterVitepress wires it into the navbar at 24 px by itself
(`vitepress_config.jl:143`). Rejected alternative: the "convergence mark" from
`371864fcc` — its embedded wordmark is ~2 px tall at navbar size and its light
tile glares on a dark ground.

**Defect fixed in the source geometry.** The outline began at the top vertex
while its closing curve ended 16 units to the right, so `Z` drew a flat spur
across the apex; the inner ring had the same bug. Both paths now start where
their closing curve ends.

## 4. Copy — three claims corrected against the repo's own evidence
| Was | Why it failed | Citation |
|---|---|---|
| formulas for "mean, scale, **shape**, correlation" | no test or doc puts a covariate on `nu`; Gamma/Beta shape is a `sigma` reparameterisation | `capabilities.md:62`; `src/gamma.jl:14-15` |
| correlation "**of a response**" | `rho12` is rejected in the univariate bundle | `src/gaussian_core.jl:50,62-64` |
| the R bridge "**serves**" its cells | round-trip is *Absent here*; the page is labelled Experimental | `capabilities.md:263`; `r-julia-bridge.md:3` |
Also: the log-σ reading is now scoped to Gaussian (Gamma is a CV, Beta a
precision), and `zi`/`hu`/`zoi`/`coi` were restored after an earlier draft
dropped four Tested capabilities. No speed, parity or coverage figure appears.

## 5. Theme — the finding that generalises
`theme/style.css` is a **takeover, not an override**: DocumenterVitepress writes
its 322-line default only when that file is ABSENT (`vitepress_config.jl:61-63`).
Creating it silently drops the only JuliaMono `@font-face`, the only rule making
display maths scrollable, and every rule behind the sidebar drawer toggle — with
a clean exit 0. Customisations therefore live in `overrides.css`, which this repo
already imports after the theme (`index.ts:25`). A comment in the file records why.

Palette is drawn from the mark, but the mark's teal is 3.09:1 on white, so links
and buttons take an AA-safe sibling. `.VPHero .image-container` is capped at
`min(320px, 100%)` because upstream fixes it at 320 px with no max-width.

## 6. Verification (full local build, `make.jl` exit 0)
- Hero renders: `VPHero` present, zero leaked front matter.
- 55 pages; all five hero targets resolve, plus `/get-started`, a live route
  absent from the nav (a stub from `make_stubs.jl:16`).
- Shipped bundle still contains `JuliaMono-Regular` and `.mjx-scroll-wrapper`.
- Display-maths page at 390 px: both equations scroll internally, body does not.
- No horizontal overflow at 1440 / 390 / **320** px; contrast passes AA in both themes.
- Only console 404 is `/versions.js`, generated at deploy time.

## 7. Not done / carried over
No push, PR, merge or deploy. Rose audit not run. The `Project.toml` version
(`0.7.0`) and `HANDOVER.md` (`0.1.2`) disagree — pre-existing, untouched here.

## 8. Ownership
Lease held on `docs/src/index.md`, `docs/src/assets/`, `overrides.css`,
`docs/make.jl`. Superseded the earlier "Astra keeps the lease" decision at
Shinichi's explicit direction. Lanes `83ac12d00` (assets) and `371864fcc`
(prose) were used as sources and are not modified.
