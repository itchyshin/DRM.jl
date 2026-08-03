GOAL: #166 beta-binomial phylo/crossed RE route — see LOOP/GOAL.md.
ARCS DONE (verified): Arc 0 — design note written
(docs/dev-log/plans/2026-08-02-166-betabinomial-kernel-design.md), full
shifted-digamma/trigamma/polygamma derivation for mean-axis (A_bb/B_bb/C_bb)
and nuisance-axis (dL/dA/dB) derivatives worked out by hand.
ARCS DONE (verified): Arc 1 — `:betabinomial_fixed` kernel written in
src/sparse_laplace_glmm.jl (value/d1/d2/d3/mean/obs/d12/v123 +
nuisance_value/d1/d2/v123_nuisance); verified against ForwardDiff (nested AD,
not naive central-FD which is numerically unstable past 1st order) to machine
precision (~1e-15) on both the η-axis (d1/d2/d3) and the φ mixed-partial axis
(nuisance value/d1/d2) — kernel algebra is correct. `_fit_betabinomial_phylo_
laplace` + `_fit_betabinomial_crossed_laplace` + `_betabinomial_laplace_setup`
added; `extra_scales` kwarg added to `_fit_phylo_mean_laplace_nuisance` /
`_fit_general_mean_laplace_nuisance` / `_fit_crossed_mean_laplace_nuisance` so
`:trials` reaches `scales` (needed by quantile_residuals.jl). `betabinomial.jl`
drm() now routes phylo(1|grp) and crossed (1|g)+(1|h), constant-sigma only.
ARCS DONE (verified): Arc 2/3 — test_betabinomial_phylo_laplace.jl (recovery +
public-API FD gradient + phylo/RE-combo and nonconstant-sigma error checks)
and test_betabinomial_crossed_laplace.jl (recovery + low-level FD≤1e-6 gate)
written and passing standalone; added "Beta-binomial phylo Laplace gradient
gate (#166): FD-vs-exact ≤ 1e-6" to the standing
test_nongaussian_phylo_grad_gate.jl — achieves 6.6e-8 (tighter than Beta's own
honest 1e-4, matches NB2/Gamma/Binomial's tight bar). Wired all 3 files into
test/runtests.jl. Standalone runs of all 3 files: all tests pass.
ARCS DONE (verified): Arc 3 (partial) — focused re-runs green: standalone
test_betabinomial_phylo_laplace.jl (9 pass), test_betabinomial_crossed_laplace.jl
(12 pass, gate 7.7e-8), test_nongaussian_phylo_grad_gate.jl (incl. new
beta-binomial gate 6.6e-8), and regression re-run of
test_betabinomial{,_re,_slope_re}.jl (16 pass, no regressions from the drm()
routing change). Full `julia --project=test test/runtests.jl` launched in
background (logs to /tmp/drm_test_run.log, buffered until exit — check before
push/PR).
ARCS DONE (verified): Arc 4 — docs/DoD: docstring already in betabinomial.jl;
docs/src/capabilities.md row updated; docs/src/tutorials/phylogenetic-models.md
gained a runnable BetaBinomial() phylo @example (recovers σ_phylo ≈0.32 vs
true 0.35, verified by direct Julia run); check-log.d entry
(2026-08-02-166-betabinomial-phylo-crossed-laplace.md) and after-task report
(docs/dev-log/after-task/2026-08-02-166-betabinomial-phylo-crossed-laplace.md,
incl. inline Rose-style claim-vs-evidence table) both written.
NEXT: confirm full Pkg.test() background run is green (check
/tmp/drm_test_run.log), then push branch + gh pr create closes #166; watch CI
per lesson from #367 (Documenter @ref); merge only if fully green + mergeable
CLEAN.
OPEN GATES: none (G0 already approved by Shinichi).
TRUTH LIVES IN: branch `codex/166-betabinomial-phylo-crossed` off `origin/main` @ 89e050a;
plan at `docs/dev-log/plans/2026-08-02-166-betabinomial-phylo-crossed-ultra-plan.md`.
RESUME: read AGENTS.md → LOOP/GOAL.md → this checkpoint → LOOP/ultra-plan.md; continue from NEXT.
