GOAL: see GOAL.md.   STATE: A-fix, A3c-2, A3c-3, A-nb2, A-sigma, A-drmtmb, A4-design ALL DONE. Next = A4c.

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

=== SESSION 2 (2026-08-15) ===
- A-nb2 (161e28fb) FIXED the bug A3c-3 found. The MoM initialiser computed NB2 SIZE r but seeded
  eta_sigma = log(sigma), where r = exp(-2*eta_sigma): the -0.5 conversion was MISSING at 6 sites.
  It seeded sigma 2.71 (size 0.136) where truth was size ~2.8. It survived because LBFGS recovered
  on most data -- only a CROSS-IMPLEMENTATION comparison exposed it. After: staged parity 5/5 PASS
  (was 2/5), main fixture 7/7, 13 NB2 suites pass. Guarded by test/test_nb2_dispersion_seed.jl.
- A-sigma (6b7caf6c) GATE DISSOLVED -- no API change needed. tau and V_known are recoverable
  EXACTLY (1.1e-16) from what the fit already stores. Bridge emits the meta sigma dpar as tau plus
  V_known; sigma() untouched. Boundary: returns nothing when the sigma block carries predictors.
- A-drmtmb: drmTMB PR #1032 OPEN, NOT MERGED (gate held). Evidence citations only, NO status
  changed. All THREE copies updated together (R fn + both TSVs) since test-julia-gate-vs-engine.R
  asserts they match. 140 checks pass locally. Isolated worktree; shared checkout untouched.
- A4 DESIGN PASS (0f0aa213) re-scoped 3 of 4 clusters -- see docs/dev-log/design/2026-08-15-a4-rescope.md.

UPSTREAM: DRM.jl #410 MERGED. #412 was BEHIND main and its test (1) failed because
docs/a3c-design predated A-fix; merged main in, auto-merge now ARMED. drmTMB #1032 OPEN (do not merge).

NEXT: A4c (drm_phylo_penalty, ~1 d) -> A4d-1 (corpair marker; grammar rail) -> A4d-2.

NEW OWNER GATES from the A4 design pass:
- A4a: confirm `categorical` moves to #49 PARKED rather than being built as a response family.
- A4b: confirm `make_mesh`/`spatial_coords` are deliberately-not-ported (R-side geospatial prep).
- MEASUREMENT: the ledger's 22-gap count MIXES missing capability with things that correctly live
  in R. Recommend a `deliberately-not-ported` class in tools/parity_ledger.py so the countdown
  measures what it claims.

=== OWNER DECISIONS 2026-08-15 (both settled — no longer gates) ===
- A4a -> #49 PARKED. `categorical` is an imputation family; NOT built as a response family.
- A4b -> deliberately-not-ported. make_mesh/spatial_coords are R-side geospatial prep.
Remaining arcs: A4c (drm_phylo_penalty, ~1 d, NOT STARTED) -> A4d-1 (corpair marker; grammar
rail) -> A4d-2 (profile_targets, structured_effects, meta_vcov_bivariate).

=== SAFE-TO-LEAVE STATE (as of this checkpoint) ===
Everything is committed and PUSHED. Nothing exists only on local disk.
- DRM.jl #412: OPEN, auto-merge ARMED; docs + test (1.10) PASS, test (1) still running.
  It merges ITSELF when green. No action needed.
