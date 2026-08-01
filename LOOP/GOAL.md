# GOAL — DRM.jl Phase 1.5 bridge closeout (IMMUTABLE — re-read at the top of EVERY arc)

## Mission

Finish Phase 1.5 R↔Julia bridge ship checklist against #5 — DRM.jl side +
drmTMB `engine = "julia"` contract — with Hopper parity evidence and Rose
claim-vs-evidence closeout. Keep tip hygiene honest (version / tag / claim
surfaces). **Julia General-registry submission is OUT OF SCOPE** (brain
**D-111**, Shinichi 2026-08-01): stay off General until ready — at least catch
up with the R twin **and** both halves working well; **probably drmTMB goes to
R/CRAN first**. Do not install/pursue JuliaRegistrator; tip-green / `v0.1.2` ≠
registered.

Exact finish line: #5 closed at Hopper finish-matrix bar (experimental wording
only); tip docs Rose-honest that DRM.jl is an MIT package distributed via
GitHub / `Pkg.develop` (or a future private path) — **not** via General.

## Headline

S2/S3 hygiene and tip verify already landed. Phase 1.5 Julia+twin (#349 +
drmTMB #878) merged and #5 CLOSED; fence General Registrator as cancelled
(D-111); finish tip hygiene via this PR.

## Invariants

- **PLATFORM:** Cursor/Claude (Shannon+Ada). HANDS TO: none unless Shinichi reassigns.
- **One lane** on DRM.jl (and paired drmTMB only for bridge finish); no second concurrent editor on the same subject.
- **#3 = SCOPED hygiene only** (this `/goal` paste). Do **not** wire remaining `experimental/` / `#13 fit_em_natgrad` / dense reml_q4 in this run.
- **#5 = Hopper finish-matrix:** admitted cells + result-shape for Gaussian uni/bivariate/first phylo mean + gate-ID rejections; stay **experimental**; no new families.
- **Fence:** never dump commits `a4585bd` / `7520d9d` / `88a2382` / `66514a0` (AGENTS/Ranganathan) into ship PRs.
- **DEFER hard:** #136 VA/ELBO; #291 REML speed.
- **License:** MIT; never vendor drmTMB GPL.
- **Engine:** do not regress verified q=4 baseline (logLik −256.51).
- **General registry / JuliaRegistrator:** OUT until readiness (**D-111**) — do **not** post `@JuliaRegistrator register`, do **not** ask Shinichi to install the app, do **not** merge any General PR if one appears (report URL for Shinichi to close).
- **Compute:** Totoro for multi-shape/parity; laptop smoke only; not GHA for heavy benches.

## Authoritative WHAT

See `LOOP/ultra-plan.md` (copy of `docs/dev-log/plans/2026-08-01-ultra-plan-registry-bridge.md`). Where that file still lists Registrator / General as a deliverable, **this GOAL.md wins: General is out of scope.** Where that file's DECISIONS LOCKED table says Q2 FULL, **this GOAL.md wins: Q2 SCOPED.**

## Definition of done

- [x] S2: ayumi↔main integrated on a clean tip (PR #340).
- [x] S3: scoped hygiene PR merged — Aqua + `Pkg.test` green; load-print silenced; HANDOVER/README honesty; no oversell of bridge or unwired experimental (#341–#343).
- [x] **S4: CANCELLED / out of scope (D-111)** — General not until R catch-up + both working; drmTMB likely first. `v0.1.2` git tag may remain — **not** General membership.
- [x] S5: #5 Hopper matrix evidenced; Rose experimental wording PASS; DRM.jl #349 @ `d296703` + drmTMB #878 @ `fb59cd3` MERGED; **#5 CLOSED**.
- [ ] S6–S8: mechanical verify + Rose audit + Melissa reconcile landed (bridge closeout / tip hygiene — this PR #352).
- [ ] Mission Control `drmTMB` status updated; after-task + check-log.d for closed slices.
