GOAL: see GOAL.md.   STATE: lane opened at G0 approval; A-fix already landed; next arc is A3c-2.

ARCS DONE (verified):
- A-fix — `biv_student` recovery tolerance. Verified by REPRODUCING the CI failure on Julia 1.12
  locally (|dev| for log(nu-2) = 0.5198 vs the old atol 0.25), then re-running 4 suites green on
  BOTH 1.12 and 1.10. Landed on #410's branch; that PR has auto-merge armed.

ARC IN PROGRESS: none. NEXT = **A3c-2** (four quadrature pair classes via QuadGK).
  How to tell it landed: `tools/parity_fixture.R` gains passing cells for the new pair classes,
  and `test_associate_pairs.jl` covers each with per-row integration-error diagnostics.

OPEN GATES (need human):
- **A-sigma** — surface the `sigma()` public-contract design BEFORE landing.
- **A-drmtmb** — open the PR, NEVER merge (9 live lanes + open release slice #959 in that repo).

TRUTH LIVES IN:
- Lane worktree: /Users/z3437171/local-scratch/lanes/DRM.jl-catchup on `claude/lane-catchup`
- Upstream: DRM.jl `main`; PR #410 (re-scope + A3a + A3b + A-fix) auto-merge armed, CI running
- Ledger: `docs/dev-log/evidence/2026-08-14-drmtmb-parity-ledger.md`; countdown 22 gaps
- A3c design: `docs/dev-log/design/2026-08-15-a3c-design-staged-association.md`
- Anchor: drmTMB 0.7.0 INSTALLED. Julia 1.12 installed locally (`julia +1.12`) — use it to
  reproduce version-specific failures rather than guessing.

RESUME:
You are the DRM.jl catch-up lane. This is a RESUME.
READ FIRST, IN ORDER: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/arcs.md -> ./AGENTS.md.
WORKSPACE: /Users/z3437171/local-scratch/lanes/DRM.jl-catchup (reattach; do NOT recreate).
Run the L2 arc-loop: re-read GOAL each arc; verify by LOG and artefact, never exit code;
one branch per arc; auto-merge armed only as the LAST action on a branch; pause at every OPEN GATE;
overwrite this checkpoint each arc.
CONTINUE FROM: A3c-2. Pause at: A-sigma (design gate) and A-drmtmb (never merge).
