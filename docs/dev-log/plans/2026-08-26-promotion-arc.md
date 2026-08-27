# The promotion arc — moving capability rows from `partial` to `covered`

**Planned 2026-08-26 (Fable, per D-151).** State at planning time: DRM.jl `main` `d34d6749`,
drmTMB `main` `fc8ee77a6`, ledger `5 covered · 4 partial · 1 experimental · 1 unsupported`,
CLOSURE: PASS, 15 open issues.

## 0. The fact that reshapes the arc

**The four-limb `covered` bar does NOT require interval-coverage campaigns.**

Precedent: the three rows promoted in drmTMB PR #1085. Their limb-4 evidence was **SE/interval parity
with a negative control** (`parity-se.tsv`, single draw, ~1e-6 relative) while every
`interval_status = coverage_claimed` fence stayed up. Their boundary text says so explicitly —
*"interval evidence (parity-se.tsv …) … NOT interval COVERAGE"*.

So `covered` is a **capability** claim and `coverage_claimed` is a separate, higher fence.
**Coverage blocks the fences, not the rows.** An earlier framing in the handover — that the remaining
gap is campaign work — is wrong for the promotion goal. Collect SE-parity-grade evidence (minutes),
and treat fence work as a separate, optional arc.

Also load-bearing: p=3000 native TMB fits in **1.61 s**, Julia in **21.85 s**
(`2026-08-24-phylo-large-p-probe.md`), and `tools/parity_classc_largep.R` already emits full-precision
SEs. The instruments mostly exist.

## 1. The five rows, ranked by cost to promote

1. **`phylo_count_large_p`** — cheapest. Needs #506 (merged) plus a large-p SE rerun (~15 min). Open
   question: SE parity loosens to ~1.5e-3 at p ≥ 1000 while coef/logLik do not — resolve with §2d
   before promoting.
2. **`phylo_gamma_beta_binomial`** (experimental) — the ledger text is **behind its own evidence**:
   `parity-phylo-nongaussian.tsv` already records PARITY_PASS for Gamma (6.3e-08) and Beta (5.0e-07).
   Needs SE cells (~5 min) + tests/docs limbs. Binomial can never have parity (drmTMB natively
   refuses `phylo()` on binomial mu) so its route is **simulation recovery**.
3. **`general_covariance_structured`** — one real question: SE parity is Gaussian 3.4e-7 but Poisson
   4.7e-3, NB2 6.8e-3, Gamma 4.1e-2. Either inner-Laplace noise (argue tolerance a priori) or a
   defect. §2d classifies it. **#509 does NOT block this row** — that finding is on the q4 bivariate
   structured route; this row is the univariate one.
4. **`gaussian_response_mask`** — blocked by a semantics decision, settled by a 10-minute experiment:
   fit native drmTMB Gaussian mean-phylo with missing y under `include` and `drop`. If they are
   likelihood-identical on this route, `include` is `drop` + prediction — a wrapper, not a derivation,
   and the TSV's "needs a derivation" is too pessimistic.
5. **`cross_family_latent`** — do not spend compute before the §4.2 governance decision.

## 2. Highest-leverage unblocking work

a. **Batch the merge queue.** Merging serialises (branches must be current), so close/merge the stale
   #420 and #406 in one pass, then run the 45-min suite **once**.
b. **Stamp `drmtmb_code_hash` into all four parity harnesses** (`parity_classc.R`,
   `parity_classc_largep.R`, `parity_phylo_nongaussian.R`, `parity_se.R` — none record it;
   `tools/drmtmb_provenance.R` already computes it). The cheap 80% of #473. **Do this BEFORE Phase 1**
   so every number banked is provenance-proof.
c. **Per-coefficient `parm`** (`src/inference.jl`, `_ci_param_selected` :238, `_profile_jobs` :263 —
   selection is by block Symbol). Converts #495's test from unrunnable to a ~10-min 3-entry pilot.
   Honestly: serves the **fence** arc, not promotion. Do it because it is small.
d. **SE-divergence diagnostic**, shared by rows 1 and 3: on one fixed fit, tighten the inner
   Newton/Laplace tolerance stepwise and watch the Julia SE. Shrinks ⇒ solve noise (argue a tolerance,
   promote). Flat ⇒ a convention difference (observed vs expected information) needing a one-page
   derivation, not a campaign. ~1 h, replaces an open-ended hunt.
e. **#509 hygiene:** gate the q4 structured `converged` on Λ admissibility (the #505 guard is on q2
   only; the fixture reported converged at cond 1.3e12), and de-saturate the smoke fixture. While in
   there, grep the other smoke fixtures against the `4G ≥ 2n` bound — third bite of this lesson
   (#483, #509).

## 3. Sequence

- **Phase 0 (1 session)** — §2a merge batch → one full suite run → §2b hash stamping, §2c parm PR,
  §2d diagnostic, §1.4 include-vs-drop experiment. All minutes.
- **Phase 1 (1–2 sessions)** — bank evidence and promote rows 1, 2, 3. Each promotion is a drmTMB PR
  editing `R/julia-bridge.R` (**the source of truth — never hand-edit the TSVs**) with both artifacts
  regenerated and the gate test updated the way #1085 inverted the cap assertion.
- **Phase 2** — rows 4 and 5, after their decisions.
- **Phase 3 (separate, optional)** — fences: the parm-enabled #495 pilot, then profile-reliability
  engineering only if `coverage_claimed` is wanted at all. **Do not let this leak into promotion.**

## 4. What NOT to do

- **No new coverage campaigns for promotion** (§0). Days of Totoro for evidence the bar does not ask for.
- **#472** — unreachable from public `drm()`; fence + document, never "fix".
- **#471** — reclassified beyond-parity; drmTMB's own `biv_student()` defers structured effects.
- **#467 residual** (`newdata` reconstruction) — fails loudly, which is correct.
- **#473 full fix** — do **not** reinstall drmTMB mid-arc; it moves the comparator under every banked
  number. Stamp going forward; leave the 19 unstamped fixtures alone.
- **#327, #270, #269, #227, #49, #280, #9, #8** — genuinely deferrable.

## 5. Where the goal deserves challenging

1. **If `covered` is meant to imply coverage-grade evidence, that is a redefinition** and should be
   made explicitly — it would retroactively indict the five already-covered rows, which carry the same
   "NOT interval coverage" disclaimers.
2. **`cross_family_latent` may not honestly reach `covered`** in an R package's ledger while
   unreachable from R. Recommend a **permanent claim_boundary** (the `engine_control_surface` pattern)
   over bridge wiring, and correct `r_bridge_status` from the self-described "generous" `experimental`.
3. **Binomial can never have parity evidence.** Promote with a per-member evidence boundary, or split
   it out — do not let `covered` silently mean two grades within one row.
4. **`gaussian_response_mask`:** if `include` proves likelihood-identical to `drop`, match semantics
   and document. Deriving a masked likelihood drmTMB does not itself have would be beyond-parity work
   smuggled into a catch-up arc.
