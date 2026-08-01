# GOAL — DRM.jl registry → Phase 1.5 bridge (IMMUTABLE — re-read at the top of EVERY arc)

## Mission

(1) Julia General-registry readiness + **scoped** hygiene gate (#8 / scoped #3) on a clean base after integrating `shannon/ayumi-integration` ↔ `main`, then (2) Phase 1.5 R↔Julia bridge ship checklist against #5 — DRM.jl side + drmTMB `engine = "julia"` contract — with Hopper parity evidence and Rose claim-vs-evidence closeout.

Exact finish line: Registrator-ready tip green (local `Pkg.test` + Aqua + Linux CI) **without** submitting Registrator until Shinichi explicitly OK's; then #5 closed at Hopper finish-matrix bar (experimental wording only).

## Headline

After #339 (merged), land a clean registry/hygiene PR onto the integrated ayumi↔main tip, then finish Phase 1.5 bridge honestly (reuse existing `drm_bridge` / `R/julia-bridge.R` — do not rebuild).

## Invariants

- **PLATFORM:** Cursor/Claude (Shannon+Ada). HANDS TO: none unless Shinichi reassigns.
- **One lane** on DRM.jl (and paired drmTMB only for bridge finish); no second concurrent editor on the same subject.
- **Base = A:** integrate `shannon/ayumi-integration` ↔ `main` before Registrator (not cherry-only onto main).
- **#3 = SCOPED hygiene only** (this `/goal` paste). Do **not** wire remaining `experimental/` / `#13 fit_em_natgrad` / dense reml_q4 in this run. (Oral "full" earlier is superseded by this GOAL paste.)
- **#5 = Hopper finish-matrix:** admitted cells + result-shape for Gaussian uni/bivariate/first phylo mean + gate-ID rejections; stay **experimental**; no new families.
- **Fence:** never dump commits `a4585bd` / `7520d9d` / `88a2382` / `66514a0` (AGENTS/Ranganathan) into ship PRs.
- **DEFER hard:** #136 VA/ELBO; #291 REML speed.
- **License:** MIT; never vendor drmTMB GPL.
- **Engine:** do not regress verified q=4 baseline (logLik −256.51).
- **Registrator / tags / public claims:** OPEN GATES — pause for Shinichi.
- **Compute:** Totoro for multi-shape/parity; laptop smoke only; not GHA for heavy benches.

## Authoritative WHAT

See `LOOP/ultra-plan.md` (copy of `docs/dev-log/plans/2026-08-01-ultra-plan-registry-bridge.md`). Where that file's DECISIONS LOCKED table says Q2 FULL, **this GOAL.md wins: Q2 SCOPED.**

## Definition of done

- [ ] S2: ayumi↔main integrated on a clean tip (PR merged or equivalent).
- [ ] S3: scoped hygiene PR merged — Aqua + `Pkg.test` green; load-print silenced if still present; HANDOVER/README register-ready honesty; no oversell of bridge or unwired experimental.
- [ ] S4: Registrator submitted **only after** Shinichi explicit OK (gate).
- [ ] S5: #5 Hopper matrix evidenced; Rose accepts experimental wording; no new families.
- [ ] S6–S8: mechanical verify + Rose audit + Melissa reconcile landed.
- [ ] Mission Control `drmTMB` status updated; after-task + check-log.d for closed slices.
