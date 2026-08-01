# Rose claim-vs-evidence — registry readiness (`origin/main`)

**Role:** Rose (read-only claim-vs-evidence). Shannon speaking; **no spawned subagents**.
**Scope:** DRM.jl only. No Registrator submit. No drmTMB inventory.
**Audited tip:** `origin/main` @ `e7261d98472ecc006a3dbb8fe1a685253592315f`
(`Merge pull request #343` — post-merge checkpoint after #340/#341/#342).
**Date:** 2026-08-01.

---

## Verdict

**Not registered; not Registrator-ready to claim “shipped to General.”**

Public surfaces correctly **deny** General-registry membership and correctly keep
**Phase 1.5 / #5** open. Registry **hygiene slices S2+S3 have already landed**
on this tip (#340 integrate, #341 load-banner silence, #342 docs honesty), so
README/HANDOVER **“Next = after #340 then S3”** is **stale relative to the tip**.
Remaining honest blockers for S4 are: (1) explicit Shinichi OK for Registrator,
(2) version/tag/`CITATION.cff` policy, (3) tip Aqua/`Pkg.test` re-verify after
the three merges (pre-merge evidence exists; post-merge tip CI for `CI.yml` does
not auto-run on `push` to `main`).

| Gate | Tip evidence | Rose call |
|---|---|---|
| Claimed as in Julia General? | README: “does **not** claim General-registry membership”; GitHub API `JuliaRegistries/General/contents/D/DRM` → **404**; no local `~/.julia/registries/General/D/DRM` | **PASS** (no false “registered”) |
| Registrator submitted from this tip? | Ultra-plan + HANDOVER fence: S4 only with Shinichi OK; this audit does not submit | **PASS** (fence held) |
| `Project.toml` version / metadata | `name = "DRM"`, `uuid = 6c755ef2-…`, `version = "0.1.0"`, `[compat]` for deps + `julia = "1.10"` | **PASS** (metadata present) |
| Version / tag honesty | Tags `v0.1.0` + `v0.1.1` exist; tree `Project.toml` + `CITATION.cff` still `0.1.0`; README/HANDOVER disclose drift | **PASS** (disclosed) / **OPEN** (S4 policy) |
| Install surface | README “Install (**development**)” via `Pkg.develop(path=…)` only — no `Pkg.add("DRM")` from General | **PASS** |
| S2 integrate #340 | **MERGED** 2026-08-01T14:05:23Z | **DONE** (docs still say “after #340 merges”) |
| S3 load-banner silence #341 | **MERGED**; `fit_q4_sparse_tmb.jl` / `fisherz_q4.jl` banners absent on tip | **DONE** |
| S3 docs honesty #342 | **MERGED**, but “Next” text still pre-S2 wording | **PARTIAL** — honesty on bridge/registry membership OK; **Next stanza stale** |
| Aqua wired | `test/test_aqua.jl` + `runtests.jl` include; `deps_compat=true`, `ambiguities=false` (documented) | **PASS** (wired) |
| Tip green `Pkg.test` / Aqua | LOOP checkpoint: pre-merge #341 tip PASS; tip verify after merges called out as remaining; `CI.yml` is PR/`workflow_dispatch` only (no push-to-main) | **UNVERIFIED on `e7261d9`** this audit |
| Documenter on tip | Actions run on `e7261d9` → Documenter **success** | **PASS** (docs build) |
| Bridge oversell? | README/HANDOVER: Julia `drm_bridge*` in-tree; **#5 / Phase 1.5 open** — not bridge-done | **PASS** (top surfaces) |
| Experimental oversell? | README/HANDOVER: remaining `experimental/` not fully wired — correct for leftover prototypes; see drift findings below | **PASS** intent / **FAIL** some stale “reml/location_only still unwired” lines elsewhere |

**S4 Registrator:** still an **open human gate**. Do not submit from this audit.

---

## Claims audited (with evidence)

### 1. Registry membership / Registrator

| Claim (paraphrase) | Where | Evidence | Verdict |
|---|---|---|---|
| Not a General-registry member | `README.md` Status | Explicit negation; General `D/DRM` 404 | **Supported** |
| Next = after #340, then SCOPED S3, then Registrator w/ OK | `README.md`, `HANDOVER.md` TL;DR + §7 | #340/#341/#342 **already merged** into tip `e7261d9`; LOOP checkpoint says S2+S3 done, Next = tip verify + S4 | **Stale “Next”** — membership/Registrator fence still honest |
| Register at v0.1.0 milestone | `ROADMAP.md` `### v0.1.0` | Aspirational (“Then register…”); tags exist while General absent | **Aspirational OK** if not read as “registered” |
| Grace owns General registry | `AGENTS.md` | Role text only | **N/A** (not a product claim) |

### 2. Version surfaces

| Surface | Value at tip | Note |
|---|---|---|
| `Project.toml` `version` | `0.1.0` | Register-as-is vs bump is S4 |
| `CITATION.cff` `version` | `0.1.0` | Matches Project.toml |
| Git tags | `v0.1.0`, `v0.1.1` | Drift disclosed in README/HANDOVER |
| README eyebrow | “Early **v0.1.0** release” | Consistent with tree version; does not assert `0.1.1` tree |

### 3. Bridge (`engine = "julia"` / Phase 1.5)

| Claim | Where | Evidence | Verdict |
|---|---|---|---|
| Julia helpers in-tree; Phase 1.5 / #5 **open** | `README.md`, `HANDOVER.md` | `src/bridge.jl` included; `drm_bridge` / `drm_bridge_inference` exported; issue **#5 OPEN** | **Supported** |
| Documenter bridge page = experimental first slice | `docs/src/r-julia-bridge.md` | Status note; admits limited Gaussian / narrow q2 cells; R glue in drmTMB repo | **Supported** (scoped) |
| Index: “**planned** R↔Julia bridge” | `docs/src/index.md` | Mild tension with in-tree `drm_bridge` + “experimental first slice” page | **Soft drift** — not a “bridge shipped” overclaim |
| Capability matrix: `R to Julia bridge (engine=julia)` = **implemented** | `docs/design/capability-status.md` | Explains Julia `drm_bridge*` + tests; does **not** claim drmTMB R round-trip done | **Supported if read carefully**; easy to overread as Phase 1.5 closed — prefer README/#5 wording for registry PR copy |
| Capabilities page: R-side glue **Absent here** | `docs/src/capabilities.md` | Explicit out-of-scope for R package glue | **Supported** (clearest fence) |

### 4. Experimental / REML / promotions

| Claim | Where | Evidence | Verdict |
|---|---|---|---|
| Remaining `src/experimental/` **not fully wired** | `README.md`, `HANDOVER.md` | Tree still has EM/estep/`fit_em_natgrad`/dense prototypes; **not** in `src/DRM.jl` include list | **Supported** |
| Public opt-in REML = `method = :REML` | `HANDOVER.md`, `src/DRM.jl` | `include("reml_q4.jl")` from **`src/reml_q4.jl`** (not under `experimental/`) | **Supported** |
| “experimental `reml_q4` path” still in experimental | `HANDOVER.md` TL;DR wording | **No** `src/experimental/reml_q4.jl` on tip; only `src/reml_q4.jl` | **Stale naming** |
| `reml_q4` / `location_only` **still in experimental/, not wired** | `ROADMAP.md` Phase 1.0 | Both live under `src/` and are `include`d (`reml_q4.jl`, `location_only.jl`); `experimental/location_only.jl` is a leftover copy | **Unsupported / drift** |
| Module docstring: location-only / EM “live in `experimental/` and are not yet wired” | `src/DRM.jl` header | `location_only.jl` **is** included from `src/`; EM prototypes remain experimental | **Partial fail** (location-only promoted; EM claim OK) |

### 5. Speed / engine headlines (registry-adjacent honesty)

| Claim | Where | Evidence pointer | Verdict |
|---|---|---|---|
| 2.18× / logLik ≈ −256.51 / O(p) to p=10k | `README.md`, `HANDOVER.md` | Anchored to `report/comparison-grid.md` + bench scripts; HANDOVER still refuses extrapolated “~12× at p=10k” | **Supported** (prior verified bar; not re-run this audit) |

---

## Drift / fix-before-Registrator (docs only unless noted)

Priority for a **follow-up docs PR** (not this audit’s job beyond naming them):

1. **Refresh README/HANDOVER “Next (registry)”** — S2+S3 merged; Next = tip Aqua/`Pkg.test` confirm + **S4 Registrator only with Shinichi OK** + version/tag decision. Stop saying “after #340 merges.”
2. **ROADMAP Phase 1.0** — mark `reml_q4` + conjugate `location_only` / `algorithm = :em` as promoted; keep `fit_em_natgrad` / leftover `experimental/` as open.
3. **`src/DRM.jl` module docstring** — stop saying location-only is unwired experimental.
4. **Align index “planned bridge”** with `r-julia-bridge.md` “experimental first slice” + #5 open (one sentence).
5. **capability-status bridge row** — optional qualifier “Julia marshalling surface; Phase 1.5 R finish = #5” to prevent registry-copy overread.

Non-docs (out of this PR): tip `Pkg.test`/Aqua re-verify on `e7261d9` if not already logged; S4 version policy; Registrator **only** with OK.

---

## What this audit does **not** do

- Does **not** run Registrator or open a General registry PR.
- Does **not** inventory or change drmTMB.
- Does **not** re-run the full ADEMP / parity / p=10k battery (engine numbers treated as previously verified).
- Does **not** bump `Project.toml` / tags.

---

## Evidence commands (reproducible)

```bash
git fetch origin main
git rev-parse origin/main   # expect e7261d9…
gh pr view 340 --json state,mergedAt
gh pr view 341 --json state,mergedAt
gh pr view 342 --json state,mergedAt
gh api repos/JuliaRegistries/General/contents/D/DRM   # expect 404
git show origin/main:Project.toml | head -40
git show origin/main:README.md | sed -n '/Status — honest/,+50p'
git ls-tree --name-only origin/main:src/experimental
git show origin/main:src/DRM.jl | rg -n 'experimental|reml_q4|location_only|bridge'
```

---

## Rose closeout

| Question | Answer |
|---|---|
| Can copy say “DRM.jl is on the Julia General registry”? | **No.** |
| Can copy say “registry-ready / hygiene landed, Registrator gated”? | **Yes**, with tip-verify + Shinichi OK still explicit. |
| Can copy say “R `engine = \"julia\"` / Phase 1.5 shipped”? | **No** (#5 open). Julia `drm_bridge*` yes, scoped. |
| Can copy say “`experimental/` fully wired”? | **No.** |
| Claim-vs-evidence on membership / bridge top surfaces? | **Honest enough to not block reading the tip**; **stale Next + ROADMAP/module experimental lines** should be cleaned before Registrator PR text is drafted. |
