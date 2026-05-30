# check-log.md — DRM.jl gate status

Canonical per-slice gating status. One row per slice; cite the issue, the
verification command, and the result. This is a **shared resource** — check PR
overlap before editing. See `AGENTS.md` → *Definition of Done*.

| Date | Slice / Issue | Gate run | Result | By |
|---|---|---|---|---|
| 2026-05-30 | Phase 0 scaffold (#2) | `using DRM` load | ✅ loads ("DRM loaded OK"); found a stray load-time print in `sparse_aug_plsm.jl` (→ Phase 1.0) | Shannon |
| 2026-05-30 | Phase 0 scaffold (#2) | `Pkg.test()` | ✅ 13/13 pass (engine loads + phylo foundation) | Shannon |
| 2026-05-30 | Phase 0 scaffold (#2) | `julia --project=docs docs/make.jl` | ✅ 36 pages render (warnonly; 14 docstrings not yet in `@docs`) | Shannon |
| 2026-05-30 | Phase 0 scaffold (#2) | Workflow A + W0 smoke-run | ✅ script format valid; scaffold present | Shannon |
| 2026-05-30 | Phase 0 scaffold (#2) | headline bench logLik −256.51 | ⏭️ NOT re-run — `bench/run_*.jl` needs the Phase-1.0 path fix (HANDOVER §11); engine unchanged so verified number stands | Shannon |
| 2026-05-30 | Slice 1: Gaussian loc-scale (#18) | `Pkg.test()` + docs build | ✅ 17/17 (13 engine + 4 Gaussian recovery); docs `@example` blocks execute, no error markers | Shannon |
