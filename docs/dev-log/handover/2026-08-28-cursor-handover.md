# Handover → Cursor — DRM.jl "true parity + better" arc (2026-08-28)

**You are Cursor**, picking up the DRM.jl ↔ drmTMB parity program from a Claude Code session.
You inherit **no chat context**: this document plus the repo is the authoritative state.
**Author:** Claude Code (speaking as Shannon; no subagents running at handover).

---

## Critical context (read first, 60 seconds)

The mission is the Julia twin of drmTMB. **v0.7.0 shipped** (twin-tracked to drmTMB 0.7.0, pinned
at drmTMB commit `a6de6bb71`). Then the owner challenged the parity claim — correctly — because
**location–scale–scale was never a ledger row**, so the "closure" silently excluded it. That gap is
now closed and a follow-on arc is planned but **not started**.

The scientific driver is a real project: **Ayumi Mizuno's ecogeographical-rules registered report**
(`Ayumi-495/LS_ecogeographical-rules`), whose model ladder M2–M6q is exactly the
location–scale–scale class. She has been briefed and is expected to use `engine = "julia"` —
see her issue **#28** (posted by the owner 2026-08-28) for the user-facing contract you must not break.

---

## What was accomplished this session (all MERGED unless stated)

| PR | Repo | What |
|---|---|---|
| **#547** (carried #554) | DRM.jl | `sd(group)` / `sd(group, phylogenetic)` grammar (canonical; `sd_phylo` soft-deprecated) · exact-Woodbury iid engine (#544) · dense phylo engine (#545) · **multi-component lsss** engine (#555: several REs, each with its own SD submodel) · fixes #548/#549/#550/#556 · tutorials |
| **#553** | DRM.jl | ν back-transform: three pages taught `exp(coef(:nu))` where the link is **logm2** (`ν = 2 + exp η`) — readers under-reported ν by exactly 2 |
| **#1100** | drmTMB | bridge routing for `sd()` parts · `sigma ~ 1` phylo **fence lifted** · block-aware coefficient-name splitting · **capability ledger row 12** `location_scale_scale = partial` · setup-UX polish |
| **#557** | DRM.jl | lane-closing handover (**this PR** — see Landing State) |

**Four real bugs found and fixed** (each was measured, not inferred):
1. **#548** (shipped in v0.7.0): `phylo(1|g)` + `sigma ~ x` returned **logLik +1.1e105 with
   `converged = true`**; the true dense value at that θ was −1873 and drmTMB says −70.38. Woodbury
   cancellation as σ_e → 0. This was *exactly* Ayumi's M5/M6 shape and the reason drmTMB had fenced
   that combination off from Julia.
2. **#549**: a Julia scoping trap — a name assigned in **both** a closure and its enclosing function
   is ONE shared boxed variable; the stored `nll` closure raced under threaded profile. Swept the
   class: one more genuine instance (`cuts` in `cumulative.jl`), two false positives.
3. **#550**: concurrent Julia threads each invoking multi-threaded OpenBLAS contend on its locks.
   Threaded bootstrap was **1.9× SLOWER**; with BLAS pinned inside threaded regions it is
   **15× FASTER than serial** (0.31 s vs 4.77 s, B = 99).
4. **#556**: the sparse phylo route built its vcov as `fill(NaN, …)` with only the mean block
   populated — variance-parameter SEs were missing **by construction** on every Gaussian phylo-mean
   fit. Now from the profiled curvature; matches drmTMB to 5 digits.

**Owner acceptance gate MET** — all five Mizuno models via `engine = "julia"`: ΔlogLik = 0 vs TMB,
finite SEs, Wald + profile + bootstrap CIs. Evidence:
`docs/dev-log/evidence/2026-08-28-lss-acceptance-matrix.md` and
`docs/dev-log/evidence/2026-08-28-lss-mladder-cross-engine.md`.

---

## Landing State ledger

