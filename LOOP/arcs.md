# Arcs — #166 beta-binomial phylo/crossed RE route

| Arc | Status | Gate | Deliverable |
|---|---|---|---|
| 0 Design | PENDING | none | kernel design note (shifted-argument digamma/trigamma math) |
| 1 Kernel (TDD) | PENDING | FD-gradient unit test green | `_laplace_v123(::Val{:betabinomial_fixed})` + nuisance variant |
| 2 Fitters+routing | PENDING | none | `_fit_betabinomial_phylo_laplace` / `_fit_betabinomial_crossed_laplace` + `drm()` dispatch |
| 3 Tests | PENDING | recovery + FD ≤1e-6 both routes | `test_betabinomial_phylo_laplace.jl`, `test_betabinomial_crossed_laplace.jl` |
| 4 Close | PENDING | PR merge | docs, DoD, Rose, PR closes #166 |
