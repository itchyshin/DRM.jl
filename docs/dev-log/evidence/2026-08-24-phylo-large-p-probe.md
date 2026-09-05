# `phylo_count_large_p` — extending the measurement past p=300

Date: 2026-08-24 · lane: DRM.jl (Hopper + Karpinski, isolated worktree) ·
anchor: installed drmTMB 0.7.0 / `origin/main` at 8d45b651 · seed 20260824 ·
tolerance 1e-4

## Why

`phylo_count_large_p`'s `claim_boundary` (drmTMB's `julia-capabilities.tsv`,
row 6) says *"Large-p phylogenetic random-intercept route"*. All prior
same-target evidence (`docs/dev-log/evidence/2026-08-24-classc-cells.md`,
`docs/dev-log/evidence/parity-classc.tsv`) tops out at p=300. That does not
establish the row's own "large p" claim. This slice extends the measurement
to p=1000 and p=3000, under D-139 timing discipline, because native drmTMB's
phylogenetic factorisation is dense O(p³) while DRM.jl's is sparse — the cost
asymmetry between the two engines is the thing actually being tested, and it
can in principle blow up.

## Method

`tools/parity_classc.R` was **not modified**. Its `make_phylo_count_fixture(seed,
p, m, ...)` already takes `p` as an argument; a new script,
`tools/parity_classc_largep.R`, copies that function verbatim (same seed
20260824, same `beta`/`sd_phy` defaults, `m=4`) and calls it at p=1000 and
p=3000, fitting the SAME `dat` object twice through `drmTMB(..., engine =
"tmb")` and `drmTMB(..., engine = "julia")` — no separate data generation per
engine, so the "same bytes" concern does not apply here (unlike a manual
cross-language RNG scenario, the bridge marshals the identical R fixture into
Julia). Each engine's fit is timed separately with `system.time()`. The
native TMB fit is wrapped in a 25-minute `setTimeLimit()` safety net: if the
dense factorisation diverges or hangs, that is treated as the finding, not a
script bug. Comparator build recorded via `tools/drmtmb_provenance.R --toml`
(copied read-only from `origin/feat/drmtmb-catchup@031eaa43`, not merged
into this branch — not committed here; drmTMB itself was **not reinstalled**):

```
drmtmb_version = "0.7.0"
drmtmb_built = "R 4.6.0; aarch64-apple-darwin23; 2026-08-15 01:49:56 UTC; unix"
drmtmb_code_hash = "8dc7c6cd77f8d5cf8bebc9adb29a5a53900d2d320de074bde43cba8fa4e1bb7e"
```

This is the identical `code_hash` recorded for the p=300 classc measurement —
same comparator build, no drift.

One-time setup note: this worktree's Julia `Project.toml` had no
`Manifest.toml` and `Pkg.instantiate()` had never been run in it, so the
first p=1000 attempt failed with `ArgumentError: Package ForwardDiff ...
required but does not seem to be installed`. Ran `Pkg.instantiate()`
(dependency install only — nothing under `src/` touched) before re-running.
Intermittent `LogExpFunctionsInverseFunctionsExt` precompile-race warnings
appeared in later runs (this machine is shared; several other lanes were
running concurrent Julia processes against the same `~/.julia` depot) — these
occurred **after** the fit results were already printed and did not affect
either run's reported numbers.

## D-139 estimates and gate

**p=1000 (pre-run):** p=300's dense factorisation was part of an 8-fit
script that finished well under 5 minutes total, most of that fixed
JuliaCall/R startup. Cubic-scaling (1000/300)³ ≈ 37× put the native TMB fit
at an estimated tens of seconds to ~2 minutes — safely under 30 minutes.
Ran directly.

**p=3000 (estimate stated before running):** from the measured p=1000 native
TMB wall-clock (0.40s), the task's own first-order method — cubic scaling,
(3000/1000)³ = 27× — gives **10.8 sec**. DRM.jl/Julia was projected at
25–40 sec (the p=1000 Julia wall-clock was dominated by one-time JuliaCall
startup, not fit cost, and the sparse route is expected to scale far better
than cubic). Total script estimate: well under 5 minutes, far below the
30-minute gate. Per the task's own decision rule (estimate ≤30 min → run it),
p=3000 was run. Actual TMB time (1.61s) came in under even that small
estimate — no blow-up observed in this range.

## Results

| p | m | n | engine=tmb (sec) | engine=julia (sec) | max\|Δcoef\| | \|Δlogℓ\| | SE (tmb / julia) | status |
|---|---|---|---|---|---|---|---|---|
| 1000 | 4 | 4000 | 0.40 | 27.69 | 8.617e-08 | 8.013e-10 | 0.309171,0.015529 / 0.308690,0.015529 | PARITY_PASS |
| 3000 | 4 | 12000 | 1.61 | 21.85 | 1.027e-05 | 7.931e-10 | 0.271078,0.008344 / 0.270679,0.008344 | PARITY_PASS |

Both fits verified as REAL before comparison: non-empty, non-NA coefficients,
finite logLik, on both engines, at both p. Family: Poisson, `phylo(1 |
species, tree = tree)` mean intercept (matching the p=300 `poisson_phylo_p300`
cell's family/formula; NB2 was not re-run here — Poisson alone answers the
large-p question this slice targets, within the time budget).

The `engine="julia"` wall-clock at both p is dominated by one-time
JuliaCall/R session startup (loading the Julia runtime, activating the
project, `require`-ing DRM), not the sparse fit itself — the fit-only cost is
not separately instrumented by this probe. Native TMB's dense O(p³)
factorisation stayed cheap in absolute terms at both p=1000 and p=3000
(1.61 sec even at p=3000); the anticipated cost asymmetry did not manifest in
this range. It would be expected to show up at substantially larger p (dense
Cholesky cost scales as p³, so another order of magnitude in p is roughly
another 3 orders of magnitude in native TMB cost) — that regime was not
probed here and is not claimed.

## What this establishes

**Outcome: both engines finish and agree.** p=1000 and p=3000 both reach
`PARITY_PASS` (coefficients agree to 1e-5–1e-8, logLik to ~1e-9, well inside
the 1e-4 tolerance; fixed-effect SE agree to <0.2% relative). This is real
same-target evidence at an order of magnitude beyond the row's prior p=300
ceiling, and it is a genuine **parity** result — both the native TMB
comparator and DRM.jl actually ran and agreed, not a DRM.jl-only asymmetry.
The row's `claim_boundary` ("large-p phylogenetic random-intercept route")
now has evidence at p=1000 and p=3000, not just p=300.

## What this does NOT establish

No coverage claim, no promotion — `phylo_count_large_p` stays `experimental`
in drmTMB's own registry; this banks additional same-target measurement only.
The cost-asymmetry risk this slice was designed to probe (dense TMB O(p³) vs
DRM.jl sparse) did not materialize by p=3000 — both engines stayed fast
(TMB 1.61s, Julia's fit-only cost not isolated from startup). That is a
finding about *this* range, not a claim that the asymmetry never appears;
p=3000 is still two orders of magnitude below the p=10,000 DRM.jl-only O(p)
claim in `CLAUDE.md`, and no native TMB comparator was attempted anywhere
near that scale here. NB2 was not re-measured at p=1000/3000 (only Poisson).