| item | state |
|---|---|
| `feat/544-lss-group`, `docs/552-nu-logm2-backtransform`, `docs/bivariate-nongaussian-tutorial` | **LANDED** (merged to main) |
| drmTMB `feat/546-julia-lss` | **LANDED** (#1100 merged) |
| `docs/handover-lss-arc` (PR #557, incl. this doc) | **CARRIED-OVER** — auto-merge armed, CI pending. Docs-only. Resume: nothing to do; confirm `gh pr view 557` is MERGED. |
| `worktree-agent-a7df907e709972cb2`, `worktree-agent-af2df784265dc24cf` (1 unpushed commit each) | **PRE-EXISTING / NOT MINE** — authored 3 months ago (Student-t and LogNormal `(1+x\|g)` GHQ work). Not touched this session; left as found. |
| `.codex/agents/shannon-coordinator.toml` (untracked) | **PROTECTED — never stage.** |

**FINDING-OF-RECORD:** the v0.7.0 parity closure under-admitted location–scale–scale (it was
never a ledger row), and closing it surfaced four measured engine bugs — #548 (a shipped
`converged=true` likelihood blow-up on Ayumi's own M5/M6 shape), #549 (Julia shared-boxed-variable
closure race), #550 (BLAS oversubscription: threaded bootstrap 1.9× slower → 15× faster once
pinned), #556 (variance-block SEs NaN by construction).
**vault-note:** [[AGENT_LOG]] entries `2026-08-28 (c)` (v0.7.0 tagged), `(d)` (the lss arc and its
four bugs), `(e)` (the Ayumi handoff), at `~/shinichi-brain/memory/AGENT_LOG.md`.

---

## Next Immediate Steps (OWED) — the "true parity + better" arc

The owner adopted this order on 2026-08-28. **Full plan with file:line anchors:**
`~/.claude/plans/partitioned-wishing-shell.md` (Claude-side path; the substance is reproduced below
so you are not dependent on it).

