# 2026-08-19 — Next G0 after the two levers (#449 / #451)

**Lane:** `lever-extension-scout` (Cursor / Shannon). Branch: `docs/lever-extension-scout`.
**This file is item 3 of the 2026-08-19 honesty sequence.** Items 1–2: AGHQ chip stays
`missing`; Cell D ADEMP is a **separate G0** (plan:
`docs/dev-log/plans/2026-08-19-cell-d-ademp-pre-run.md`). Items 4–5 wait.
**Read-only scout.** Do not implement `src/` from this file.

Cite: Liu & Pierce (1994) AGHQ; Cox & Reid (1987) adjusted profile; Patterson &
Thompson (1971) REML. Twin = **drmTMB**. Do not cite −7.3 / −5.0 / −0.9 as DRM.jl.
No GLLVM Λ. Capability chip stays **missing**. No recovery headline.

---

## What this item is / is not

| This slice | Not this slice |
|---|---|
| Scout the *next* engine attach after #449 and #451 | Implement `src/` |
| Recommend **one** G0 + draft GitHub issue text | `gh issue create` (STOP; draft lives here) |
| Noether: 1-D attach vs category error | Tensor / phylo AGHQ, `:REML`×`:AGHQ` |
| Chip stays `missing` | Flip `docs/design/capability-status.md` |
| Docs-only PR | ADEMP / Totoro, q4, #49, #420, #406, GPL vendoring |

---

## What already landed (do not redo)

| Lever | Issue / PR | Cell | Honesty |
|---|---|---|---|
| AGHQ 1-D Liu–Pierce | #448 / [#449](https://github.com/itchyshin/DRM.jl/pull/449) | Poisson `(1 \| g)` only. Default `:LA` = **GHQ-32**. | Plumbing. Kernel nll \|Δ\| vs GHQ-32 ≈ 0.004 at true θ; fitted loglik \|Δ\| ≈ 2e-4 (Mac) / 0.057 (CI). **Not recovery.** Chip `missing`. |
| Cox–Reid GHQ | #443 / #444 | Poisson `(1 \| g)` GHQ-32 | Cell A: ML **−12.4%** at G=10 vs CR **−1.8%**; CR **over-corrects** at G=40 (**+4.4%**). ML default. |
| Cox–Reid Laplace | #450 / [#451](https://github.com/itchyshin/DRM.jl/pull/451) | Poisson phylo / relmat / animal / precomputed-spatial | Cell D (ntip=16 / 12 seeds) **is not recovery** (ML +8.18%, CR +17.41%). |

Probe order (`docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md` § Next G0s)
had (1) Poisson GHQ CR → (2) Poisson phylo CR → (3) other families one at a time →
(4) AGHQ. (1), (2), and a narrow (4) are done. **(3) is the hole.**

---

## Scout 1 — AGHQ: who fail-louds, and is it a category error?

Public path: `marginal = :AGHQ` → `struct AGHQ` in `src/variational.jl`. The only
admitted cell is Poisson `(1 | g)` (`_fit_poisson_ranef_aghq` / `_poisson_group_aghq_logint`
in `src/aghq_1d.jl`). `_aghq_require_1d` throws unless dim == 1. Header of
`aghq_1d.jl`: tensor / multi-d AGHQ is **intentionally absent**; on tree-sized
phylo Laplace it is `k^{tree}`.

### Fail-loud map (measured in source, 2026-08-19)

