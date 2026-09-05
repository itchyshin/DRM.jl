## Summary

- DRM-native **1-D Liu–Pierce AGHQ** around existing `_gauss_hermite` (`src/aghq_1d.jl`).
- Opt-in `marginal = :AGHQ`, `nAGQ = 5` on Poisson `(1 | g)` only. Default `:LA` stays today's **GHQ-32**.
- k=1 ≡ 1-point Laplace is **plumbing**, not a quadrature or recovery headline. Capability row stays **missing**.
- Fail-loud on phylo / crossed / relmat / `(1 + x | g)` / associate_pairs QuadGK / other families / `:REML` × `:AGHQ`.
- Does **not** edit `_fit_poisson_general_laplace`. No q4. No GPL vendoring. No GLLVM Λ headlines.
- Cite −7.3 / −5.0 / −0.9 as **drmTMB's** only.

closes #448

## Test plan

- [x] TDD: `test/test_aghq_1d.jl` failed first (`UndefVarError`), then 9/9 kernel + 37/37 surface
- [x] Kernel smoke (true θ): nll AGHQ k=5 = 73.05425078766923 vs GHQ-32 = 73.05027860681251 (absdiff 0.00397) — agreement, not recovery
- [x] Fitted smoke: loglik −100.80748354012172 vs −100.80728676421757 (absdiff 1.97e-4); `:LA` ≡ omit keyword
- [x] `pathof(DRM)` = this worktree
- [ ] Maintainer / Noether review of `src/` + public `marginal` — **do not merge from the loop**

## DoD (AGENTS.md)

- [x] Implementation wired
- [x] Tests in `test/runtests.jl`
- [x] Docstrings + worked example (Poisson)
- [x] `docs/dev-log/check-log.d/2026-08-18-aghq-lever-2.md`
- [x] `docs/dev-log/after-task/2026-08-18-aghq-lever-2.md`
- [x] Rose claim-vs-evidence (no false recovery)

## Mechanical verify (S7)

- [x] Issue #448 exists
- [x] Worktree ≠ `handover/2026-08-18-cursor`
- [x] No `_fit_poisson_general_laplace` hunk
- [x] No `reml_q4.jl` / q4 edit
- [x] Capability row still `missing`
- [x] No GLLVM `LOOP/GOAL.md`
- [x] No #420 / #406 steal
- [x] Tests actually ran (LOG read, not exit code)

## Fences

ML default. No `:REML`×`:AGHQ`. QuadGK / VA-12 / `(1+x|g)` 12² are **not** AGHQ.
