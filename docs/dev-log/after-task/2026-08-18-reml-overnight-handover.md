# 2026-08-18 — REML overnight handover (mean-re-reml)

**Lane:** `mean-re-reml` @ `~/local-scratch/lanes/DRM.jl-mean-re-reml` on `claude/lane-mean-re-reml`
**Platform:** Cursor Grok (Shannon `b7009689`). **HARD STOP:** not hit — PR merged first.
**Time:** 2026-08-17 20:02 America/Denver.

## Result

**PR [#440](https://github.com/itchyshin/DRM.jl/pull/440) MERGED** at 2026-08-18T01:57:00Z (`5e392c6e`). Issue **#439 CLOSED**.

CI on the merged tip: `test (1.10)` pass 36m34s · `test (1)` pass 1h0m32s · docs pass · scaling-sweep skipped.

## What landed

Opt-in `method = :REML` for Gaussian mean `(1 | g)` on the Woodbury spine.
ML stays default. B-card `rejected` → `implemented` after src+standalone test,
footnote **not in the default suite yet**. Documenter = **Impl, untested**.

## Verify (this conductor, log not exit code)

| file | result |
|---|---|
| `test/test_reml_ordinary_ranef.jl` | 18/18 (FD ≤ 1e-6 + `lrtest` guard) |
| `test/test_reml.jl` | 23/23 |
| `test/test_gaussian_ranef.jl` | 9/9 |

## Option A

**WAIT.** #423 and #428 still OPEN. Do not edit `test/runtests.jl`.

## Not done / fence

- No TSV / scoreboard A; no “parity complete”; no AI-REML; no q4
- No σ-RE / slopes / non-Gaussian REML
- DoD item 2 incomplete until Option A include
- LOOP/ kit stayed local (not in the PR)

## Next

Option A include of `test/test_reml_ordinary_ranef.jl` **only after** #423+#428 merge.
Claim stays partial. D-111 OFF. #49 PARKED.

`PLATFORM: cursor | LANE: mean-re-reml | FOREIGN LANE: claude+#429+#428+#423+#420+#406+phylo-mean+arc1+biv-q4+a3c+catchup`