### 1. #558 — lss REML  ← START HERE
Ayumi fits mass/tarsus/beak by **REML**; DRM.jl's lss routes are ML-only, so those exact fits are
not reproducible via Julia.
- **Julia:** in `src/gaussian_lss.jl`, both dense fitters (`_fit_structured_gaussian_lss` ~:329,
  `_fit_gaussian_lss_multi` ~:405) already build `Vfac = cholesky(Symmetric(Vm))`. Add a second
  closure: `A = Vfac \ Xμ`; `XtVinvX = Xμ' * A` (**PSD by congruence — not a Woodbury subtraction,
  so the #499 hazard is weak here**); guard `issuccess(chX) || return nll_ml_θ + REML_NONPD_PENALTY`;
  return `nll_ml_θ + 0.5*logdet(chX) - 0.5*pμ*log(2π)` (**normalised** convention, #477).
- **Copy the pattern from `_fit_ranef_gaussian_lss` (`gaussian_lss.jl:115-234`)** — the iid lss route
  is *already* REML-capable. Store `_withnll(..., nll_ml)` so profile CIs stay on ML; then
  `_withreml(fit, -nll_reml(θ̂), -nll_ml(θ̂))`. vcov = FD Hessian of the **restricted** objective.
- **Lift the refusals in the same PR:** `gaussian_lss.jl:299-301` and `:490-491`, plus their pins
  `test/test_lss_phylo.jl:68` and `test/test_lsss_multi.jl:75-78`.
- **R side (the one real gate):** drmTMB `drm_julia_reml_supported()` is
  `gaussian && (no phylo || sigma-phylo)`, so a `sd(species, level="phylogenetic")` model has a phylo
  term *without* sigma-phylo and is **silently downgraded to ML with a warning**. Widen it once Julia
  lands. *(The dpar-admission gate is NOT a blocker — #1100 merged the `is_lss` widening; verified on
  drmTMB `origin/main`.)*
- **Verify:** mirror `test/test_reml_ordinary_ranef.jl`'s structure, add the defining-property test
  from `test_reml_q4_allaxes.jl` (each `exp(α̂)` SD ≥ its ML counterpart), and add cross-engine
  fixtures on **Ayumi's REML shapes**.
- ⚠ **Resolve while here:** `gaussian_core.jl:1839` claims every REML route reports the normalised
  form, but `_glsp_reml_penalty` (`gaussian_locscale_phylo.jl:91-106`) appears to omit `−½pμ log2π`.
  Confirm, then fix the route or correct the doc — #558 copies this convention.

### 2. #559 — lss missing responses
Unlocks Ayumi's **lightness** models. Same observed-rows argument as the #517 phylo-mean cell.
- **The one design decision, settled by precedent:** build `gidx`, `G`, and `Zg` from the **FULL**
  data (so `D_a` stays parameterised over all G levels), *then* subset `y/Xμ/Xσ/gidx` to observed
  rows. Deriving `Zg` from observed rows only would silently change the α design when a level's rows
  are all masked (and `_sd_group_design` fills `Zg = fill(NaN, G, q)`, so it would leave a NaN row).
- **Refusals to lift:** `gaussian_core.jl:469-471`, `gaussian_lss.jl:90-92`, `:294-296`.
  ⚠ `_drm_gaussian_lss_multi` **is not passed `has_missing_response` at all** — lifting the core gate
  without threading the flag would let the multi route silently produce NaNs.
- Copy the dof guard, saturated-fit warn, and the never-silent drop `@warn` (`gaussian_core.jl:648-653`,
  `:865-879`). The 5000-row caps (`gaussian_lss.jl:333`, `:409`) should then measure `n_obs`.
- **Verify:** mirror testset (4) of `test/test_gaussian_phylo_mean_missing_response.jl` — exact `==`
  on `loglik` **and** `theta` between `response="include"` and hand-dropped data, with one entirely
  masked species — plus a leak guard that the remaining refusals still name the right gate.

### 3. #551 — sparse O(p) lss engine (the headline; lifts the 5000-species cap)
**Recon changed the framing and made this much cheaper than the issue assumes.** The right base is
**`_fit_two_structured_gaussian_sparse_spec`** (`src/gaussian_structured.jl:424-574`), already an
**exact sparse Gaussian marginal** (no Laplace, no mode iteration, no IFT correction — `â = H⁻¹b`
*is* the conditional mean), which already has:
`diag(σ_e,i²)` heteroscedastic residual **wired** (`:460-461`, with its `∂NLL/∂βσ` derived at
`:492-501`) · a **per-observation weight slot** in `_sparse_incidence` (`:317`) that
`_phylo_aug_comp` (`:397-415`) already uses to fold `1/√v_leaf` into `wts[i]` · O(p) analytic
gradients via Takahashi selected inverse with symbolic-factorisation reuse (`:438-451`) · and a
two-component structure to generalise.
- **`D_a` enters as `wts[i] = exp(Zg[gidx[i],:]·α) / √v_leaf(gidx[i])`** — one multiply in that slot.
  **Do NOT rescale the tree precision:** `D_a` is p-dimensional but the latent is `2p−2` nodes
  (internal ancestors have no α), so `D_a⁻¹QD_a⁻¹` has no well-defined lift. Consequence: `Q`,
  `logdetCprior`, `logdet P` stay **α-free**, so α enters only via `ZᵀWZ` and `b`.
- **α gradient:** for one component `ZᵀWZ` is *diagonal*, so
  `∂logdetH/∂α_k = Σ_r ∂(ZᵀWZ)_rr/∂α_k · S[r,r]` needs only `diag(takahashi_selinv(ch))` — the same
  object `_diag_ZHinvZt` (`:579`) already computes.
- **Vector-α shape:** mirror the #164 precedent `_phylo_mean_laplace_hetero_fg`
  (`src/sparse_laplace_glmm.jl:901`) — scalar accumulator → `Xσ`-chained vector, `crossν` → `q×pσ`
  matrix — and carry over its **parity contract** (`:899`): a one-column constant design must
  reproduce the scalar route bit-for-bit.
- **HARD CONSTRAINT:** `ForwardDiff.Dual` does **not** flow through CHOLMOD
  (`src/fit_q4_sparse_tmb.jl:17-24`). The dense engines' `autodiff = :forward` cannot come along —
  every logdet derivative must be an analytic Takahashi trace. This is the main new work.
- **GATE BEFORE ANY CODE:** the dense engine documents a *measured* cancellation failure — with
  per-species `D_a`, a Woodbury-style `q1 − dot(C, M\C)` lost every digit as σ_e → 0
  (`gaussian_lss.jl:315-323`). The sparse base has the **same subtraction shape**
  (`quad = dot(r, w.*r) − dot(b, â)`, `:478`). Re-run that experiment against this form at small σ_e
  **before** building on it.
- **Oracles:** the dense lss engines under their 5000-row caps are the exact comparators;
  `_loconly_dense_comparator_diagnostic` (`src/location_only.jl:327`) is the template for wiring one.
- ⚠ **D-139:** the p = 10,000 scaling run is a >30 min campaign — **state a time estimate and get the
  owner's approval before running it.** No whole-tree claim without it.

### 4. Ledger row 12 → `covered`
Stamp an SE-parity cell for one lss fit in drmTMB's `parity-se.tsv` machinery, flip row 12
`partial → covered` in `drm_julia_capability_comparison()` (drmTMB `R/julia-bridge.R`), **regenerate
the TSVs via `tools/write-julia-capability-comparison.R` — never hand-edit them**, and confirm
`python3 tools/parity_ledger.py --drmtmb <path> --ref origin/main` reports **CLOSURE: PASS**.
Then v0.7.1 + Julia General registration is the owner's ceremony (D-181).

---

## Your environment (do not assume you inherit anything)

- **Working directory:** `/Users/z3437171/Dropbox/Github Local/DRM.jl` (branch `main` after #557 merges).
- **drmTMB sibling:** `/Users/z3437171/Dropbox/Github Local/drmTMB` — ⚠ that checkout was at
  `1cc1985cd` (stale, pre-#1100) at handover; **`git fetch && git log origin/main` before trusting
  it**, and it may be held by a Codex lane. Do drmTMB work in an isolated `git worktree`.
- **Julia suite (the safe verification command):**
  `julia --project=test --startup-file=no test/runtests.jl` — baseline **344 testsets, zero
  failures**, ~35–45 min. `Pkg.test()` is BROKEN on this machine; do not use it.
- **Before pushing any test change:** `python3 tools/check_test_deps.py` → "OK — every import is declared".
- **Live R↔Julia bridge runs need:** `NOT_CRAN=true DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<DRM.jl path>`,
  and `JULIA_NUM_THREADS=8` **before the first Julia call** for threaded profile/bootstrap.
- **Never stage:** `.codex/agents/shannon-coordinator.toml` (untracked, PROTECTED), `.worktrees/`.
- **License boundary:** drmTMB is GPL(≥3), DRM.jl is MIT. **Never vendor drmTMB source** — parity
  fixtures use generated OUTPUTS only (see `test/fixtures/lsss/README.md` for the pattern).
- **Merge rules:** one issue → one branch → one PR → merge, `closes #NN`. DRM.jl has strict branch
  protection (test(1), test(1.10), docs must pass and the branch must be up to date); drmTMB has **no**
  required checks, so `--auto` merges instantly — use an explicit merge-on-green watcher there.
  **Do not auto-merge on the owner's behalf beyond the standing "merge when CI is green" authorization.**

## Gotchas / failed approaches (paid for in this session)

- **Push only after the LOCAL full suite runs on the FINAL head.** CI caught two stale-fixture tests
  my mid-arc suite had missed (they depended on the NaN vcov #556 removed). A suite run on an earlier
  head is not evidence about the head you are pushing.
- **A failed check CANCELS GitHub auto-merge** — re-arm after pushing a fix.
- **Do not delete a worktree while a background job still points at it** (it silently invalidated an
  acceptance run mid-flight).
- **Precompile lock contention:** a suite run and an R-bridge run against the same checkout collide
  (`Pidfile`); use separate worktrees or serialise.
- **Julia `@formula` cannot parse keyword args or string literals** — hence `sd(g, phylogenetic)`
  with a bare symbol, where drmTMB writes `sd(g, level = "phylogenetic")`.
- **Non-ASCII in R string literals fails `R CMD check`** (comments are exempt). Check with
  `tools::showNonASCIIfile`.

## Open questions / judgement calls left to you or the owner

- The `_glsp_reml_penalty` normalisation discrepancy (above) — a doc bug or a route bug; resolve before #558 ships.
- drmTMB's gates-ledger rows (~`:247`/`:260` in `R/julia-bridge.R`) still say `response="include"` is
  refused on mean-phylo; untrue since #517. Fix when you are next in that file.
- Whether #559's post-fit surfaces should restore full-row `means`/`obs`/`scales`
  (`_with_full_fixed_gaussian_rows` precedent) or report observed rows only.

## How to resume

```sh
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
git fetch origin && git checkout main && git pull --ff-only
bash ~/shinichi-brain/tools/lane_preflight.sh .      # ~2 s, never blocks; DO WHAT IT SAYS
gh issue view 558                                    # your first slice
```

Then read `AGENTS.md` (team, lanes, Definition of Done, contracts), `CLAUDE.md`, and
`docs/dev-log/evidence/2026-08-28-lss-acceptance-matrix.md` (the bar Ayumi's models must keep
clearing). Classify every item above as `OWED` / `DONE` / `RETRACTED` / `PROTECTED` against the
actual git state before you write code.

---

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-28-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
