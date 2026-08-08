# Plan vs actual — #136 Arc 0 Poisson public `marginal=:VA` (Melissa)

| Axis | Planned | Actual | Tag |
|---|---|---|---|
| Keyword | `marginal=:VA` (default `:LA`); reject `method=:VA` | same | — |
| Scope | Poisson `(1\|g)` public path only | same | — |
| Kernels | reuse `_fit_poisson_ranef_va`; no rewrite | `variational.jl` + `_va_reject` only | — |
| DrmFit tag | `_withmarginal`; default LA 11-arg ctor | field `marginal::Symbol=:LA` threaded through `_with*` + 3 reconstructors | — |
| Mixed IC | error mixed LA/VA in lrtest/aic/aicc/bic | lrtest/anova mixed error; unary `aic`/`bic`/`aicc` error on VA (ELBO) | adaptive (stronger, honest) |
| Docs | Experimental Poisson RI; banner Planned; no close #136 | capabilities + guide | — |
| Tests | frontend file + runtests; local subset | 43+9+6+7+12 + LA smoke | — |
| Fence | no rungs 1–4 / 136e / 5-family / overnight-audit merge | held | — |
| Merge | OPEN GATE | PR open, not merged | — |
