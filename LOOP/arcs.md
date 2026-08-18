# Arcs — AGHQ lever 2 (from approved ultra-plan)

Sequential: S0 → S1 → S2 → S3 → S4 → S5 → S6 → S7 → S8 → S9.
Fan-out: recon only (S1 recon already ran in planning). One builder at a time on `src/`.

| # | arc | owner | status | gate? |
|---|-----|--------|--------|-------|
| S0 | Open ONE GitHub issue (#448); `lane_launch.sh` off origin/main; commit LOOP/ kit | Shannon | done | — |
| S1 | `src/aghq_1d.jl`: Liu–Pierce 1-D wrap of `_gauss_hermite`; k=1 ≡ Laplace; fail-loud dim≠1. Do not vendor GLLVM `aghq_grid.jl` | Noether | todo | OPEN: `src/` = Noether+maintainer (land on branch; merge later) |
| S2 | TDD: `test/test_aghq_1d.jl` first (red), then kernel. Smoke: k≈5 nll vs GHQ-32 — agreement, not recovery | Noether | todo | — |
| S3 | Thread `marginal=:AGHQ` + `nAGQ=5` through `_marginal_method` + Poisson `(1|g)`. Default `:LA` unchanged. Fail-loud phylo / crossed / relmat / `(1+x|g)` / associate_pairs. Do not edit `_fit_poisson_general_laplace`. No `:REML`×`:AGHQ` | Noether | todo | OPEN: public `marginal` = Noether+maintainer |
| S4 | Mac-local `Pkg.test` for new file + Poisson AGHQ smoke. Log the numbers. No Totoro. No Cell D | Curie/Noether | todo | — |
| S5 | Docstrings + worked example. Capability row stays missing. check-log.d + after-task + Rose claim-vs-evidence (no −7.3/−5.0 as DRM, no GLLVM 1.0021, no chip flip) | Pat + Rose | todo | — |
| S6 | One PR `closes #NN` from this worktree. DoD. Do not merge | Shannon | todo | OPEN: PR merge = human |
| S7 | MECHANICAL-VERIFY: issue exists; worktree ≠ handover branch; no phylo-Laplace REML hunk; no q4; no chip flip; no GLLVM LOOP; no #420/#406; tests actually ran (read the log) | scout | todo | — |
| S8 | REVIEW: Rose + Noether plan + PR claim audit (skip Other Models if bar exhausted; Rose note in after-task) | Rose + Noether | todo | — |
| S9 | RECONCILE: `docs/dev-log/plan-actual/2026-08-18-aghq-lever-2.md` | Melissa | todo | — |

Status: todo / doing / done / blocked. Gate = needs a human before it can proceed.

## Q1/Q2 (G0 defaults — IF YOU DO NOT MIND)

- Q1: Poisson `(1|g)` 1-D AGHQ (not `_fit_poisson_general_laplace`)
- Q2: public `marginal=:AGHQ` on Poisson `(1|g)` only; chip stays missing
