# Totoro campaign certification — timing re-derivation and tree-scale audit (issue #468)

**Date:** 2026-08-25 · **Platform:** Claude Code (Shannon) · **Target:** Totoro (384 cores, D-143 cap 150)
**Authorised by:** Shinichi, 2026-08-25 — *"run the coverage campaign on Totoro"* (the D-139 go/no-go on
`docs/dev-log/evidence/2026-08-24-coverage-prerun.md` §7).

This document records the **pre-grid certification only**. No coverage number appears in it, and both
`interval_status != "coverage_claimed"` fences remain intact.

## Environment

| item | value |
|---|---|
| host | `totoro.biology.ualberta.ca`, 384 cores, 1007 GB RAM, load ≈ 0.1 at start |
| access | existing ControlMaster socket `~/.ssh/cm-…totoro…` (pid 74689), `ssh -O check` first — **no Duo prompt** (D-64) |
| julia | **1.10.10** via juliaup (`+1.10.10`), matching `Project.toml`'s `julia = "1.10"` |
| repo | rsync of `feat/drmtmb-catchup` @ `6f52d179` → `~/drm_coverage/DRM.jl` (4.0 MB; `git clone` failed on a network disconnect) |
| threading | `OPENBLAS_NUM_THREADS=1` throughout; core cap **150** (D-143, binding) |

`git clone` from Totoro failed (`fetch-pack: unexpected disconnect`), so the tree was rsynced instead and
the source commit written to `~/drm_coverage/STAGED_SHA.txt`. Provenance is the SHA, not the clone.

## 1. Per-rep cost re-derived on target hardware

The pre-run's §5 estimate was measured on this Mac and carried a **×2 safety factor** on the assumption
that "cluster cores are typically ~1.5–2.5× slower per-core". Measured on Totoro, that assumption is
wrong in the **favourable** direction:

| stage (Cell B, `q4_vcov = true`) | Mac (pre-run §3) | **Totoro (measured)** |
|---|---|---|
| cold fit, JIT included | 48.1 s | **36.5 s** |
| warm fit | 2.7 s | **11.8 s** |
| Wald, 17 rows | 3.63 s | **1.09 s** |
| profile(`rho12`) | 84.8 s | **34.7 s** |
| **per rep (warm + wald + profile)** | **91 s** | **47.6 s** |

**Consequence for the campaign bill:** Cell B at n_sim = 1000 is **13.2 CPU-h**, not the 25.3 CPU-h the
pre-run budgeted. At the 150-core cap that is ≈ 7 reps/shard × 47.6 s + 36.5 s JIT ≈ **6–7 minutes wall**.

Two components moved in opposite directions and it is worth saying so rather than quoting only the
headline: the warm fit is **4× slower** on Totoro (11.8 s vs 2.7 s) while the `rho12` profile is **2.4×
faster** (34.7 s vs 84.8 s). The net is favourable, but a design that leaned on the warm-fit cost alone
would have been misled. The 11.8 s warm figure is used as-is (conservative — a third fit was not timed,
so some residual compilation may still be inside it).

## 2. Two of the pre-run's three stated risks resolved, measured

The pre-run's §7 "honest case against" listed three. Two are now settled on target hardware:

- **(ii) Cell B convergence.** The pre-run warned the Optim flag is `false` on this shape, which would
  yield "a conditional-on-convergence coverage number plus a large *fit failed* bucket". **Measured
  `converged = true`** on Totoro. This is #484's automatic warm restart, which landed after the pre-run
  was written. The campaign will still report the rate rather than assume it.
- **(F3) Wald finiteness.** `q4_vcov = true` gives **17/17 finite** Wald rows. Confirmed independently
  here, and the campaign uses that setting.
- **(F2) reproduced independently:** on Cell U, `confint(fit; method = :wald)` returns `[-Inf, Inf]` for
  the `sigma` and `resd` axes on Totoro exactly as on the Mac. Those two rows stay **excluded by design**;
  an infinite interval covers everything and would read as 100 % coverage.

Still open from §7: **(iii)** Cell U's larger-`ntip` costs were AGENT-INFERRED. §3 below replaces them.

## 3. Tree-scale audit — the trap #454 demands be partitioned before any grid

`re_sd` for a phylo term is defined against the **raw** covariance `sigma_phy_dense(phy)`, whose diagonal
is the tree height — not a normalised correlation. At `branch_length = 0.25` a balanced tree has height
`0.25·log2(ntip)`, so the ladder is height **1.00 / 1.25 / 1.50** at ntip **16 / 32 / 64**.

**ntip = 16 has height exactly 1.0, where the two conventions coincide.** An audit run only there proves
nothing. So the audit was run across the ladder, 60 seeds per rung, DGP simulating `u = σ_phy · L z` on
the raw covariance:

| ntip | height | converged | β₀ | β₁ | log σ_resid | **log σ_phy** | raw truth | normalised would give |
|---|---|---|---|---|---|---|---|---|
| 32 | 1.25 | 60/60 | 0.2958 | 0.2598 | −0.7096 | **−0.3956** | −0.3567 | −0.4682 |
| 64 | 1.50 | 60/60 | 0.2566 | 0.2487 | −0.6863 | **−0.3817** | −0.3567 | −0.5594 |

**PASS.** The recovered `log σ_phy` tracks the **raw** truth and shows no drift toward the normalised
values. At ntip = 64 the observed −0.3817 sits 0.025 from the raw truth and 0.178 from the normalised
one — a 7× separation, in the right direction. β₀/β₁ recover, and convergence is 60/60 at every rung.

DRM.jl emits its own warning at height ≠ 1 (`src/sparse_phy.jl:533`), naming the `sqrt(height)` factor
against drmTMB's `ape::vcv(tree, corr = TRUE)` convention. The audit agrees with that warning rather than
contradicting it.

Cell U cost, measured: 60 reps × 3 rungs completed in **12.7 s wall including JIT** — so the whole Cell U
ladder at n_sim = 1000 is minutes, not hours. The pre-run's inferred "×4–×20" scale-up is superseded by
measurement, closing §7's item (iii).

## What this document does NOT establish

No coverage rate is reported here, and none was computed. This is the certification that the campaign's
cost estimate and its DGP-vs-estimator scale agreement hold on the machine that will run it. The campaign
itself, its runner, and any coverage number are separate and come after.
