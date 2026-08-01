# After-task: Registry hygiene S2/S3 (ayumi→main + scoped #3)

**Date:** 2026-08-01  
**Platform:** Cursor / Claude (Shannon speaking; Ada+Grace+Rose perspectives; no spawned subagents for this DoD write).  
**Main tip at closeout:** `e7261d9` (Merge #343).  
**Plan:** `docs/dev-log/plans/2026-08-01-ultra-plan-registry-bridge.md`  
**Repo scope:** DRM.jl only — no drmTMB edits.

## 1. Goal

Bank Definition-of-Done evidence for the completed ultra-plan #2 slices **S2** (ayumi↔main integrate) and **S3** (scoped registry hygiene), after merges #340–#343 landed on `main`. This PR adds check-log + after-task only; it does **not** submit Registrator and does **not** open Phase 1.5 (#5) R work.

## 2. What merged (ledger)

| Slice | PR | Merge SHA | Merged (UTC) | Contents |
|---|---|---|---|---|
| **S2** ayumi→main (Q1=A) | [#340](https://github.com/itchyshin/DRM.jl/pull/340) | `7df22b4` | 2026-08-01T14:05:23Z | Integrate `shannon/ayumi-integration` @ `7cb868d` into `main`; lands **#337** σ-phylo REML β_ψ restriction + **#339** `docs/design/capability-status.md`; conflict resolutions kept main's stronger bootstrap REML `method` passthrough and bridge surface; LOOP kit for scoped Q2 |
| **S3** load hygiene | [#341](https://github.com/itchyshin/DRM.jl/pull/341) | `50faf6d` | 2026-08-01T14:06:37Z | Remove residual script-gated load banners in `src/fit_q4_sparse_tmb.jl` / `src/fisherz_q4.jl`; bank `docs/dev-log/plans/registry-checklist-2026-08-01.md` |
| **S3** docs honesty | [#342](https://github.com/itchyshin/DRM.jl/pull/342) | `74f30a8` | 2026-08-01T14:06:47Z | Rose-honest `HANDOVER.md` / `README.md` Next + claim fences; same checklist file as #341 |
| Checkpoint | [#343](https://github.com/itchyshin/DRM.jl/pull/343) | `e7261d9` | 2026-08-01T14:16:56Z | `LOOP/checkpoint.md` records S2/S3 done; S4 Registrator remains open gate |

Antecedent gate **#339** (capability-status) had already merged into ayumi @ `7cb868d` before S2.

## 3. Evidence

### Local (pre-/on-integrate tip)

| Check | Result | Log / note |
|---|---|---|
| `using DRM` silence | Markers empty → `USING_DRM_OK` | `/tmp/drm-pkg-test-logs/using-drm-silence-check.log` |
| Focused REML σ-phylo | PASS (`test/test_reml_sigma_phylo.jl`) | `/tmp/drm-pkg-test-logs/test-reml-sigma-phylo-20260801-073456.log` |
| Full `Pkg.test()` | `Testing DRM tests passed` (exit 0) | `/tmp/drm-pkg-test-logs/pkg-test-ayumi-integrate-20260801-071902.log` |
| Aqua | **10/10** in suite (`Aqua.jl quality assurance \| 10 10`) | same Pkg.test log |

Local suite was recorded on the ayumi-integrate / S3 tip before the three merges stacked on `main`; no contradictory Fail cells were claimed. VA scaffold retains Broken/skip cells (not Fail).

### CI (GitHub Actions)

| PR | Documenter | `test (1)` / `test (1.10)` | Notes |
|---|---|---|---|
| **#340** | **pass** (run `30701314951`) | **pass** / **pass** (run `30701314945`, ~50m / ~38m) | Integration tip CI green before merge |
| **#341** | **pass** (run `30703091845`) | **pending** at DoD write (run `30703091842`) | Hygiene `src/` silence; do not claim Julia CI green until conclusion lands |
| **#342** | **pass** (run `30703097078`) | **pending** at DoD write (run `30703097083`) | Docs-only; Documenter green |
| **#343** | pending at DoD write | pending at DoD write | Checkpoint-only |

**Claim discipline:** S2 has verified Linux CI green. S3 has verified local silence + Aqua/`Pkg.test` + Documenter; post-merge Julia CI on #341/#342/#343 is **not** asserted green in this after-task.

## 4. Locked decisions (held)

| ID | Decision | Status after S2/S3 |
|---|---|---|
| **Q1 BASE** | Integrate ayumi↔main before Registrator (not cherry-only) | **Done** via #340 |
| **Q2 #3 SCOPE** | **SCOPED** registry hygiene only — not full experimental wire | **Held** — #341/#342 only; `#13 fit_em_natgrad` / remaining `experimental/` wire deferred |
| **Q3 #5 SHIPPED BAR** | Hopper finish-matrix; stay experimental; no new families | **Not started** for R-side; Julia-side inventory may exist as plan draft only |
| Registrator | Explicit Shinichi OK required | **Not submitted** (S4 open) |
| Fence AGENTS | No dump of REML-tip AGENTS/Ranganathan commits | **Held** |
| DEFER | #136 VA/ELBO; #291 REML speed | **Held** |
| License | MIT; no drmTMB GPL vendoring | **Held** (DRM.jl-only PRs) |

## 5. Fences / open gates (explicit)

1. **No Registrator yet (S4).** Do not open a General-registry PR or tag/version bump for registration without Shinichi's explicit OK. Version/tag drift remains noted: tree `Project.toml` / `CITATION.cff` still `0.1.0` while tags `v0.1.0` / `v0.1.1` exist — decide at S4.
2. **#5 R blocked.** Phase 1.5 R↔Julia finish (drmTMB `engine = "julia"` inventory / Hopper matrix vs twin) waits on a free drmTMB lane; this session must **not** touch drmTMB. Julia helpers remain in-tree; bridge is **not** claimed shipped.
3. **Q2 scoped.** Closing #3 as "full Phase 1.0 wire" would be false; only registry-hygiene cells of #8 / scoped #3 advanced.
4. **Do not oversell.** `src/experimental/` is not fully public-wired; REML speed (#291) and VA (#136) stay deferred.

## 6. Files already on `main` from S2/S3 (not this DoD PR)

Representative (non-exhaustive):

- Engine: σ-phylo REML β_ψ restriction (#337 via #340)
- Hygiene: load-banner silence in `fit_q4_sparse_tmb.jl`, `fisherz_q4.jl` (#341)
- Docs: `HANDOVER.md`, `README.md`, `docs/design/capability-status.md`, `docs/dev-log/plans/registry-checklist-2026-08-01.md`, `LOOP/*` (#340/#342/#343)

## 7. Files in this DoD PR

- `docs/dev-log/check-log.d/2026-08-01-ayumi-main-s3-hygiene.md`
- `docs/dev-log/after-task/2026-08-01-registry-hygiene-s2-s3.md` (this file)

## 8. Rose audit (claim-vs-evidence)

| Claim | Verdict |
|---|---|
| ayumi integrated into main (Q1) | **PASS** — #340 MERGED @ `7df22b4` |
| Scoped S3 hygiene landed | **PASS** — #341+#342 MERGED; load silence + honesty docs |
| Package ready to Registrator-submit | **FAIL / blocked** — S4 needs Shinichi OK; version policy open; post-merge tip Julia CI not yet asserted here |
| Phase 1.5 / #5 done | **FAIL / out of scope** — R inventory blocked; keep experimental wording |
| Full #3 experimental wire done | **FAIL / out of scope** — Q2 scoped |
| Local Aqua + `Pkg.test` evidence exists | **PASS** — cited LOG paths |
| #340 CI green | **PASS** — both Julia versions + Documenter |
| #341/#342 Julia CI green | **NOT CLAIMED** — pending at write time |

## 9. Next

1. Watch #341/#342/#343 (or `main` @ `e7261d9`) Julia CI to completion; re-verify Aqua/`Pkg.test` on tip if needed.
2. **S4 Registrator** — only after explicit Shinichi OK + version/tag decision.
3. **S5 / #5** — Hopper finish-matrix when drmTMB lane is free (separate twin PR; not this repo alone).

## 10. Issue ledger

No issue closed by this DoD-only PR. Tracker context: #8 (registry) still open until S4; #3 remains open under scoped reading; #5 open / R-blocked; #136/#291 deferred.
