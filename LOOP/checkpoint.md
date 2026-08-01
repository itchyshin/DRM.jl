GOAL: see GOAL.md.   STATE: Tip verify PASS @ `e7261d9`; version **0.1.2** + tag `v0.1.2` @ `651c96c` exist as git artifacts. **S4 General = OUT (brain D-111)** — stay off Julia General until R twin catch-up + both working well; drmTMB likely CRAN first. Do NOT Registrator. **#349 MERGED** @ `d296703` (S5 Hopper matrix + Rose PASS on Julia side). Next = tip hygiene / twin closeout (#5 experimental bar; drmTMB #878 if still open) — **not** General.

ARCS DONE (verified):
- S0 RECON — checklist at `docs/dev-log/plans/registry-checklist-2026-08-01.md`
- S1 Merge #339 — MERGED @ `7cb868d`
- S2 ayumi→main integrate — MERGED PR #340
- S3 scoped hygiene — MERGED PR #341 (load-print silence) + #342 (docs honesty) + #343 (checkpoint)
- Docs prep / DoD / Rose / tip-verify LOOP — MERGED #344 #345 #347 #348 #350
- **Tip verify (2026-08-01, Totoro CPU, Julia 1.12.6)** on `e7261d9`: Aqua **10/10**; full `Pkg.test` **PASS** (~4726 Pass / 0 Fail / 3 Broken VA scaffold)
- Version bump — MERGED PR #346 @ `651c96c` (`Project.toml` / `CITATION.cff` / NEWS → **0.1.2**)
- Annotated tag `v0.1.2` → `651c96c` (pushed; may remain as a git tag)
- S4 submitted checkpoint #351 — MERGED (historical; superseded by General-out-of-scope / D-111)
- **S5 Hopper finish matrix (Julia side)** — MERGED PR #349 @ `d296703`; Rose PASS @ `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md`

ARC CANCELLED:
- **S4 General registration** — OUT OF SCOPE (**D-111**). Readiness bar: catch up with drmTMB + both working well; probably drmTMB R/CRAN first. Prior `@JuliaRegistrator register` on #346 is **not** to be followed up. No `D/DRM` in General (2026-08-01). If a General PR appears later, report URL — do **not** merge.

ARC IN PROGRESS: Tip claim hygiene (this PR #352) so HANDOVER/README/Mission Control stay off General; twin #5 closeout if drmTMB #878 still open (experimental bar only).

NEXT:
1. Land docs PR #352 (D-111 fence) when CI green
2. drmTMB #878 — merge only when green (bridge-only; experimental wording)
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
- LOOP/GOAL.md (General out of scope / D-111; Q2 SCOPED)
- `origin/main` @ `d296703` (Merge #349; version 0.1.2)
- tag `v0.1.2` → `651c96c` (git tag only — **not** General membership)
- Rose verdict `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md`
- Paired matrix `docs/dev-log/plans/bridge-finish-matrix-2026-08-01.md`
- Totoro tip-verify logs under `/tmp/drm-pkg-test-logs/` + totoro scratch
- Historical prep only: `docs/dev-log/plans/registrator-prep-2026-08-01.md` (superseded for General)

RESUME:
```
You are DRM.jl Phase 1.5 bridge closeout lane — running LOOP goal. RESUME.
READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md → AGENTS.md.
WORKSPACE: origin/main @ d296703 (v0.1.2 git tag; #349 merged; General NOT in scope / D-111).
CONTINUE FROM: S4 CANCELLED; #349 merged; land #352 tip hygiene; twin #878 if open; do NOT Registrator; do NOT dump AGENTS. Q2=SCOPED. DEFER #136 #291 #13.
Pause at: public claims beyond experimental; any surprise General PR (report URL, do not merge).
```
