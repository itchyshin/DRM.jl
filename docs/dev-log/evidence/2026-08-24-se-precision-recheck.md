# `phylo_count_large_p` SE precision recheck (issue #487)

Date: 2026-08-24 · lane: DRM.jl (Karpinski + Hopper, isolated worktree) ·
anchor: installed drmTMB 0.7.0 / `origin/main` at 8d45b651 · seed 20260824 ·
tolerance 1e-4

## Why

A large-p probe extending `phylo_count_large_p` to p=1000/3000 reported
`max_rel_se_diff ≈ 1.6e-03` (p=1000) and `≈ 1.5e-03` (p=3000) by eyeballing
SE vectors that script printed with `sprintf("%.6f", ...)` — display-rounded,
and the script never computed `max_abs_se_diff`/`max_rel_se_diff` at all. That
is ~200x looser than the full-precision `poisson_phylo_p300` figure
(7.91e-06) already on record, while coefficient and logLik agreement stayed
tight throughout (#487). Filed rather than resolved, because a figure derived
from rounded display output does not belong in a measured-evidence column.

This settles it: `tools/parity_classc_largep.R` now computes full-precision
`max_abs_se_diff`/`max_rel_se_diff` (fixed-effect Wald SE =
`sqrt(diag(vcov(fit)))`, same pattern `tools/parity_classc.R` uses for its own
SE columns) at p = 300, 1000, 3000, on the same seed/DGP for all three, plus
the reciprocal condition number of each engine's returned `vcov(fit)`.

## Method

`tools/parity_classc.R` was **not modified**. `tools/parity_classc_largep.R`
copies its `make_phylo_count_fixture(seed, p, m, ...)` verbatim and calls it at
p ∈ {300, 1000, 3000}, seed 20260824, m=4 (same seed/DGP as the existing
`poisson_phylo_p300` cell), fitting `y ~ x + phylo(1 | species, tree = tree)`
via `engine = "tmb"` and `engine = "julia"` in one R session (so JuliaCall/DRM
loads once, not three times). Each engine timed separately (D-139); native TMB
wrapped in a 25-minute wall-clock ceiling (not hit at any p).

**rcond**: `src/vcov_guard.jl`'s `_vcov_from_hessian` guard — read, not
touched — is **not actually in the call path for this route**. The phylo
Poisson ML fit runs through `src/sparse_laplace_glmm.jl`'s
`_fit_poisson_general_laplace`, which computes the returned fixed-effect vcov
inline as `try inv(Symmetric(Hθ)) catch → identity`, with no conditioning
diagnostic exposed anywhere in that path (checked by reading both files).
`rcond` is therefore computed independently here, as the reciprocal condition
number (`min|eig| / max|eig|`) of the 2×2 `vcov(fit)` matrix each engine
actually returns (the same matrix `se_of()` takes `sqrt(diag())` of) — for
both the native-TMB side and the DRM.jl side, at each p.

Comparator provenance (`tools/drmtmb_provenance.R`, copied unmodified from
`feat/drmtmb-catchup` into this worktree since it didn't yet exist on
`origin/main`; drmTMB **not reinstalled**):

```
drmtmb_version = "0.7.0"
drmtmb_built = "R 4.6.0; aarch64-apple-darwin23; 2026-08-15 01:49:56 UTC; unix"
drmtmb_code_hash = "8dc7c6cd77f8d5cf8bebc9adb29a5a53900d2d320de074bde43cba8fa4e1bb7e"
```

Identical `code_hash` to every prior `phylo_count_large_p` measurement — same
comparator build, no drift.

D-139: prior runs of this same route measured tmb=0.40–1.61s and
julia=1.9–28s (JuliaCall-startup-dominated) at p=1000/3000; three sizes in one
session, well under 30 min. Ran directly; actual total wall time ~25s of
fit cost plus one ~20s JuliaCall/DRM load.

## Results — full precision, same run

| p | engine=tmb (s) | engine=julia (s) | max\|Δcoef\| | \|Δlogℓ\| | max_abs_se_diff | **max_rel_se_diff** | status |
|---|---|---|---|---|---|---|---|
| 300 | 0.15 | 19.96 (incl. one-time JuliaCall/DRM load) | 3.818e-07 | 3.669e-09 | 1.974e-06 | **7.914e-06** | PARITY_PASS |
| 1000 | 0.35 | 0.22 | 8.617e-08 | 8.013e-10 | 4.809e-04 | **1.555e-03** | PARITY_PASS |
| 3000 | 1.53 | 2.00 | 1.027e-05 | 7.931e-10 | 3.985e-04 | **1.470e-03** | PARITY_PASS |

The freshly measured p=300 value (7.914e-06) reproduces the previously
recorded full-precision figure (7.91445853527365e-06) to 6 significant
figures — same seed/DGP, deterministic fixture generation, cross-lane
agreement. The p=1000/p=3000 full-precision values (1.555e-03, 1.470e-03) are
within ~3% of the old rounded-display estimates (~1.6e-03, ~1.5e-03).

## rcond(vcov) by p

| p | rcond tmb | rcond julia |
|---|---|---|
| 300 | 8.115e-03 | 8.115e-03 |
| 1000 | 2.522e-03 | 2.530e-03 |
| 3000 | 9.474e-04 | 9.502e-04 |

Condition numbers (1/rcond) run from ~123 (p=300) to ~1053 (p=3000) —
monotonically worsening, roughly ∝ 1/p, on **both** engines almost identically
at every p. None of these are remotely near `_vcov_from_hessian`'s own
singularity threshold (`rtol = 1e-12`, i.e. condition number > 1e12); nothing
here is close to a boundary/near-singular fit.

## Verdict

**The trend is real, not a rounding artifact.** The full-precision p=1000/3000
numbers closely reproduce what the display-rounded probe suggested (within
~3%), and the ~200x jump from p=300 (7.91e-06) to p=1000/3000 (~1.5e-03) is
measured at full IEEE-754 double precision on both sides — six-figure display
rounding cannot manufacture a difference four significant figures deep. Had
this evaporated at full precision, that would have been the better outcome
(#487 said so explicitly); it did not.

**It does not cleanly track conditioning, though it moves in the same
direction.** rcond degrades smoothly and monotonically across all three
points (~3.2x worse per ~3.3x growth in p, close to 1/p). `max_rel_se_diff`
does not move proportionally to that: it jumps ~196x between p=300 and
p=1000 while rcond only worsens ~3.2x over the same step, then **decreases**
slightly (1.555e-03 → 1.470e-03) from p=1000 to p=3000 even as rcond keeps
worsening a further ~2.7x. A "two factorisations accumulating rounding in
proportion to conditioning" story would predict smooth, monotone growth in
`max_rel_se_diff` tracking 1/rcond at every step; that is not what is
measured. The direction is consistent (both p=300→1000 conditioning and SE
divergence worsen together), but the disproportionate size of that first
jump and the plateau/slight-improvement from 1000→3000 are not explained by
conditioning alone.

**Not settled by this probe:** three points cannot distinguish a genuine step
change somewhere between p=300 and p=1000 from a smooth function this
sampling is too coarse to resolve. That would need denser sampling (e.g.
p=500, 700) to pin down — out of scope here, and not claimed.

**What is NOT in question:** coefficient (8.6e-08 to 1.0e-05) and logLik
(≤8.0e-10) agreement stay tight at every p; every cell is `PARITY_PASS` on
the existing <1e-4 coefficient/logLik criterion; no tolerance was widened; no
capability row was promoted. The `<0.2%` SE criterion the original probe
applied is true and remains true at full precision — this recheck sharpens
*how* true it is (0.16% at p≥1000, not the ~1e-06 seen at p=300), which is the
`claim_boundary` wording point #487 raised.

## What this does NOT establish

No claim about behaviour beyond p=3000. `phylo_count_large_p` stays
`experimental`. This is a same-target SE-precision measurement only.
