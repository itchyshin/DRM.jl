GOAL: see GOAL.md.   STATE: lane repaired and healthy; starting A3c-2.

ARCS DONE (verified):
- A-fix — `biv_student` recovery tolerance. Verified by REPRODUCING the CI failure on Julia 1.12
  locally (|dev| for log(nu-2) = 0.5198 vs the old atol 0.25), then 4 suites green on 1.12 AND 1.10.
  Landed on #410's branch; that PR has auto-merge armed.
- LANE REPAIR (this session, not a planned arc) — the lane was scaffolded from `main` @ 3638ba28,
  which PREDATES A3a/A3b/A3c-1 and the QuadGK dep, so `src/associate_pairs.jl` was absent and A3c-2
  could not have started. Rebased `claude/lane-catchup` onto `docs/a3c-design` (the campaign tip,
  9f7a1484). VERIFIED BY ARTEFACT, not exit code: associate_pairs.jl 259 lines, bivariate_student.jl
  164, bivariate_lognormal.jl 129, vcov_guard.jl 69, QuadGK in [deps] and [compat], and 3 suites
  pass in the lane.

ARC IN PROGRESS: **A3c-2** — four quadrature pair classes via QuadGK.
  How to tell it landed: `test_associate_pairs.jl` covers gaussian_nbinom2, bernoulli_bernoulli,
  bernoulli_nbinom2, nbinom2_nbinom2 with per-row integration-error diagnostics, AND
  `tools/parity_fixture.R` gains passing cells for them vs installed drmTMB 0.7.0.

NEXT AFTER: A3c-3 (associate_pairs parity fixture + diagnostic parity).

OPEN GATES (need human):
- **A-sigma** — surface the `sigma()` public-contract design BEFORE landing.
- **A-drmtmb** — open the PR, NEVER merge (9 live lanes + open release slice #959 there).

BRANCH/PR STATE (important — two unmerged PRs stack under this lane):
- #410 `docs/a3-rescope-bivariate-nongaussian` — re-scope + A3a + A3b + A-fix. Auto-merge ARMED,
  CI running. NOT merged.
- `docs/a3c-design` — A3c design + A3c-1 + QuadGK + drmTMB 0.7.0 re-verification. **NO PR YET.**
- `claude/lane-catchup` — this lane, now rebased on top of `docs/a3c-design`.
  When #410 and the A3c-1 work merge, rebase this lane onto `origin/main`.

TRUTH LIVES IN:
- Lane worktree: /Users/z3437171/local-scratch/lanes/DRM.jl-catchup on `claude/lane-catchup`
- Ledger: `docs/dev-log/evidence/2026-08-14-drmtmb-parity-ledger.md`; countdown 22 gaps
- A3c design (the binding contract for this arc):
  `docs/dev-log/design/2026-08-15-a3c-design-staged-association.md`
- Anchor: drmTMB 0.7.0 INSTALLED. Julia 1.12 installed (`julia +1.12`) — reproduce
  version-specific failures rather than guessing.

RESUME:
You are the DRM.jl catch-up lane. This is a RESUME.
READ FIRST, IN ORDER: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/arcs.md -> ./AGENTS.md.
WORKSPACE: /Users/z3437171/local-scratch/lanes/DRM.jl-catchup (reattach; do NOT recreate).
Run the L2 arc-loop: re-read GOAL each arc; verify by LOG and artefact, never exit code;
one branch per arc; auto-merge armed only as the LAST action on a branch; pause at every OPEN GATE;
overwrite this checkpoint each arc.
CONTINUE FROM: A3c-2. Pause at: A-sigma (design gate) and A-drmtmb (never merge).
