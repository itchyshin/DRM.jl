GOAL: see GOAL.md.   STATE: Tip verify PASS @ `e7261d9`; **S4 submitted** (0.1.2 bump merged, tag pushed, `@JuliaRegistrator register` posted). Watching AutoMerge — do **NOT** claim registered until `JuliaRegistries/General` merges `D/DRM`. S5 Hopper #5 bar **evidenced** (Rose PASS); #349 rebasing onto main / awaiting CI.

ARCS DONE (verified):
- S0 RECON — checklist at `docs/dev-log/plans/registry-checklist-2026-08-01.md`
- S1 Merge #339 — MERGED @ `7cb868d`
- S2 ayumi→main integrate — MERGED PR #340
- S3 scoped hygiene — MERGED PR #341 (load-print silence) + #342 (docs honesty) + #343 (checkpoint)
- Docs prep / DoD / Rose / tip-verify LOOP — MERGED #344 #345 #347 #348 #350
- **Tip verify (2026-08-01, Totoro CPU, Julia 1.12.6)** on `e7261d9`: Aqua **10/10**; full `Pkg.test` **PASS** (~4726 Pass / 0 Fail / 3 Broken VA scaffold)
- **S4 version bump** — MERGED PR #346 @ `651c96c` (`Project.toml` / `CITATION.cff` / NEWS → **0.1.2**)
- **S4 tag** — annotated `v0.1.2` → `651c96c` (pushed to origin)
- **S4 Registrator comment** — `@JuliaRegistrator register` on merge commit + PR #346 thread
- S4 submitted checkpoint — MERGED #351
- S5 Hopper finish matrix (paired) — DRM.jl #349 open (rebase onto `origin/main`); drmTMB #878 open (ASCII fix; wait green). Rose PASS @ `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md`

ARC IN PROGRESS: Finish #349 rebase + CI green, then merge; watch JuliaRegistrator / AutoMerge (do NOT claim registered). drmTMB #878 only after re-check green.

NEXT:
1. Merge DRM.jl #349 when CI green; close #5 after twin lands (experimental bar)
2. drmTMB #878 — merge only when ubuntu R-CMD-check green post-ASCII fix
3. Confirm JuliaRegistrator reply + `JuliaRegistries/General` PR for `DRM` 0.1.2; watch AutoMerge — do NOT claim registered until General merges
4. Do not dump AGENTS fence commits

OPEN GATES (need human):
- **Install / authorize JuliaRegistrator** on `itchyshin/DRM.jl` if the bot stays silent (click: https://github.com/apps/julia-registrator)
- Do not claim “registered” until General merges
- Do not dump AGENTS fence commits

COMPUTE (ask before heavy runs):
- Totoro: CPU only — tip verify done
- DRAC: GPU / large arrays
- Local Mac: smoke OK

TRUTH LIVES IN:
- LOOP/GOAL.md (Q2 SCOPED; Q3 S5 evidenced)
- `origin/main` @ `5f782fa` (Merge #351; S4 submitted checkpoint; version 0.1.2)
- tag `v0.1.2` → `651c96c`
- Registrator comment: https://github.com/itchyshin/DRM.jl/commit/651c96c6b94f39c380eb7954fd8800ceb31bd17e#commitcomment-194611869
- Rose verdict `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md`
- Paired matrix `docs/dev-log/plans/bridge-finish-matrix-2026-08-01.md`
- Totoro tip-verify logs under `/tmp/drm-pkg-test-logs/` + totoro scratch
- `docs/dev-log/plans/registrator-prep-2026-08-01.md`

RESUME:
```
You are DRM.jl registry→bridge lane — running LOOP goal. RESUME.
READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md → AGENTS.md.
WORKSPACE: origin/main @ 5f782fa (v0.1.2; S4 submitted, not registered).
CONTINUE FROM: S5 Rose PASS; finish #349 rebase/CI; watch AutoMerge / JuliaRegistrator reply; do NOT claim registered; do NOT dump AGENTS. Q2=SCOPED. DEFER #136 #291 #13.
Pause at: General membership claim; human Registrator app install if bot silent; public claims beyond experimental.
```
