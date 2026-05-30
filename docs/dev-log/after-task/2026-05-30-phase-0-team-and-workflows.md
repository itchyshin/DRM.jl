# After-task — Phase 0: team, scripted workflows, ledger, Documenter shell

**Date:** 2026-05-30 · **Branch:** `phase-0-team-workflows` · **Voice:** Shannon
(coordination). No subagents persistently running; the W0 audit + A smoke-run
were one-shot workflow runs.

## What landed

- **Team:** `AGENTS.md` (12 personas + skills map + lanes + Definition of Done +
  the formula-parity / R-bridge / license contracts), extended `CLAUDE.md`,
  `ROADMAP.md`. 12 `.codex/agents/*.toml`.
- **Workflows:** 10 scripted `.claude/workflows/*.js` (W0, Q, A, B, D, F, G, H,
  S, R). W0/F/S/Q have runnable bodies; A/B/G/H/R are structurally-complete
  scaffolds that return their slice plan until their phase opens.
- **Ledger:** 21 custom labels, 8 milestones (Phase 0 → v1.0), 18 near-term
  issues (#2–#19) — roadmap trackers + wire-experimental + Q-gates + 2 design
  issues. Article/family slices live as checklists in the roadmap issues
  (promoted by Workflow D/H). Issue + PR templates; `labels.yml`;
  `tools/bootstrap-issues.jl`.
- **Memory / dev-log:** `docs/dev-log/{check-log,coordination-board,after-task,
  decisions,recovery-checkpoints,scout}` + `tools/drm-checkpoint.jl`.
- **Documenter shell:** `docs/make.jl` + 36 status-tagged pages mirroring
  drmTMB's pkgdown navbar (5 dropdowns + Reference ×6 + Rosetta + R-bridge +
  changelog). `docs/make_stubs.jl` (skip-if-exists generator).
- **Project meta:** `bench/Project.toml`, `CITATION.cff`, `.JuliaFormatter.toml`,
  `NEWS.md`, `.github/workflows/{Documenter,TagBot}.yml`.
- **Cross-package proposals filed:** [GLLVM.jl#15](https://github.com/itchyshin/GLLVM.jl/issues/15)
  (full better-team pattern) and [gllvmTMB#324](https://github.com/itchyshin/gllvmTMB/issues/324)
  (Pólya scout only — it already has a ledger).

## Verification (evidence, not assertion)

| Gate | Result |
|---|---|
| `using DRM` loads | ✅ loads cleanly (`Pkg.instantiate` + `using DRM` → "DRM loaded OK") |
| Documenter site builds | ✅ `julia --project=docs docs/make.jl` rendered all 36 pages (warnonly; 14 engine docstrings not yet in `@docs` blocks — expected for stubs; deploy skipped locally) |
| Workflow-script format | ✅ A smoke-run returned its scaffold object (0 agents, 2 ms) |
| W0 scaffold audit | ✅ independent Explore run (Rose lens): **27/27 required items present, none missing** |
| GitHub ledger | ✅ 8 milestones + 18 issues live; labels applied |
| Headline bench (logLik −256.51) | ⏭️ **NOT re-run this session.** `bench/run_sparse_tmb_nd.jl` has a stale poc include (`include("fit_q4_sparse_tmb.jl")` → now in `src/`) — the documented HANDOVER §11 caveat; `bench/run_*.jl` is out of scope for Phase 0 (Curie audits it in Phase 1.0). The engine is unchanged this phase, so the verified number stands; we did **not** reproduce it here. |

## Discrepancies found & corrected (verify-before-claiming wins)

1. **Load-time print exists.** The Phase-0 inventory claimed "no println on
   load"; verification showed `sparse_aug_plsm.jl` prints
   `=== sparse_aug_plsm.jl loaded ===` during load. HANDOVER's original claim was
   right. Corrected HANDOVER; flagged the print for removal in Phase 1.0
   (Workflow A comment). **Did not touch `src/`** otherwise.
2. **`meta_known_V` → `meta_V`.** drmTMB v0.1.3 makes `meta_V()` current and
   `meta_known_V()` deprecated (solo read of the pkgdown). Fixed in CLAUDE.md +
   Boole's contract. (Pre-existing issue #1 — "Reconcile meta_V()/meta_known_V()
   parity wording" — is in Boole's formula-parity lane; left untouched.)
3. **"digital twin" → "twin"** across all identity-bearing files (maintainer:
   both are software). Left `report/plan-and-timings.md` as historical provenance.

## Per-persona verdict

- **Ada:** scaffold complete and internally consistent; phases + gates in
  `ROADMAP.md` mirror the milestones. Engine untouched.
- **Rose (claim-vs-evidence):** no overselling — the headline bench is marked
  *not re-run*, not "passing"; the load-time print is documented, not hidden;
  Documenter stubs carry honest status tags. License boundary intact (no drmTMB
  GPL source vendored; the R-parity scaffold uses generated outputs only).
- **Karpinski (no-regression):** `src/` unchanged except one docstring word
  (`digital twin`→`twin`); engine loads; no logic touched.
- **Pólya:** scout snapshot dir seeded; cross-package proposals filed so the
  reciprocal scouting can start.

## Manifest policy (note for Grace, Phase 1.0)

Root `Manifest.toml` and `docs/Manifest.toml` are git-ignored: the root is a
library (never pin), and the docs/bench envs dev `DRM` via a machine-specific
absolute path (not portable). Phase 1.0 pins **portable** docs/+bench Manifests
via a relative dev path.

## Next (Phase 1.0 — see milestone)

Workflow A wires `src/experimental/` (#10–#13) and removes the stray print;
Workflow D fills the easy Get-Started pages; Workflow Q completes the FD/Allocs/
multi-shape gates (#14–#16); the bench runners get their path fix (Curie). Open
design issues: the public verb (#18) and tree/R-object marshalling (#19).
