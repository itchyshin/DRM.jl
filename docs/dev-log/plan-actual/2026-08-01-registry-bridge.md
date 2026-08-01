# Plan vs actual — registry → Phase 1.5 bridge (2026-08-01)

Reconciler: **Melissa** (hub-only; not a DRM.jl `.cursor/agents/` persona).
Light pass — **material deviations only**, six axes. Source of truth: ultra-plan
`docs/dev-log/plans/2026-08-01-ultra-plan-registry-bridge.md` (+ `LOOP/ultra-plan.md`
copy) vs `LOOP/GOAL.md` overrides, git tip `origin/main` @ `81e02c7`, and closed
ledger (#5, #349, drmTMB #878, #352–#354). Cosmetic wording/ordering omitted.

## Verdict: **clean-with-adaptations.** No drift rows.

Two material deviations, both **adaptive** (owner-justified mid-arc). Zero
`drift` / `unclear`. **Melissa → Rose handoff:** nothing to promote to
[[PLAN-DRIFT-LEDGER]] this close (no unjustified gaps).

| # | Axis | Planned | Actual | Tag |
|---|------|---------|--------|-----|
| 1 | **Scope** | S4 = JuliaRegistrator / General submission after hygiene green | **S4 CANCELLED** (brain **D-111**, Shinichi 2026-08-01): stay off General until R twin catch-up + both halves working; drmTMB likely CRAN first. `v0.1.2` git tag may remain — not General membership | **adaptive** — explicit owner correction; GOAL.md overrides ultra-plan S4 |
| 2 | **Scope** | Q2 = **FULL** `#3` (wire remaining `experimental/` incl. `#13 fit_em_natgrad`) | Q2 = **SCOPED** hygiene only (`LOOP/GOAL.md` wins); `#13` / full experimental wire deferred | **adaptive** — GOAL override recorded before S3 ship; avoided swallowing the bridge arc |

## Clean on the other axes

- **Evidence / verification** — Hopper finish-matrix + Rose Phase 1.5 PASS on tip;
  local/Totoro Aqua + `Pkg.test` evidenced on hygiene path; no skipped planned
  gates for the *executed* scope (S4 not run because cancelled, not skipped).
- **Model routing** — Cursor/Claude (Shannon+Ada) held; no Registrator chase;
  Melissa hub-only as intended for S8.
- **Safety gates** — AGENTS fence commits (`a4585bd`…`66514a0`) stayed out;
  `#136` / `#291` DEFER held; MIT / no GPL vendoring held; engine baseline
  untouched (docs-only ship path).
- **Public claims** — bridge stays **experimental**; distribution honesty =
  MIT via GitHub / `Pkg.develop` (not General); Rose PASS for Phase 1.5 wording.
- **Handoff state** — tip hygiene #352 @ `6d73539`, Cursor agents #353 @
  `14cec07`, checkpoint #354 @ `81e02c7`; #5 CLOSED; Mission Control
  `next_safe_action` pointed off Registrator/General (idle / optional deeper
  parity — not a registry chase).

## Deferred — accounted for

| Fence | Status |
|---|---|
| `#136` VA/ELBO | honoured — not opened |
| `#291` REML speed | honoured — not opened |
| FULL `#3` / `#13` | deferred via Q2 SCOPED (adaptive) |
| JuliaRegistrator / General | cancelled via D-111 (adaptive) |
| AGENTS tip dumps | fenced — not dumped |

## Optional non-material residue (not a deviation)

Rose nit: uni `r_bridge_status=supported` vs `claim_status=partial` — noted in
`LOOP/checkpoint.md` as non-blocking; **skipped** this close (not a plan axis
failure).

## DECISION RECEIPT (D-67)

| ID | Planned question | Locked answer | Actual outcome |
|---|---|---|---|
| Q1 BASE | ayumi↔main before registry? | **A** — integrate before Registrator | Done (#340); Registrator later cancelled |
| Q2 #3 SCOPE | FULL vs SCOPED? | Plan table said FULL; **GOAL → SCOPED** | SCOPED hygiene shipped (#341–#343) |
| Q3 #5 bar | Hopper finish-matrix? | OK | #5 CLOSED (#349 + drmTMB #878); Rose PASS |
| S4 | Registrator after green? | Plan: yes after Shinichi OK | **CANCELLED** (D-111) |

> Related: after-tasks under `docs/dev-log/after-task/2026-08-01-*` ·
> `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md` · Melissa hub charter ·
> Rose (no PLAN-DRIFT-LEDGER promotion this close)
