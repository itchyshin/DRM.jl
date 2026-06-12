# Session handover — 2026-06-12 (σ-phylo + REML ship → AI-REML fresh)

*Speaking as Shannon. No subagents running at the time of writing. Evidence-first:
reconstruct state from `git status`, recent commits, and this file — not chat memory.*

## TL;DR — first five minutes of the next session

1. **Read this file, then `HANDOVER.md` + `AGENTS.md` + `ROADMAP.md`.** Check
   `git status` and `git log` in the three worktrees (below).
2. **The headline opener is AI-REML** — the "beat ASReml, superfast, the speed is on
   the Julia side" milestone. The derivation sketch is in §4; build it with a clean
   context, anchored on the FD-REML shipped this session as the correctness reference.
3. **Ayumi reply is DEFERRED to this session by the user's explicit instruction** —
   "we write to her in the next session." The draft + the working install are ready
   (§5). Do NOT post until REML delivery is bundled and the user green-lights.
4. **Widget**: keep it live; restart per §6.

## 1. Worktrees & branches (where everything lives)

| Worktree | Branch | Holds |
|---|---|---|
| `~/worktrees/DRM-integrate` | `shannon/land-sigma-phylo` | the q4 engine + σ-phylo locscale + **REML** (this session) |
| `~/worktrees/DRM-RELEASE` | (release) | widget backup `report/dashboard/`, Ayumi draft `report/ayumi-issue2-followup-draft.md` |
| `~/worktrees/drmTMB-RELEASE` | `shannon/RELEASE-drmtmb` (base 5a9f6c4e, **UNPUSHED**) | R bridge: families fix applied; REML gate still BLOCKS σ-phylo (§5) |

Main checkout `~/Dropbox/Github Local/DRM.jl` was on `codex/missing-response-bridge`
at session start.

## 2. What shipped this session (DRM-integrate, branch shannon/land-sigma-phylo)

Committed earlier (verified):
- `1013908` σ-phylo locscale subsystem (separate / coupled / asymmetric blocks).
- `637388e` rho12 RHO_GUARD·tanh alignment to drmTMB.
- `7e2f1ad` Student ν = 2 + exp(η) alignment.
- `794ad58` NB2 log-σ alignment (size r = exp(−2ψ); MoM starts, residuals, VA, FD all fixed).

**This turn — FD-REML for the Gaussian σ-phylo route (uncommitted at time of writing):**
- `src/gaussian_locscale_phylo.jl`: `_glsp_reml_penalty` (Patterson–Thompson
  0.5·logdet S, S = FD of the analytic β_μ-gradient block = the marginal β_μ-information
  = Schur complement); `_glsp_reml_refit` (LBFGS polish of θ̂_ml). **Convergence is
  judged on substance** — ML converged + restricted objective finite (β_μ-info PD) +
  θ̂ stays near θ̂_ml — because the FD-penalty's gradient is a second finite difference,
  too noisy for Optim's gradient-convergence flag (a false negative; it parks at the
  right θ̂). Asymmetric + separate paths route through it; `reml = method === :REML`
  in `gaussian_core.jl`.
- `test/test_reml_sigma_phylo.jl`: (a) **identity anchor** — penalty at logL22 = −10
  ≈ 0.5·logdet(Xμ'WXμ) (the fixed-effect REML limit); **PASSED diff 3.17e-8**.
  (b) **end-to-end** `drm(method = :REML)` — tagging, finite REML/ML loglik, REML ≠ ML,
  recovery (σ-phylo SD in range), REML ≈ ML at this p.

**Verification state:** identity 3.17e-8 (proven correct). End-to-end estimates correct
(REML σ-SD 0.266 ≈ ML 0.267, finite, REML ≠ ML, recovery + tagging pass). The
convergence-flag fix (this turn) is under re-test (`/tmp/reml4.log`) — confirm green,
then commit with this handover.

**Still owed for REML (next session, before Ayumi):**
- Bridge relax: `drmTMB-RELEASE/R/julia-bridge.R:~98` `reml_supported <- gaussian &&
  !has_phylo` BLOCKS σ-phylo REML — relax for the Gaussian σ-phylo locscale cell;
  add a REML bridge smoke test.
- Ultracode adversarial verify: bias-reduction sim (REML lifts the n→n−p downward bias
  at small p), the AIC/BIC/LRT guard (REML likelihoods not comparable across fixed-
  effect structures — ML stays the default), no-regression.

## 3. The audit alignment (user's independent audit — all three DONE)

drmTMB is the reference; DRM.jl aligned to it: **rho12** plain→RHO_GUARD·tanh (`637388e`);
**NB2** log-size→log-σ (`794ad58`); **Student ν** exp(η)→2+exp(η) (`7e2f1ad`). All green.

## 4. ★ AI-REML — the fresh session's headline opener (derivation sketch) ★

**Goal (user, verbatim intent):** "to beat ASReml — we need to beat it with REML!!! —
superfast, and the speed comes from the Julia side." REML = TRUE/FALSE like glmmTMB;
REML can converge where ML fails.

**Where it lives:** the fast REML is the **DRM.jl (Julia) engine** — the O(p) sparse
augmented-Laplace + Takahashi selected inverse give the exact gradient in O(p); AI-REML
is the average-information Newton update on top. **R (drmTMB) reaches it via
`engine = "julia"`.** drmTMB's *native* TMB engine has its own REML (TMB Laplace +
`random=`), comparable to ASReml — not the speed headline. Both packages expose REML;
the *speed* is Julia's.

