# After-task: #202 non-Gaussian phylo location–scale closeout

Date: 2026-08-05 · closes #202

Perspectives: Shannon · Ada · Noether · Rose. No nested subagents.

## Summary

Closed #202 as a **public closeout**, not a kernel rewrite. Tip already had
`src/locscale_*.jl` + private Gamma recovery (#253). Gap was `tree=` forward
from family `drm()`, public NB2 recovery evidence, capability/tutorial honesty,
and ledger disposition under G0 grammar **B**.

## What landed

- S1: forward `tree`/`K`/`A`/`coords` in `src/negbinomial.jl` + `src/gamma.jl`;
  stale “waits on #209” comment fixed in `src/locscale_frontend.jl`
- Public gate: `test/test_public_phylo_locscale.jl` (in `test/runtests.jl`)
  - NB2 grammar B recovery (ψ = log σ draw convention)
  - Gamma public-route smoke
  - Dual `phylo(1|sp)` on both axes still throws (grammar A out of cohort)
- Docs: `docs/design/capability-status.md` row; tutorial note + example in
  `docs/src/tutorials/phylogenetic-models.md`; `NEWS.md` Unreleased
- Hygiene: `/.worktrees/` gitignored; accidental gitlinks never re-staged

## Verify (log)

```
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 julia --project=. test/test_public_phylo_locscale.jl
Test Summary:                               | Pass  Total   Time
public phylo location–scale (#202 closeout) |   13     13  54.2s
```

Root-cause note (S2): first fixture used `r = exp(ψ)` (pre-unification). Kernel
uses `r = exp(−2ψ)`; public≈private both collapsed. Fixed draw + locked seed 7.

## Not covered / deferred

- Grammar A dual-`phylo(1|sp)` alias (RETRACTED unless owner renames)
- R `nbinom2-locscale` fixture (D-94; drmTMB coupled `(1|p|·)` still skipped)
- q=4 core / other families’ phylo locscale public recovery
- Owner merge is L2 human gate

## Rose audit

| Check | Verdict |
|---|---|
| Claim = public grammar B + measured Julia recovery | **PASS** |
| Dual issue-text formula not claimed as shipped | **PASS** |
| No R nbinom2-locscale / no extrapolated drmTMB parity | **PASS** |
| capability-status + tutorial no longer say “#202 on ledger only” | **PASS** |
| No GPL vendoring; `.worktrees/` unstaged; D-111 OFF; no q=4 core | **PASS** |

*Shannon · Ada · Noether · Rose.*