| Cell | What happens | Noether |
|---|---|---|
| Poisson `(1 \| g)` | **Admitted** (#448) | Legitimate 1-D Liu–Pierce. |
| Poisson `phylo` / relmat / animal / precomputed spatial | `_aghq_reject(…, "a phylogenetic/structured random effect")` | **Category error** if sold as 1-D: the latent is tree-sized. Nested / sparse AGHQ is a different project. |
| Poisson crossed `(1\|g)+(1\|h)` | `_aghq_reject(…, "crossed/multiple random intercepts")` | **Category error** for 1-D attach (joint dim = G₁+G₂). |
| Poisson `(1 + x \| g)` | `_aghq_reject(…, "… (12² tensor GHQ is not AGHQ)")` | **Category error** vs this kernel. Existing product GHQ-12² is **not** Liu–Pierce. A 2-D *adaptive* product is a new kernel, not a copy of `_aghq_1d.jl`. |
| Poisson FE / `zi` / `hu` | `_aghq_reject(…, "no random intercept …")` | Nothing to integrate. |
| Poisson `:REML` × `:AGHQ` | dedicated `ArgumentError` (#448) | Deferred B. Combining two uncertified levers. |
| Binomial / NB2 / Gamma / Beta **any** structure | family-door `_aghq_reject(fam, "this family")` before ranef dispatch | **Legitimate 1-D attach** on `(1 \| g)` only (those routes are already GHQ-32). Not a category error. |
| `associate_pairs` QuadGK | reject `:AGHQ` | QuadGK ≠ AGHQ. |
| Other families without `marginal` | never enter `_marginal_method` | Out of this lever. |

Item 2 PRE-RUN already showed public `marginal = :AGHQ` on Poisson **phylo** throws.

### Leverage on the legitimate 1-D attach

On Poisson `(1 | g)`, public `:LA` is **already GHQ-32**. AGHQ k=5 vs that default is
integral **agreement**, not a bias lever. Extending the same kernel to Binomial /
NB2 / Gamma / Beta `(1 | g)` is the smallest *honest AGHQ* G0 — and the **least
scientific leverage** of the remaining options. Do not sell it as “DRM.jl now has
AGHQ.” Chip stays `missing` even after a second family.

---

## Scout 2 — Cox–Reid: Gaussian REML? other families on phylo Laplace?

Helpers already generic: `_glsp_reml_penalty` / `_glsp_reml_refit_clean` /
`_glsp_reml_vcov` / `_withreml`. Cell B: CR ≡ Patterson–Thompson on Gaussian
`(1 | g)` to `2.9×10⁻⁶`. Nothing new to derive.

### Gaussian REML (not this lever)

| Cell | Status |
|---|---|
| Gaussian FE location-scale REML | `implemented` |
| Gaussian mean `(1 \| g)` REML | `implemented` (#439 / #440) — Woodbury / Patterson–Thompson |
| Gaussian loc-scale phylo REML | already threaded (`reml = method === :REML` in `src/gaussian_core.jl`) |
| q4 all-axes phylo REML | `implemented` (`src/reml_q4.jl`) |
| Gaussian σ-RE, slopes, multi-ranef, structured/meta on the #439 path | still `ArgumentError` |

**Do not open a “Gaussian Cox–Reid” G0.** The Gaussian cells that matter already
have exact REML. Cell B was the anchor, not a to-do. q4 is fenced.

### Non-Gaussian REML fail-loud (after #451)

`_reject_method_as_marginal(..., allow_reml=true)` is **Poisson-only**. Binomial /
NB2 / Gamma / Beta still hit “`$famname` is ML-only”.

Poisson routes that still error on `:REML` (honest, keep):

- coordinate-spatial with estimated ρ
- crossed / `(1 + x | g)`
- `marginal = :VA` (ELBO is not a likelihood)
- `marginal = :AGHQ` (not wired)
- FE-only / `zi` / `hu`

### Other families on phylo Laplace — legitimate wiring, not first

Binomial / NB2 / Gamma / Beta already have `_fit_*_phylo_laplace` (and relmat
twins except Binomial, which is phylo-only among structured markers). The Poisson
#450 pattern (thread `reml` after `_withnll`) copies. **But:**

- Cell D is **not** a recovery result. Item 2 owns ADEMP and **STOP**s before Totoro.
- Poisson sequence was **GHQ first** (#443) then phylo (#450), because on GHQ-32
  the integral lever is already paid — residual σ̂ bias *is* the ML VC lever (Cell A).
- NB2 / Gamma / Beta put `log σ` in θ. Probe: mean-block `pμ` only until a separate
  decision. Binomial is **mean-only**, same θ layout as Poisson `[βμ; log σ_b]`.

So phylo CR on a second family is a **later** G0, not this one.

---

## Recommendation — ONE next G0

**Opt-in Cox–Reid on Binomial `(1 | g)` GHQ-32** (`method = :REML`; ML remains default).

Copy #443, not #448 and not #450.

| Why this, not the others | |
|---|---|
| Best remaining **lever** | Cell A mechanism is family-agnostic finite-cluster ML bias. AGHQ-on-GHQ-32 is not. |
| Smallest **honest** extension | Mean-only family; `_fit_binomial_ranef` already stores `nll` via `_withnll`; `grad_fn = θ -> ForwardDiff.gradient(nll, θ)` is the #443 pattern. |
| Chip stays missing | No TSV / “has non-Gaussian REML”. One more certified cell, still not a capability. |
| No recovery headline | Tests: direction (σ̂_CR > σ̂_ML per seed), `reml_loglik ≠ ml_loglik`, uncertified routes error. No ADEMP. |
| Matches probe order | Next G0s item 3, first family = Binomial (mean-only before NB2/Gamma/Beta). |

**Explicitly not this G0**

- 1-D AGHQ on Binomial/NB2/Gamma/Beta `(1 | g)` — legitimate, low leverage; later if wanted as plumbing.
- Tensor AGHQ / phylo AGHQ / `(1+x|g)` AGHQ — category error vs `_aghq_1d.jl`.
- `:REML` × `:AGHQ` — deferred B.
- Binomial phylo Laplace CR — next *after* this, mirroring Poisson; not ADEMP.
- NB2/Gamma/Beta CR — extra σ in θ; separate `pμ` decision.
- Gaussian REML — already shipped on the cells that matter.
- Cell D ADEMP — item 2; owner approval; >30 min.
- Chip flip, q4, #49, #420, #406, GPL vendoring, GLLVM Λ.

---

## If this G0 is named — attach sketch (not started)

Files (implementer G0, **not this PR**):

- `src/variational.jl` — `_reject_method_as_marginal(fam::Binomial, …; allow_reml=true)` **or** pass `allow_reml=true` from `drm(::Binomial)` only; keep `_reject_reml_route` copy naming the new cell.
- `src/binomial.jl` — admit `:REML` on `(1 | g)` GHQ; reject phylo, crossed, slopes (Binomial has no public `(1+x|g)`), VA, FE-only.
- `_fit_binomial_ranef(...; reml=false)` — same refit / vcov / `_withreml` as `_fit_poisson_ranef`.
- `test/test_cox_reid_binomial_ranef.jl` — standalone; **do not** require `runtests.jl` this G0 (same fence as #443 / #451).
- Docstring warning: ML default; over-correction possible; not a chip.

Reuse unmodified: `_glsp_reml_penalty`, `_glsp_reml_refit_clean`, `_glsp_reml_vcov`, `_withreml`.
Never vendor drmTMB `R/aghq-coxreid.R`.

---

## Draft GitHub issue (do not create this slice)

Default STOP: paste when Shinichi names the G0. Labels: `enhancement`, `engine-quality`.
Do **not** reuse #448 / #443 / #450 / #136 / #49 / #11.

````markdown
# Cox–Reid Binomial (1|g) GHQ (opt-in method=:REML)

## Mission

Admit opt-in `method = :REML` (Cox–Reid, `½ log|I_ββ|`) on **Binomial** scalar
`(1 | g)` integrated by GHQ-32 (`_fit_binomial_ranef`). **ML stays the default.**
No recovery headline. Capability chip stays **missing**.

This is the next family cell after Poisson GHQ (#443 / #444) and Poisson phylo
Laplace (#450 / #451). Scout:
`docs/dev-log/plans/2026-08-19-lever-extension-next-g0.md`.

Twin = drmTMB (mechanism only). Cite −7.3 / −5.0 / −0.9 as **drmTMB's** only.
Never vendor GPL source. No GLLVM Λ.

## Attach cell

- Family: `Binomial()` (mean-only; θ = `[βμ; log σ_b]`, same layout as Poisson).
- Structure: single random intercept `(1 | g)` only.
- Integral: existing GHQ-32. Residual σ̂_b bias is the ML VC lever (probe Cell A
  mechanism), not an AGHQ job.
- Reuse #444 helpers unmodified: `_glsp_reml_penalty` / `_glsp_reml_refit_clean` /
  `_glsp_reml_vcov` / `_withreml`.
- `grad_fn = θ -> ForwardDiff.gradient(nll, θ)` (no analytic closure on this route).

## Keep rejecting

Phylo / structured, crossed intercepts, `(1 + x | g)` if it appears, `marginal = :VA`,
`marginal = :AGHQ`, FE-only. NB2 / Gamma / Beta stay ML-only. Poisson cells already
wired stay untouched. Do **not** punch `_fit_binomial_phylo_laplace` this issue.

## Honesty

- No ADEMP. No parameter-recovery target.
- Tests assert direction and mechanism only (σ̂_CR > σ̂_ML per seed;
  `reml_loglik ≠ ml_loglik`; uncertified routes error).
- Over-correction is possible when clusters are plentiful (Poisson Cell A G=40).
  That is why ML is the default.
- Do not flip `docs/design/capability-status.md`. AGHQ row stays `missing`.

## Tests

Standalone `test/test_cox_reid_binomial_ranef.jl`. **Do not** edit
`test/runtests.jl` this G0 unless a later owner call says otherwise.

## Fences

- No q4 / `src/reml_q4.jl`.
- #49 PARKED.
- Do not steal #420 / #406.
- No tensor / phylo AGHQ. No `:REML` × `:AGHQ`.
- No Cell D ADEMP / Totoro.
- D-111 Julia General OFF.
- Human merges the PR (`closes` this issue). Worker does not `gh pr merge` on `src/`.

## Definition of Done

`AGENTS.md`: impl + tests + docstrings + worked example + check-log.d + after-task
+ Rose audit. One branch → one PR.
````

---

## Shannon / lane notes (this scout)

- Dropbox `DRM.jl` was on `docs/cell-d-ademp-scope` (item 2) with untracked
  `2026-08-19-cell-d-ademp-pre-run.md`. This lane used a **separate worktree**
  `~/local-scratch/lanes/DRM.jl-lever-extension-scout` off `origin/main` @
  `8c6d4f78` (#451 merge). Item 2 files were not staged.
- Coordination board `docs/dev-log/coordination-board.md` is **committed** on
  `origin/main` (reaches other lanes) but **stale** (still describes 2026-08-16
  catch-up). This slice does not punch it (shared counter / shared file).
- `LOOP/GOAL.md` on `origin/main` still reads as the #450 phylo-CR mission.
  Stale; do not rewrite from a scout.
- Open foreign docs PRs: **#420**, **#406** — do not steal.
- Census at scout time: 3 live lanes (those two PRs + worktree×33). This lane
  owns **this plan file only**.

`PLATFORM: cursor | ON BRANCH: docs/lever-extension-scout | LANE: lever-extension-scout`
`OTHER LANES: cursor+PR#420 + cursor+PR#406 + item-2 docs/cell-d-ademp-scope (Dropbox, untracked plan)`
