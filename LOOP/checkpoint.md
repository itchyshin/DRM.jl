GOAL: see GOAL.md.   STATE: S2–S3 + tip verify PASS (@ `e7261d9`); Rose docs #347/#348 + tip-verify #350 MERGED; version **0.1.2** + tag `v0.1.2` @ `651c96c` (git artifacts only). **S4 General = OUT (brain D-111)** — stay off Julia General until R twin catch-up + both working well; drmTMB likely CRAN first; do NOT Registrator. **S5 landed:** DRM.jl #349 @ `d296703` + drmTMB #878 @ `fb59cd3`; Rose PASS; **#5 CLOSED**. NEXT = land tip-hygiene PR #352 + optional Rose nit — **not** General.

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
- Version bump — MERGED #346 (`0.1.2`; tag `v0.1.2` — **not** General membership)
- S4 submitted checkpoint #351 — MERGED (historical; superseded by D-111)
- S5 Hopper finish matrix — MERGED DRM.jl #349 + drmTMB #878; Rose PASS @ `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md`; #5 CLOSED

ARC CANCELLED:
- **S4 General registration** — OUT OF SCOPE (**D-111**). Readiness bar: catch up with drmTMB + both working well; probably drmTMB R/CRAN first. Prior `@JuliaRegistrator register` on #346 is **not** to be followed up. No `D/DRM` in General (2026-08-01). If a General PR appears later, report URL — do **not** merge.

ARC IN PROGRESS: tip claim hygiene (this PR #352) so HANDOVER/README/LOOP/Mission Control stay off General.

NEXT:
1. Merge docs PR #352 (D-111 fence) when CI green
2. Optional: align uni `r_bridge_status=supported` vs `claim_status=partial` (Rose nit, non-blocking)
3. Keep Mission Control `next_safe_action` off Registrator
4. Do not dump AGENTS fence commits; do not pursue JuliaRegistrator / General

OPEN GATES (need human):
- None for Registrator (cancelled — do **not** ask for app install)
- Do not dump AGENTS fence commits
- Public claims stay experimental for bridge

COMPUTE (ask before heavy runs):
- Totoro: CPU only — tip verify done
- DRAC: GPU / large arrays
- Local Mac: smoke OK

TRUTH LIVES IN:
- LOOP/GOAL.md (General out of scope / D-111; Q2 SCOPED; Q3 S5 landed)
- Rose verdict `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md`
- Paired matrix `docs/dev-log/plans/bridge-finish-matrix-2026-08-01.md`
- `origin/main` @ `3a18f72` (S5 landed checkpoint; version 0.1.2)
- tag `v0.1.2` → `651c96c` (git tag only — **not** General membership)
- Historical prep only: `docs/dev-log/plans/registrator-prep-2026-08-01.md` (superseded for General)

RESUME:
```
You are DRM.jl Phase 1.5 bridge closeout lane — running LOOP goal. RESUME.
READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md → AGENTS.md.
WORKSPACE: origin/main @ 3a18f72 (#349/#878 landed; #5 closed; General NOT in scope / D-111).
CONTINUE FROM: S5 MERGED; land #352 tip hygiene; do NOT Registrator; do NOT dump AGENTS. Q2=SCOPED. DEFER #136 #291 #13.
Pause at: public claims beyond experimental; any surprise General PR (report URL, do not merge).
```
