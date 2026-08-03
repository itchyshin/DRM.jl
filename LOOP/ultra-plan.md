# Ultra-plan — DRM.jl #372: measured wall-clock for six #370 bridge cells

**Status:** G0 **APPROVED** 2026-08-03 (Shinichi). Frozen for `/goal` execution.
Canonical detail:
[`docs/dev-log/plans/2026-08-03-372-six-cell-measured-timing-ultra-plan.md`](../docs/dev-log/plans/2026-08-03-372-six-cell-measured-timing-ultra-plan.md)

**Issue:** https://github.com/itchyshin/DRM.jl/issues/372  
**Prior:** #370 arcs 0–4 complete; PR #371 may still be merging (external gate).

---

## 🎯 GOAL (binding)

```
SOLO PLATFORM: Cursor `/goal`.

DELIVERABLE: Close DRM.jl #372 — replace the six #370-bridge fixture cells'
"timing not measured — no claim" with a retained measured wall-clock artifact
(Julia drm_bridge and/or native drm vs local drmTMB on the same fixtures),
then update docs/src/r-julia-bridge.md claim surface to match the artifact
only; PR closes #372.

HEADLINE: Make the twin-mission speed story auditable for the six families
the bridge already admits — measured edge or honest no-claim with reason —
without inventing timings or re-using the q=4 2.18× cell.

DEFER: Lovelace R glue; D-111; :natgrad / AI-REML / #291; GPL vendoring;
q4 −256.51 / 2.18× regression; p>100 scaling; #202; #136; leave .worktrees/;
do not reopen #370 implementation.

DISCIPLINE: retained evidence + local re-read; local Julia + local drmTMB;
Rose: no "Nx faster" without artifact; record exact drmTMB version
(prefer v0.1.3, else installed version).
```

---

## Arc ladder

| Arc | Status | Gate | Budget | Deliverable |
|---|---|---|---:|---|
| 0 Probe + protocol | in progress | G0 yes | 30–45 min | Version + smoke + protocol stub |
| 1 Six-cell measure | pending | Arc 0 | 90–150 min | Retained timing artifact |
| 2 Docs + DoD + Rose | pending | Arc 1 | 45–75 min | Bridge docs match; DoD |
| 3 PR close | pending | Arc 2 | 30–45 min | PR `closes #372` |

---

## Fences (never cross)

D-111 · no GPL · no `:natgrad` · no q4 regression · leave `.worktrees/` ·
defer p>100 · no second #370 lane · no invented timings.
