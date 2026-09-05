# Check-log — parity catch-up, Wave 1 (recon + the D-139 gate)

**Date:** 2026-08-24 · **Platform:** Claude Code · **Branch:** `parity/se-axis`
**Issue:** #457 · **Base:** `origin/main` @ `6ee03fd`
**Read-only recon + one live pre-run test. No `src/` edits.**

## W1-A — parity ledger re-measured at CURRENT refs

The committed countdown (`docs/dev-log/evidence/2026-08-16-parity-ledger-countdown.md`)
was measured against drmTMB `9e42d2c94`. drmTMB `origin/main` has since advanced to
`fb8e6c1a5`, and DRM.jl main from `394b62d9` to `6ee03fd`. Re-measured rather than assumed:

```
python3 tools/parity_ledger.py --drmtmb "…/drmTMB" --ref origin/main
```

```
COUNTDOWN: 0 export gaps (17 raw, 17 accounted for) · 11 unsupported capability rows · 14 closed gates
CLOSURE: PASS — every one of 11 capability rows is supported or carries a written
         claim_boundary; all 14 closed gates carry evidence + review_due
```

**Delta vs 2026-08-16:** raw export count moved **18 → 17**; all still accounted for in
writing. The headline is unchanged and still true: **0 export gaps ≠ parity complete.**
The 11 capability rows remain the frontier, and the ledger stays CLOSED at the newer ref.

**Fixture staleness inventory:** 11 of 12 canonical fixtures carry
`drmtmb_version = "0.6.0"` in `expected.meta.toml`, while the **installed** package is
**0.7.0**. (`xfam-external-gllvm` carries `gllvm_version` instead and is skipped by both
runners.) This is what W2-B re-measures.

## W1-B — D-139 pre-run test: is the live R↔Julia bridge real on this machine?

A hard gate, run before committing any batch. Had it failed, Waves 2–3 could not run and
the campaign degraded to Route-1 (committed-fixture) work only.

Toolchain: R 4.6.0 · drmTMB **0.7.0** (installed) · Julia 1.10.0 · JuliaCall present.

Same target fitted twice through drmTMB, `engine = "tmb"` vs `engine = "julia"`,
`bf(y ~ x, sigma ~ 1)`, gaussian, n = 60, seed 1:

```
tmb    logLik: -79.19668
julia  logLik: -79.19668
SMOKE_COEF_DIFF: 2.145468e-08
SMOKE_DONE
```

**VERDICT: GREEN.** The bridge fits the same target and agrees to 2.1e-08. Waves 2–3
authorised.

## Fences held (standing, re-checked mid-Wave-2)

| gate | check | result |
|---|---|---|
| GF1 | both same-target tests still assert `interval_status != "coverage_claimed"` | **intact** (`test_parity_gaussian_phylo_mean.jl:77`, `test_parity_biv_q4_phylo_reml.jl:72`) |
| GF2 | drmTMB working tree unchanged by this arc | **unchanged** — dirty-set hash `0c763689…` identical to baseline |
| GF3 | no speed/accuracy claim outside a dated evidence doc | **interim pass** — one grep hit, and it is a *disclaimer* in `compare.jl` |

**Note on GF2's oracle.** drmTMB is **not clean at baseline**: it carries 102 pre-existing
uncommitted files on branch `claude/handover-freshness-0718` (mtimes 2026-08-10..08-19)
from a prior lane. So "0 dirty files" would have been the wrong oracle and would have
failed for reasons unrelated to this arc. The gate pins the **baseline dirty-set hash**
instead, and fails if this arc adds, removes, or alters any entry. That prior lane's
unlanded state is flagged for the owner and is **not** touched here — drmTMB is in CRAN
prepare-only quiesce.

## Method note — a collision refused before dispatch

W2-B (Route-2 refresh) and W2-D (phylo_gamma diagnosis) were both scoped to write
`docs/dev-log/evidence/parity-phylo-nongaussian.tsv`. Two concurrent writers on one
append-only evidence file is a race, not a decomposition. **The plan was changed rather
than the claim bypassed:** W2-D was re-scoped to scratch-only output and W2-B retains sole
ownership of the TSV.

## Method note — why benchmark timings were deliberately deferred

Six agents run concurrent R + Julia sessions in this tree. Any wall-clock number measured
under that load is contaminated. Both performance slices were therefore split: the
**correctness** half (interval agreement, convergence, logLik equality) is load-independent
and runs now; the **authoritative timing** half waits for a quiet machine and must record a
load check (`ps ax | grep -c "[R]script"`, `uptime`) in its evidence doc. Publishing a
contaminated benchmark would be worse than publishing none.
