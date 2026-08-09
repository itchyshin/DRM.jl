# Plan vs actual — #136 Rung 1 public `marginal=:VA` (Melissa)

| Axis | Planned | Actual | Tag |
|---|---|---|---|
| Keyword | same `marginal=:VA` as Arc 0 | same; shared `_reject_method_as_marginal` | — |
| Scope | Binomial / NB2 / Gamma / Beta `(1\|g)` public path | all four shipped; none skipped | — |
| Kernels | reuse `_fit_*_ranef_va`; no rewrite | dispatch-only; variational kernels byte-stable | — |
| Rejects | `_va_reject` for unsupported combos | FE / crossed / corr / phylo / `sigma ~ x` / zi / locscale | — |
| Mixed IC | already on Poisson; don’t duplicate | not duplicated | — |
| Docs | Experimental Poisson **+ these four**, not everywhere | capabilities + guide + NEWS | — |
| Tests | `test_va_frontend_*.jl`; local subset | 89 + Poisson 43 + kernels + LA smoke | — |
| Fence | no close #136 / no 136e / no ZI-public / no merge | held | — |
| Merge | OPEN GATE | PR open, not merged | — |
