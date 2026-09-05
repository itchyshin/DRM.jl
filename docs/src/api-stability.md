# API stability

*The stability promise of the v0.7 line, stated precisely. Machine-checked by `test/test_api_stability.jl`, which
classifies **every** exported name into exactly one tier and fails if a new export appears
unclassified, a stable name vanishes, or a tier changes without a reviewed edit.*

## The promise

*(Versioning twin-tracks drmTMB — D-181: the version communicates parity level with the R twin,
so the twin-complete release is `v0.7.0`, **registration in Julia General is planned at
`v0.7.1`** mirroring the twin's own sequence (D-181), and a formal SemVer `1.0` happens together
with the twin. Julia's 0.x convention allows minor-version breakage; this page plus the test gate are the
promise that we will not use that allowance on the Stable tier.)*

From `v0.7.0`, names in the **Stable** tier — the `bf()`/`drm()` grammar, the fourteen family
constructors, the structured-effect markers, and the accessor/inference/plotting surface — keep
their names, meanings, and conventions across the `0.7.x` line and beyond. The conventions are drmTMB's: scale is
**`sigma`** (never `tau`), the bivariate residual correlation is **`rho12`**, meta-analysis is
`gaussian()` + **`meta_V`**. Breaking any of these is a co-versioned major event decided with the twin, never a quiet 0.x bump.

## The three tiers

**Stable** — the promise above. The authoritative list is the `API_STABLE` vector in
`test/test_api_stability.jl`; the gate keeps this page and the code from drifting apart.

**Experimental — exported, usable, exempt.** These work today and are tested, but their shape may
change between releases, and each carries its reason:

- the **R bridge** (`drm_bridge`, `drm_bridge_inference`, `drm_listwise`) — the R↔Julia capability
  ledger holds `r_bridge_status = experimental`, and the bridge's shape follows that ledger;
- the **cross-family surface** (`mf_*`, `associate_pairs`, `latent_normal`, `association`,
  `PairAssociation`, `integration_diagnostics`) — its ledger row carries a permanent owner-signed
  claim boundary (D-179 #3);
- the **penalized-MAP surface** (`drm_phylo_penalty*`, `PhyloPenalty`,
  `PhyloCorPenaltyNeedsTwoSD`) and **bivariate meta** (`meta_vcov_bivariate`) — newer surfaces
  whose ergonomics are still settling;
- the **VA/ELBO marginal** (`marginal = :VA`, #136) — reachable through stable `drm()` but
  Experimental-labelled on its own pages; its behaviour and coverage may change between releases;
- the **prepared joint missing-predictor surface** (`PreparedJointModel`,
  `prepared_joint_model`, `fit_prepared_joint`, `mi`, and related result and
  summary types) — implemented and tested, while formula and bridge ergonomics
  continue to settle.

**Engine** — the computational spine (`AugProblem`, `make_problem`, `fit_q4_sparse_tmb`,
`estep_mode`, the `coevo_*` and `fz_*` families, tree utilities, packers). Exported so scripts,
benchmarks, and the dev-log's instruments can reach it; stable in practice but **not** part of the
promise, the same way a language's internals are not.

## What the promise does and does not cover

It covers names, argument meanings, and return conventions on the Stable tier. It does **not**
cover: numerical trajectories (an optimiser or tolerance improvement may move estimates within
documented accuracy), the Experimental and Engine tiers, or interval *coverage* — interval claims
throughout this package are **capability parity, not coverage**; the ledger's `coverage_claimed`
fences are permanent documented boundaries by owner decision (D-179 #4, D-180 #2).

## Deliberate exclusions at v0.7.0

- **Bivariate Student structured markers** (`phylo`/`relmat`/`animal`/`spatial` on
  `Student()` bivariate) are **outside** the frozen surface (D-180 #3, issue #471) — matching
  drmTMB, whose own `biv_student()` defers structured effects. Bivariate **LogNormal** structured
  markers are inside: they delegate to the exact/q4 Gaussian engines on `log(y)` and are tested.
- The prepared joint missing-predictor API is available as an Experimental
  post-v0.7 surface. Its inclusion here does not widen the Stable-tier promise.