- `claude/lane-catchup`: pushed, NO PR YET (stacked under #412). ONE ACTION OWED LATER:
  open its PR with base `main` AFTER #412 merges. Until then the handover and A3c-2/A3c-3/
  A-nb2/A-sigma/A4-design are reachable only from the lane branch, not from main.
- drmTMB #1032: OPEN and must STAY open until the owner decides timing. NEVER merge.
- A4c is NOT started -- deliberately not begun rather than left mid-flight.

=== A4c DONE 2026-08-15 (branch feat/a4c-phylo-penalty, cut from the lane tip) ===
`src/phylo_penalty.jl` — drm_phylo_penalty() + drm_phylo_penalty_sweep(), wired into the
objective AND the analytic gradient of all four phylo blocks (mean-only sparse, asymmetric,
separate, coupled). New `penalty=` kwarg on drm(); `:MAP` estimator tag; phylo_penalty/penalty
fields on DrmFit (via a 19-arg compat constructor, so none of the ~70 existing call sites moved).
PARITY 3/3 PASS vs native drmTMB 0.7.0 (ML baseline 9.66e-09, sd_u=0.5 7.46e-07, sd_u=0.25
9.06e-08; tol 1e-4). test_phylo_penalty.jl = 73 assertions, all pass.

TWO DECISIONS worth not re-litigating:
 (1) `cor_sd` penalises atanh(cor) recovered from the Cholesky, NOT L21 itself. Penalising L21
     would be a DIFFERENT PRIOR wearing drmTMB's name. Chain rule is closed form
     (dz/dL21 = 1/r, dz/dlogL22 = -L21/r) so the analytic gradients survive; FD-verified 1e-9.
 (2) The penalty value lives in a REAL DrmFit field, not a `scales` key. A scales key would have
     re-broken sigma() exactly as A-sigma documented (gaussian_core.jl:975).

TWO FINDINGS (evidence: docs/dev-log/evidence/2026-08-15-a4c-phylo-penalty-parity.md):
 (1) TREE SCALE. drmTMB standardises via ape::vcv(tree, corr=TRUE); DRM.jl uses the branch
     lengths as given. sd_drmTMB = sd_DRM * sqrt(tree height) — so the SAME sd_u is a DIFFERENT
     prior unless the tree has unit height. Documented + warned in the docstring. The unpenalized
     ML baseline cell is what caught it; without that cell it would have been debugged as a
     penalty bug in the wrong file.
 (2) UPSTREAM DEFECT IN drmTMB. It reads the penalty from fit$obj$report() with NO argument, so
     TMB reports at last.par — a finite-difference perturbation 1e-3 off the optimum. Since
     logLik <- -opt$objective + phylo_penalty, EVERY penalized drmTMB fit reports a slightly
     wrong penalty and logLik (0.0033 at sd_u=0.5, 0.0094 at sd_u=0.25). DRM.jl matches drmTMB's
     documented formula to 15 digits; the R value is the outlier. FILED, NOT PATCHED —
     R/drmTMB.R is outside the narrow lane and #1032 must not be merged. OWNER DECISION.

ALSO FOUND, PRE-EXISTING, NOT FIXED: check_drm throws on any fit whose vcov contains NaN — the
normal state of the mean-only sparse phylo route. Reproduces on a plain ML fit on main.

NEXT: A4d-1 (corpair marker — grammar, so DRM_PARITY_TESTS=1 is MANDATORY and its output must be
attached to the PR) -> A4d-2 -> A4e (parity_ledger deliberately-not-ported class; the 22-gap
count decomposes as 9 already-implemented + 7 parked/not-ported + 6 genuinely owed).

=== A4d DONE 2026-08-15 (same branch feat/a4c-phylo-penalty) ===
BUILT: src/introspection.jl — profile_targets(fit; ready_only) + structured_effects(fit).
21 assertions. profile_targets mirrors profile_result's dispatch BRANCH FOR BRANCH so
`profile_ready` tracks what the profiler actually does; pinned on 3 routes that differ
(fixed-effect locscale ready; sigma-phylo NOT ready and profile_result really does throw;
sigma-phylo + profile_ci=true flips ONLY the SD blocks). A readiness column that always says
"ready" is worse than none — it turns a clear error into a broken promise.

REFUSED, both with written claim_boundary — this is the RESULT, not a shortfall:
 (1) A4d-1 `corpair` BLOCKED on two independent grounds. StatsModels' @formula rejects BOTH
     keyword args (`ArgumentError: non-call expression encountered: Expr(:kw, ...)`) AND string
     literals (`MethodError: no method matching parse!(::String, ::Bool)`) at MACRO-EXPANSION
     time — so drmTMB's syntax is not expressible, the paste-and-run contract cannot be met,
     and DRM.jl cannot even intercept the paste to give a better error. Second blocker: the
     fitted drmTMB route needs the labelled covariance-block grammar (1|p|id), absent here.
     Lifting it = an owner decision on a @drmformula macro, i.e. a front-end slice.
 (2) `meta_vcov_bivariate` BLOCKED. meta_V is DIAGONAL-ONLY (gaussian_meta.jl:16 says so) and
     the bivariate route ignores metav entirely, so the port would export a constructor whose
     output nothing can consume — the exact export-name-without-capability antipattern A4e exists
     to fix.

DOC BUG, real, not fixed here: docs/src/rosetta.md:117 maps corpair(fit) -> corpairs(fit),
implying corpair is an accessor. It is a marker.

NEXT: A4e (parity_ledger deliberately-not-ported class + name-alias map; the 22-gap headline
decomposes as 9 already-implemented + 7 parked/not-ported + 6 genuinely owed, of which A4c
closed 2 and A4d closed 2 more and blocked 2).

=== A4e + check_drm fix DONE 2026-08-15 ===
A4e: tools/parity_ledger.py gained DELIBERATELY_NOT_PORTED, every entry carrying a WRITTEN REASON,
and the countdown now splits "genuinely owed" from "accounted for in writing".
COUNTDOWN: 0 export gaps (18 raw, 18 accounted for), down from a 22 headline.
CORRECTION recorded there: an earlier claim that 9 names were "already implemented in src/ under
other export names" was right in COUNT and wrong in REASON — the evidence was a text grep matching
STRING LITERALS AND COMMENTS, not definitions. None of the nine is a Julia symbol. True split:
3 delivered under a different spelling (family + bivariate formula), 5 R post-fit functions fed by
the bridge payload (A2a's one-contract finding), 1 a struct field, 5 PARKED (#49), 2 R-side prep,
2 blocked structurally, 4 built by A4c/A4d.
NOT a capability claim: 11 capability rows remain un-`supported`, and that bar still needs a
native-vs-Julia comparison per GOAL.md.

check_drm partial-vcov fix (owner-named arc): check_drm crashed on any NaN-containing vcov — the
NORMAL state of the sparse phylo route. Now reports `vcov_complete=false` instead of raising.
Rose sweep for the same class came back NEGATIVE and is recorded as such: location_only.jl:701 is
already try/caught, gaussian_ranef.jl:397 already guards on isfinite, the coevolution/bivariate
isposdef calls validate user input and SHOULD throw, and 8 other post-fit accessors were verified
fine on such a fit. Isolated instance.

PR STACK (each retargets as the one below merges):
  #414 A4c  -> main                      auto-merge ARMED, test(1.10) PASS, test(1) pending
  #415 A4d  -> feat/a4c-phylo-penalty    CLEAN
  #416 A4e  -> feat/a4d-introspection    CLEAN
  #417 check_drm -> feat/a4e-ledger-honesty
OPEN GATES (need human, loop is STOPPED at these):
  (1) drmTMB PR timing — #1032 OPEN and must NEVER be merged from this lane.
  (2) A2b (result-shape contract, R side) is BLOCKED on that same gate.
  (3) A-tag release boundary — owner only.
  (4) NEW: the drmTMB `obj$report()` off-optimum defect (A4c finding) — patch upstream or not?
  (5) NEW: `corpair` — lift the block with a @drmformula macro (front-end slice), or leave blocked?

=== UPSTREAM drmTMB FIX 2026-08-15 (owner-named; narrow-lane fence lifted for this) ===
FILED: drmTMB issue #1036 (bare obj$report() read at last.par, not the optimum).
FIXED: drmTMB PR #1038, branch claude/fix-report-at-optimum, base main.
  - R/drmTMB.R: re-pin from `tmb_state` (captured at :621, BEFORE sdreport) before the report.
    Chosen over obj$env$last.par.best because it does not assume last.par.best survives sdreport.
    Same idiom profile.R already uses at 3 sites.
  - R/check.R: same defect in check_logsigma_clamp_active (post-hoc, never re-pinned). Fixed.
  - NOT changed: drm_warn_if_clamp_active (R/drmTMB.R:2928) is a bare report but runs BEFORE
    sdreport, so it is correct today — safe by ordering, not by construction. Out of scope, noted.
  - Tests: the old assertion built its "expected" penalty from the SAME bare report(), so both
    sides moved together — it could never fail. Now derives log_sd from parList(opt$par), tol 1e-8.
    New test: `se` must not move phylo_penalty or logLik.
VERIFIED with a purpose-built temp library (installed drmTMB 0.7.0 left UNTOUCHED so the DRM.jl
parity fixtures still work): penalty error 5.077e-04 -> 0.000e+00; se=TRUE == se=FALSE exactly;
325 pass / 0 fail / 0 error / 0 skip across the 5 affected test files.
One "error" seen en route was a HARNESS ARTIFACT of bare test_file() + library() calling an
INTERNAL function unqualified — vanished when run in the package namespace. Not a regression.

** GATE HELD: PR #1038 is OPEN and NOT merged, auto-merge OFF. ** GOAL.md makes drmTMB a STOP
GATE (9 live lanes + release slice #959) and the owner lifted only the narrow-lane fence, not the
merge gate. #1032 also still open and unmerged.
WORKTREE (declared, not deleted): scratchpad/drmtmb-fix on claude/fix-report-at-optimum, pushed.
NOT RUN: full R CMD check on drmTMB — flagged in the PR as worth doing before merge.
