# 2026-08-16 — Arc 1 backlog refresh after #434 (docs only)

**Lane:** `docs-arc1-backlog-after-434` on `claude/lane-arc1-backlog-after-434`
in `~/local-scratch/lanes/DRM.jl-arc1-backlog-after-434`.
**Personas:** Shannon (conductor) · Ada · Rose · Hopper (mechanical count).
**Nested Task subagents:** [Rose](f3b00b68-52a2-4bd1-af25-53f01aa0c05c)
(morning ship-gate on PR #436).
**closes:** #435

Phrase: *refresh the Arc 1 backlog after #434; fixture banked; 11 rows
still unsigned.* `claim_status` stays **partial**. No TSV `supported`
flip. Does not name a new recommended implement. Does not claim
"R–Julia parity complete," interval reliability, coverage, AI-REML, or
R-via-Julia bridge admission.

## What landed

- Refresh of `docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md`
  (same path as #432; not a second inventory hunt)
- This after-task + check-log
  `docs/dev-log/check-log.d/2026-08-16-arc1-backlog-after-434.md`
- New LOOP/ kit for this G0 (not the #432 / #434 / catchup kits)
- plan-actual `docs/dev-log/plan-actual/2026-08-16-arc1-backlog-after-434.md`

## After #434 (facts, not a promotion)

#434 (`b73d9241`, closes #433) banked
`test/parity/q4-reml/biv-q4-phylo-reml/`. The #432 sentence "fixture
**NONE**" and "recommended first later implement = `biv_q4_phylo_reml`"
are false after that merge. This refresh deletes both.

Declared `[tol]`: `atol_loglik=6.0`, measured `d_loglik≈−5.63` (TMB
mean-only REML vs Julia mean+scale). Cite
`docs/dev-log/after-task/2026-08-16-biv-q4-phylo-reml-fixture.md`.
`julia_converged=false` is recorded, not sold.

## S3 Rose

**Verdict:** **clean-with-limitations.** Fence copied from the
planning-pass note `2026-08-16-next-after-biv-rose.md` and in-PR S5
`2026-08-16-biv-q4-s5-rose-fence.md`.

Sweep (this pass + morning [Rose](f3b00b68-52a2-4bd1-af25-53f01aa0c05c)):
stale **NONE** gone; 11 IDs once; `claim_status` still `partial` in
prose; no new recommended implement; no "parity complete"; no TSV /
`src/` / `runtests.jl` / `capability-status.md` edit; `#136` not
closed; `#49` not unparked; `#428` not stolen; `atol_loglik=6.0` not
treated as a `src/` defect. Honesty fix: wait-gate is `#423`+`#428`
(`#425` merged).

Limitation: no `parity_ledger.py` re-run; no `Pkg.test`. COUNTDOWN 0
is **UNVERIFIED** as a fresh script after `b73d9241`.

## S4 mechanical

See the S4 table in the refreshed backlog. Verify commands in the
check-log row.

## What this did NOT cover

The other 10 unsigned rows as implement cells. TSV `supported`.
`runtests.jl` include (WAIT `#423` `#428`; `#425` merged). `src/`. Workflow G
harness. Interval coverage / reliability. AI-REML. R-via-Julia bridge
admission. `#428` / `#136` / `#49`. A new recommended implement.
D-111 / Registrator. drmTMB checkout.
