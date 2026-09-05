# DRM.jl visual identity proposal

## Chosen concept: convergence mark

`src/assets/logo.svg` is the proposed site mark (with an editable working copy
at `src/assets/identity/drm-mark-convergence.svg`). Three
coloured paths (mean, spread, association) meet in a dark fitted-distribution
disc. It communicates the package's central promise—separate model components
forming one response distribution—without borrowing the drmTMB hex logo or the
Julia dots. The SVG is the home-page mark only; it does not replace any existing
logo because no DRM.jl logo asset was present at the start of this lane.

## Reviewable alternatives

- `assets/identity/candidates/drm-mark-axis.svg`: an analysis-axis motif. Clear,
  but too close to a generic plotting package.
- `assets/identity/candidates/drm-mark-density.svg`: a distribution-and-parameters
  motif. Scientifically literal, but less recognisable at small sizes.

The chosen mark has the strongest small-size silhouette and can be read without
requiring colour alone.

## Palette and accessibility

| Token | Hex | Role |
|---|---:|---|
| Ink | `#132735` | headings, fitted-distribution disc, high-contrast text |
| Parameter blue | `#176b87` | primary action and mean path |
| Parameter teal | `#08796f` | model-map path |
| Parameter coral | `#c55e4a` | evidence/limitation path |
| Mist | `#edf4f5` | light surface |

Colour supplements labels, borders, and copy; it does not encode a meaning by
itself. The mark includes a textual `DRM.jl` label, accessible title and
description, and a high-contrast ink outline. The CSS supplies equivalent dark
mode tokens, preserves 16px-or-larger body text, and reduces the route-card grid
to a single column on narrow screens.

## Maintenance boundary

The theme is limited to `docs/src/.vitepress/theme/style.css`, which overrides
DocumenterVitepress tokens rather than copying its theme. Keep this file focused
on shared tokens and the documented landing components; page-specific additions
should not become a second layout system.
