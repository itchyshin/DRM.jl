GOAL: see GOAL.md.   STATE: A3c-2 + A3c-3 done. A3c-3 found a REAL DRM.jl NB2 bug (not fixed).

ARCS DONE (verified):
- A-fix — biv_student tolerance. Reproduced the CI failure on Julia 1.12 (|dev| 0.5198 vs atol
  0.25), fixed, 4 suites green on 1.12 AND 1.10. On #410 (auto-merge armed).
- LANE REPAIR — lane was cut from main @ 3638ba28, predating A3a/A3b/A3c-1 + QuadGK. Rebased onto
  docs/a3c-design. Verified by artefact (4 src files present, QuadGK in deps+compat, 3 suites pass).
- A3c-2 (23eb10af) — all four remaining pair classes. DESIGN CORRECTION: gaussian_nbinom2 is
  CLOSED FORM, so only THREE classes need quadrature, not four. 5-seed study n=2000 gave means
  0.539-0.547 vs true 0.55. integration_diagnostics() retains per-row QuadGK abs_error.
- A3c-3 (a5c56807) — tools/parity_associate.R + a convergence guard. SEE BELOW.

*** A3c-3 FINDING — a real DRM.jl bug, NOT fixed, needs its own arc ***
  Parity vs drmTMB 0.7.0: gaussian_bernoulli 2.7e-08 PASS, bernoulli_bernoulli 1.9e-08 PASS.
  All THREE NB2 classes FAIL (DRM.jl ~0.42 vs drmTMB ~0.58).
  Root cause is NOT the association code. Verified in order:
    - my NB2 latent endpoints match drmTMB's to 5e-6
    - the likelihood with TRUE margins peaks exactly at the true eta
    - DRM.jl's NB2 MARGIN FIT does not converge: coef [1.421, -0.1894, -14.4011],
      converged=FALSE, sigma-hat 5.6e-7 (dispersion collapsed to the Poisson boundary),
      logLik -3200.76 vs drmTMB -2909.55 on data with mean 4.235 / var 10.857.
  => `src/negbinomial.jl` fails to converge on legitimately overdispersed data. The
     fe_nbinom2 parity cell still PASSES on rnbinom-drawn data, so this is DATA-DEPENDENT
     fragility -- which is why one passing fixture never caught it.
  I FIXED only the part that was mine: associate_pairs froze a non-converged margin without
  checking. _assoc_require_converged now refuses it.
  NOT CLAIMED: the three NB2 pair classes are NOT parity-verified.

ARC IN PROGRESS: none.
NEXT: **A-nb2** (NEW, propose adding to arcs.md) — diagnose and fix the NB2 margin
  non-convergence. It BLOCKS parity for three staged classes and may affect other NB2 results.
  Suggested first step: compare DRM.jl vs drmTMB NB2 fits across a grid of dispersion/mean
  levels to map where DRM.jl's optimiser fails, before touching the fitter.
  Then: A-sigma (GATE), A-drmtmb (GATE), A4a-A4d.

OPEN GATES (need human):
- **A-sigma** — surface the sigma() public-contract design BEFORE landing.
- **A-drmtmb** — open the PR, NEVER merge (9 live lanes + release slice #959 there).
- **A-nb2 is new scope** — it was not in the approved G0 arc list. It is a genuine defect
  found by an in-fence arc, but adding an arc is a plan change: surface before doing it.

BRANCH/PR STATE:
- #410 `docs/a3-rescope-bivariate-nongaussian` — auto-merge ARMED, CI running, NOT merged.
- #412 `docs/a3c-design` — A3c design + A3c-1 + QuadGK + 0.7.0 anchor. NO auto-merge (base
  not clean until #410 lands).
- `claude/lane-catchup` — pushed; carries A3c-2 + A3c-3. No PR yet (stacked under #412).

TRUTH LIVES IN:
- Lane: /Users/z3437171/local-scratch/lanes/DRM.jl-catchup on claude/lane-catchup
- Findings: docs/dev-log/evidence/2026-08-15-a3c3-nb2-margin-nonconvergence.md
- Measured table: docs/dev-log/evidence/parity-associate.tsv
- Anchor: drmTMB 0.7.0 INSTALLED; Julia 1.12 installed (`julia +1.12`).

RESUME:
You are the DRM.jl catch-up lane. This is a RESUME.
READ FIRST, IN ORDER: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/arcs.md -> ./AGENTS.md.
WORKSPACE: /Users/z3437171/local-scratch/lanes/DRM.jl-catchup (reattach; do NOT recreate).
Run the L2 arc-loop: re-read GOAL each arc; verify by LOG and artefact, never exit code;
one branch per arc; auto-merge armed only as the LAST action on a branch; pause at every OPEN GATE.
CONTINUE FROM: surface A-nb2 as new scope, then A-sigma (GATE) / A-drmtmb (GATE) / A4a.
