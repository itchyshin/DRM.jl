GOAL: see GOAL.md.   STATE: S2–S3 + tip verify PASS (@ `e7261d9`); Rose docs #347/#348 + tip-verify #350 MERGED; S4 draft bump #346 → `0.1.2` on main (still no Registrator submit). S5 Hopper #5 bar **evidenced** (Rose PASS) and **landed**: DRM.jl #349 MERGED @ `d296703`; drmTMB #878 MERGED @ `fb59cd3`. Issue #5 CLOSED. NEXT = S4 Registrator / AutoMerge OPEN GATE (needs explicit Shinichi OK — do not submit).

ARCS DONE (verified):
- S0 RECON — checklist at `docs/dev-log/plans/registry-checklist-2026-08-01.md`
- S1 Merge #339 — MERGED @ `7cb868d`
- S2 ayumi→main integrate — MERGED PR #340 @ `7df22b4`
- S3 scoped hygiene — MERGED PR #341 @ `50faf6d`
- S3 docs honesty — MERGED PR #342 @ `74f30a8`
- Post-merge checkpoint / tip verify — MERGED #343 @ `e7261d9` (Totoro Aqua 10/10 + full `Pkg.test` PASS)
- Rose registry claim audit — MERGED #347
- Rose tip claim-drift fix — MERGED #348
- Tip-verify checkpoint — MERGED #350
- S4 draft version bump — MERGED #346 (`0.1.2`; Registrator still gated)
- S5 Hopper finish matrix — MERGED DRM.jl #349 + drmTMB #878; Rose PASS @ `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md`; #5 CLOSED

ARC IN PROGRESS: none on S5. Waiting Registrator AutoMerge separately.

NEXT:
1. S4 Registrator / AutoMerge — **waiting separately**; only with explicit Shinichi OK
2. Optional: align uni `r_bridge_status=supported` vs `claim_status=partial` (Rose nit, non-blocking)

OPEN GATES (need human):
- **S4 Registrator submit / AutoMerge — do not submit without explicit OK**
- Do not dump AGENTS fence commits

COMPUTE (ask before heavy runs):
- Totoro: CPU only — used for tip verify
- DRAC: GPU / large arrays
- Local Mac: smoke OK

TRUTH LIVES IN:
- LOOP/GOAL.md (Q2 SCOPED; Q3 S5 evidenced + landed)
- Rose verdict `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md`
- Paired matrix `docs/dev-log/plans/bridge-finish-matrix-2026-08-01.md`
- `origin/main` @ `d296703` (Merge #349)
- `docs/dev-log/plans/registry-checklist-2026-08-01.md`

RESUME:
```
You are DRM.jl registry→bridge lane — running LOOP goal. RESUME.
READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md → AGENTS.md.
CONTINUE FROM: S5 MERGED (#349 + drmTMB #878); #5 closed; do NOT Registrator; do NOT dump AGENTS. Q2=SCOPED. DEFER #136 #291 #13.
Pause at: S4 Registrator / AutoMerge; public claims beyond experimental.
```