### 4.1 The info-geometry insight — DONE (conceptual, NOT yet implemented)

For the REML variance-component update, **natural-gradient = Fisher information =
average information.** The AI matrix is the metric of the natural gradient on the
variance-component manifold — which is *why* AI-REML (ASReml's algorithm) converges in
~3–5 Newton steps. This identity is what makes the derivation tractable. **Done = the
insight. NOT done = the implementation + the ASReml benchmark** (those are queued).

### 4.2 Standard AI-REML (the LMM baseline)

For y ~ N(Xβ, V), V = Σ_k θ_k V_k (variance components θ):
- REML projection `P = V⁻¹ − V⁻¹X(X'V⁻¹X)⁻¹X'V⁻¹`.
- REML score `s_k = −½ tr(P V_k) + ½ (Py)' V_k (Py)`.
- Average information `AI_kl = ½ (Py)' V_k P V_l (Py)` — only data-dependent quadratics;
  the "average" trick cancels the expensive second-derivative-of-trace terms.
- Update `θ ← θ + AI⁻¹ s` (3–5 steps).

### 4.3 The location-scale twist (the genuine new work)

This is NOT a textbook LMM: the σ-axis RE is on **log σ**, so the residual variance is
heteroscedastic AND the σ-phylo RE enters the variance **non-linearly**
(σ_i = exp(Xψβψ + u_σ,i)). So V ≠ Σ_k θ_k V_k linearly, and the marginal is
Laplace-approximated. → **Operate on the Laplace-linearized model:** at the inner mode
the joint is Gaussian in the augmented latent; the `V_k` become
∂(Laplace precision)/∂(logL11, logL22), which the **existing exact gradient already
forms** (the Λ-trace term `M_k = −Λ⁻¹ ∂Λ Λ⁻¹`, via the Takahashi diag blocks).

### 4.4 Reusable (the hard 80%, already verified) vs new

- **REUSABLE:** the augmented-state sparse Laplace (precision + inner mode); the
  Takahashi selected inverse → the O(p) trace terms `tr(P V_k)`; the sparse solves for
  the quadratic forms `(Py)'…`.
- **NEW:** the REML **projection P** (the fixed-effect adjustment) — *at the Laplace
  level this is the SAME Schur-complement S already built for the FD-REML penalty in
  `_glsp_reml_penalty`*; the **AI quadratic forms**; the **Newton update loop**.

### 4.5 Scope & verification plan

The infrastructure exists; the new layer is P + AI + the location-scale care. The
**FD-REML shipped this session is the correctness anchor.** AI-REML must: (a) match the
FD-REML estimates (correctness); (b) reduce to the LMM AI-REML when σ is constant
(structural check); (c) converge in 3–5 steps (speed); (d) **benchmark vs ASReml-R —
measured, not extrapolated** (the headline). Realistic as a focused fresh-session slice
with a clean context.

## 5. Ayumi delivery — READY but DEFERRED (user: "write to her in the next session")

- **Issue:** Ayumi-495/LS_ecogeographical-rules#2. She explicitly wants to **wait for
  REML so she can do everything in one install** ("everything at one go").
- **Draft:** `DRM-RELEASE/report/ayumi-issue2-followup-draft.md` (R route works: mean
  SD 0.63, σ SD 0.52; + install caveat). Postable copy was staged at `/tmp/ayumi-post.md`.
- **Her snags to close before replying:** (i) branch 404 → push `shannon/RELEASE-drmtmb`;
  (ii) σ-phylo not reachable from R → the bridge families fix (applied) + the REML
  relax (owed, §2); (iii) her 50-vs-100-trees question → recommend **100 trees**.
- **Santi** (issue #4) was already POSTED — green-lit by the user. Do not re-post.
- **Sequence next session:** finish REML (commit + bridge relax + smoke) → reconcile +
  **push** `shannon/RELEASE-drmtmb` (σ-phylo families + REML relax + doc fixes; EXCLUDE
  held files — see §7) → then post the Ayumi reply on the user's go-ahead.

## 6. The widget (keep it live)

- Backup: `DRM-RELEASE/report/dashboard/` (index.html, update.sh, version.txt,
  sweep.json, status.json). Live copy ran from `/tmp/drm-dashboard/` via
  `python -m http.server 8765` + an `update.sh` loop.
- **Control:** I write `sweep.json` directly; `update.sh` refreshes `status.json`;
  `activeLanes` drives the persona lit-state.
- **TRAP (cost me a reload loop):** `version.txt` must equal the HTML `BUILD` constant.
  Only bump `version.txt` when you edit the HTML `BUILD` — a mismatch causes an infinite
  reload loop. Last good build was `r11`.

## 7. Constraints (carry forward — non-negotiable)

- **License:** drmTMB is GPL(≥3); DRM.jl is MIT. **Never vendor drmTMB GPL source into
  DRM.jl.** R-parity uses generated outputs only. Rose audits per tag.
- **Held files — do NOT touch:** `drmTMB-RELEASE/vignettes/how-fitting-works.Rmd`,
  `drmTMB-RELEASE/_pkgdown.yml`.
- **External writes are user-gated:** `git push`, GitHub issue/PR posts, the GLLVM brief
  — all wait for an explicit "yes" in chat.
- Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Local checks over CI. Verify before claiming — every speed/accuracy number reproduced.

## 8. ★ GLLVM cross-pollination — REMEMBER to pass it on (user request) ★

User: "AI-REML is done — we should remember to pass it onto GLLVM team." **Honest
state:** what's transferable *today* is the **method/insight**, not a benchmarked
implementation (§4.1). Package for the GLLVM team as **method-sharing only (ideas, not
code; MIT/GPL clean)**, filed **on the user's go-ahead** (external write):

1. **The Takahashi O(p) sparse-phylo exact gradient** + the **info-geometry AI-REML
   update** (natural-gradient = Fisher = average-information) — the recipe for a fast
   REML on sparse latent-Gaussian models.
2. **Boundary inference toolkit** — profile-likelihood + χ̄² mixture CIs for latent
   variances / loading correlations at the boundary, where the Wald Hessian is singular.
   Directly useful for GLLVM's **K-selection / over-factoring** ("this factor's variance
   is ≈ 0" reported as a *result*, not a crash).
3. **The R↔Julia bridge pattern.** Related issues already noted: DRM.jl #269 (Pagel-λ),
   #270 (Matérn/NNGP kernels); drmTMB #531.

Deliverable: append to `DRM-RELEASE/report/gllvm-cross-pollination-brief.md`; draft
issues on their repo — **filed only on the user's go-ahead.** Best shared *after* the
ASReml-R benchmark exists, so the speed claim is measured, not asserted.

## 9. Team & voice (keep stable)

Speak as **Shannon**; name the active perspectives; say explicitly when no subagents are
running. The 12 personas + lanes are in `AGENTS.md` (Ada/orchestrator, Noether/engine
math, Karpinski/perf, Fisher/inference, Boole/grammar, Curie/sim, Hopper/parity,
Lovelace/drmTMB, Grace/CI-CRAN, Florence/figures, Pat/docs, **Rose**/pre-publish gate).
Work ledger = GitHub Issues (milestones = phases; one issue → one branch → one PR).

## 10. Ordered next-session task list

1. Confirm `/tmp/reml4.log` green → **commit FD-REML + this handover** (DRM-integrate).
2. **AI-REML** (§4) — the headline; clean context, anchored on FD-REML; ASReml-R benchmark.
3. Bridge REML relax + smoke (`drmTMB-RELEASE/R/julia-bridge.R`).
4. Reconcile + **push** `shannon/RELEASE-drmtmb` (exclude held files) — *user-gated*.
5. **Post Ayumi reply** (§5) — *user-gated*; recommend 100 trees.
6. Ultracode adversarial verify of REML (bias-reduction sim, guard, no-regression).
7. GLLVM brief (§8) — *user-gated*.
