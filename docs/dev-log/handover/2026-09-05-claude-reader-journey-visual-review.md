# Claude review note — DRM.jl reader journey and visual identity

## Scope and ownership

This is a **Codex-owned docs-only worktree lane**. It changes the Documenter
navigation label, home-page reader journey, VitePress theme override, editable
SVG marks, and review notes. It does **not** change `src/`, public API,
capability status, fixtures, deployment, registry state, or the idle registry
task. Do not move this work into another checkout by copying generated `docs/build/`
files; that directory is ignored render output.

## Review packet

Open the local output after a fresh render from `docs/`:

```sh
julia --project=. make.jl
python3 -m http.server 8765 --directory build/1
```

The visual review captured the landing page at a desktop viewport, at **390 ×
844** (mobile), and in dark mode. Check that:

1. the convergence mark appears both in the navbar and hero;
2. the three route cards are linked and stack to one column on mobile;
3. the page says what is estimated, where to find evidence, and how DRM.jl
   relates to drmTMB without widening any capability claim; and
4. the existing five navigation groups and every existing route remain present.

The local full render exited 0 on 2026-09-05. It exercised document examples,
cross-references, checks, static rendering, and VitePress rendering. It issued
only the existing non-blocking VitePress chunk-size advisory and the expected
no-deployment / no-favicon local warnings.

## Identity decision

The selected `docs/src/assets/logo.svg` is a copy of the editable convergence
mark. The source concept and candidates are retained in
`docs/src/assets/identity/` and explained in `docs/design/visual-identity.md`.
Do not replace the mark with drmTMB branding: the twin relationship is explained
in copy, while DRM.jl keeps an independent MIT identity.

## Collaboration boundary

Claude can review prose, claim scope, and SVG concept. Please do not alter
`docs/src/index.md`, `docs/make.jl`, or `docs/src/.vitepress/theme/style.css`
while this commit is under review; send proposed text or design changes as a
bounded follow-up. No external message, preview deployment, release, registry
action, or push is authorised by this lane.
