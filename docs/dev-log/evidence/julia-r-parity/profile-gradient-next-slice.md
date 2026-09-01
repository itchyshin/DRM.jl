# Proposed next slice — private exact gradients for sparse LSS profiling

## Decision

The generic profiler already accepts a stored full-objective gradient.  The
smallest candidate is therefore **not** a new profile optimizer or a change to
`src/inference.jl`: it is a narrowly reviewed ML-only attachment of the
existing exact sparse-LSS gradient to the fitted `DrmFit`.

This requires explicit authorization to edit the currently denied
`src/gaussian_sparse_lss.jl`.  There is no safe alternate-location workaround:
the closure that owns the exact sparse likelihood and its parameter unpacking
lives in that file.  This note authorizes no source edit.

## Existing mechanism

`_fit_phylo_gaussian_lss_sparse` defines `eval_core` in
`src/gaussian_sparse_lss.jl`.  With `want_grad=true`, it returns the exact ML
gradient using the selected inverse of the augmented sparse Cholesky factor.
The fitting `fg!` callback already uses that result.  The returned ML fit,
however, currently calls `_withnll(..., nll_ml_only)` without that gradient.

Generic profiling consequently sees `fit.nllgrad === nothing` and
`_profile_autodiff_mode` in `src/inference.jl` selects finite differences.
For the retained 15-parameter profile-cost fixtures, fixing one coordinate
leaves fourteen nuisances.  The receipts verify exactly
`2 * 14 + 1 = 29` objective calls for each finite-difference gradient request:

| tips | nuisance gradient requests | objective calls | constrained solve | status |
|---:|---:|---:|---:|:---|
| 64 | 143 | 4,148 | 0.546 s | converged |
| 128 | 2,007 | 58,204 | 4.672 s | converged |
| 256 | 2,743 | 79,548 | 11.115 s | not converged |

Those are historical diagnostic measurements, including fresh-process costs;
they do not predict the cost of an exact-gradient path or certify inference.

## Narrow implementation contract

If the file authorization is granted, define an ML `nllgrad!(g, theta)` beside
`nll_ml_only`.  It should call
`eval_core(unpack(theta)...; want_grad=true, use_ref=false)`, copy the returned
finite full gradient into `g`, and use the same finite-failure convention as
the fitted objective.  Attach it only through
`_withnll(..., nll_ml_only, nllgrad!)` for the ML return.

`use_ref=false` is a safety requirement.  The fitting callback uses the mutable
`chol_ref` cache with `use_ref=true`; the stored profile callback must instead
allocate a private Cholesky factor and its temporary arrays for every call.  The
proposal does **not** claim workspace reuse.  It relies only on read-only
captured design/precision data and must be tested for independent concurrent
calls before threaded profile use is claimed.

The route remains limited to the one-component sparse phylogenetic Gaussian
LSS ML fitter.  It excludes REML (whose `eval_reml` has no matching analytic
gradient), dense LSS, multi-component LSS, structured engines, and all changes
to generic profile optimizer defaults or fallback policy.

## Required tests and pilot

A new focused test should use the existing eight-tip sparse fixture and its
independent dense covariance likelihood to check:

1. the stored gradient at fixed non-optimal parameter vectors against an
   independent central finite difference;
2. selection of `:stored` for sparse ML, while sparse REML remains `:finite`;
3. two concurrent, distinct-theta gradient calls agreeing with serial results;
4. a bounded accepted nuisance solve using the stored route, without treating
   a timing result as an interval or coverage result.

Keep the historical finite-difference receipt checker unchanged.  A new,
versioned pilot/checker must separately record objective and gradient-callback
counts, constrained-solver status, resources, and independent dense-objective
agreement.  It must not call callback counts “NLL calls”.

The first execution should be only the 64-tip fixture, one Julia and one BLAS
thread, with a 120-second watchdog.  Estimated wall time is under two minutes
including startup, but no speed claim is warranted before that receipt exists.

## Source identity at diagnosis

Recorded on branch `codex/julia-r-parity`, base commit
`285ff5fd5443acbcfd1518381bd0b5ef62cb0707`.  The profile-status worktree was
dirty at observation, so these hashes identify bytes rather than a clean head:

| path | SHA-256 |
|---|---|
| `src/inference.jl` | `286fec89b7bc451c85778d545824a2e2e57ae073cb7305395c047864c3d239e7` |
| `src/gaussian_sparse_lss.jl` | `96ee90f88bc12af7e6eebd7f3f51fb285711cf8f9f9c2ed0a19953ca6b19de1f` |
| `src/gaussian_core.jl` | `2c4f2d38f1b8d1e4557583c9d1db6826681ac9696bf1b75b9330376e9e5f9d05` |
| `tools/profile-scaling-pilot.jl` | `da12bb525e0f30e67204fae65478054782cf2454f3d72472b12b852acbd6c03a` |
| `tools/check_profile_cost_receipt.py` | `b341471b00059dcddd92d4f50abf0063d719b09425f009e248f1b8a63158c2d8` |

No fit, benchmark, source change, or authorization bypass occurred while
producing this diagnosis.

## Profile-status reconciliation

The profile-status slice earned only its stated status-handling closure:
combined002 reported 212 assertions; docs001 executed 19 guide examples; the
final public004 analytical Gaussian ML transport receipt carried 15 injected
cases; and its checker rejected 12 damaged receipts while validating all 141
recorded current source hashes.  These verify accepted versus failed nuisance-arm
transport, plotting/status handling, and selected public diagnostics.  They do
not validate profile gradients, shared workspaces, interval coverage, native-R
profile parity, specialized location-only/location-scale profilers, or a
performance result.

Keep all programme G0–G8 and the strict raw-coefficient gate open.  In
particular, retain all 24 native missing-predictor cells and their strict losses;
stamped LSS SE/REML/masks/large-tree/final-head requirements; recovery and
coverage; full public accessor/output work; warm complete-workflow and 1/2/4/8
thread measurements; whole-site/deployment documentation; worktree cleanup and
final reconciliation.  The earlier bootstrap leaf remains bounded evidence, but
requires requalification against a future final source revision rather than
being erased or promoted to programme closure.
