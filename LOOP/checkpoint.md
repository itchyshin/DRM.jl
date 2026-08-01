GOAL: see GOAL.md.   STATE: Tip verify PASS @ `e7261d9`; version **0.1.2** + tag `v0.1.2` @ `651c96c` exist as git artifacts. **S4 General = OUT (brain D-111)** — stay off Julia General until R twin catch-up + both working well; drmTMB likely CRAN first. Do NOT Registrator. Next = Phase 1.5 closeout (#349 / Rose #5) + tip hygiene / parity only.

ARCS DONE (verified):
- S0 RECON — checklist at `docs/dev-log/plans/registry-checklist-2026-08-01.md`
- S1 Merge #339 — MERGED @ `7cb868d`
- S2 ayumi→main integrate — MERGED PR #340
- S3 scoped hygiene — MERGED PR #341 (load-print silence) + #342 (docs honesty) + #343 (checkpoint)
- Docs prep / DoD / Rose / tip-verify LOOP — MERGED #344 #345 #347 #348 #350
- **Tip verify (2026-08-01, Totoro CPU, Julia 1.12.6)** on `e7261d9`: Aqua **10/10**; full `Pkg.test` **PASS** (~4726 Pass / 0 Fail / 3 Broken VA scaffold)
- Version bump — MERGED PR #346 @ `651c96c` (`Project.toml` / `CITATION.cff` / NEWS → **0.1.2**)
- Annotated tag `v0.1.2` → `651c96c` (pushed; may remain as a git tag)
- S4 submitted checkpoint #351 — MERGED (historical; superseded by General-out-of-scope correction)

ARC CANCELLED:
- **S4 General registration** — OUT OF SCOPE (**D-111**). Readiness bar: catch up with drmTMB + both working well; probably drmTMB R/CRAN first. Prior `@JuliaRegistrator register` on #346 is **not** to be followed up. No `D/DRM` in General (2026-08-01). If a General PR appears later, report URL — do **not** merge.

ARC IN PROGRESS: Phase 1.5 / #5 Julia-side finish matrix — PR #349; tip claim hygiene so HANDOVER/README/Mission Control no longer treat General as Next.

NEXT:
1. Finish / merge DRM.jl #349 when CI green; Rose #5 closeout (experimental bar)
2. Tip hygiene — HANDOVER/README/LOOP already corrected on this branch; keep Mission Control `next_safe_action` off Registrator
3. Do not dump AGENTS fence commits
4. Do not pursue JuliaRegistrator / General

OPEN GATES (need human):
- None for Registrator (cancelled — do **not** ask for app install)
- Do not dump AGENTS fence commits
- Public claims stay experimental for bridge

COMPUTE (ask before heavy runs):
- Totoro: CPU only — tip verify done
- DRAC: GPU / large arrays
- Local Mac: smoke OK

TRUTH LIVES IN:
- LOOP/GOAL.md (General out of scope; Q2 SCOPED)
- `origin/main` @ `5f782fa` (Merge #351; version 0.1.2)
- tag `v0.1.2` → `651c96c` (git tag only — **not** General membership)
- Totoro tip-verify logs under `/tmp/drm-pkg-test-logs/` + totoro scratch
- Historical prep only: `docs/dev-log/plans/registrator-prep-2026-08-01.md` (superseded for General)

RESUME:
```
You are DRM.jl Phase 1.5 bridge closeout lane — running LOOP goal. RESUME.
READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md → AGENTS.md.
WORKSPACE: origin/main @ 5f782fa (v0.1.2 git tag; General NOT in scope).
CONTINUE FROM: S4 CANCELLED; finish #349 / Rose #5 closeout + tip hygiene; do NOT Registrator; do NOT dump AGENTS. Q2=SCOPED. DEFER #136 #291 #13.
Pause at: public claims beyond experimental; any surprise General PR (report URL, do not merge).
```
