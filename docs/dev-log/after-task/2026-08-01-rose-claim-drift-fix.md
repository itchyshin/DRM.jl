# After-task — Rose claim-drift fix (docs)

**Date:** 2026-08-01
**Role:** Shannon (docs fix); Rose perspective for claim honesty. **No spawned subagents.**
**Base:** `origin/main` @ `e7261d9` (independent of #346 version bump; can stack after or beside #347 audit).

## What changed

Rose audit (#347) found tip claim drift after S2/S3 landed. This PR fixes the
named fences only — **no Registrator**, no drmTMB, no version bump (#346 owns that).

1. **`ROADMAP.md`** — Phase 1.0 / “Where we are”: `reml_q4` + conjugate
   `location_only` marked promoted (`method = :REML`, `algorithm = :em`); remaining
   open experimental wiring is `fit_em_natgrad` / E-step / dense prototypes.
2. **`src/DRM.jl` module docstring** — stops saying location-only is unwired
   experimental; states public includes vs leftover `experimental/`.
3. **`README.md` / `HANDOVER.md` “Next”** — drop stale “after #340 / finish S3”;
   Next = watch **0.1.2 Registrator / AutoMerge** (other lane) + Phase 1.5 **#5**;
   explicitly **do not claim registered**. Experimental layout lines aligned with
   tip (no `experimental/reml_q4.jl`).

## Coordination

- **#346** (0.1.2 bump): untouched `Project.toml` / `NEWS.md` / `CITATION.cff`.
- **#347** (audit bank): independent; merge when CI green if desired.

## Rose verdict (this slice)

**PASS** for the named drift items. Still honest: not a General member; bridge
Phase 1.5 / #5 open; Registrator not submitted from this PR.
