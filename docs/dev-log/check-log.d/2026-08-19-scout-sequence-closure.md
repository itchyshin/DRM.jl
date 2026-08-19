# 2026-08-19 — scout sequence closure (items 1–5 STOP)

**Lane:** `docs/420-406-housekeeping` (Cursor / Shannon). STOP. Shinichi away.

## RESUME

```
Dropbox DRM.jl on main @ aa9ce55f (+ note: #453/#454 auto-queued, not yet on main). AGHQ #449 + Cox-Reid #451 merged. Chip AGHQ still missing.
Scout plans on main: lever-extension (#452 @ aa9ce55f). q4-49 parked (#453) and cell-d pre-run (#454) auto-merge armed; #453 updating onto main (CI re-running); #454 still BEHIND until #453 lands.
Next optional G0: Binomial Cox-Reid (draft in plan) — needs issue + /goal if building.
#420/#406: OPEN, CONFLICTING/DIRTY — leave open. Do not restart AGHQ/Cox-Reid in this chat.
```

## Item 1–5 status

| Item | What | Status | PR / SHA |
|---|---|---|---|
| 1 | AGHQ lever 2 + Poisson phylo Cox–Reid | **merged** (engine already on `main` before this slice) | [#449](https://github.com/itchyshin/DRM.jl/pull/449) + [#451](https://github.com/itchyshin/DRM.jl/pull/451) @ `8c6d4f78` |
| 2 | Cell D ADEMP pre-run (scope + stop) | **auto-queued**, green then **BEHIND** after #452 | [#454](https://github.com/itchyshin/DRM.jl/pull/454) — not merged at write time |
| 3 | Lever-extension scout (Binomial 1\|g Cox–Reid) | **MERGED** | [#452](https://github.com/itchyshin/DRM.jl/pull/452) merge `aa9ce55f` (2026-08-19T15:06:49Z) |
| 4 | q4 / #49 parked scout | **auto-queued**; branch updated onto `main`; required CI **re-running** | [#453](https://github.com/itchyshin/DRM.jl/pull/453) head `e76aed32` |
| 5 | #420 / #406 housekeeping | this PR (docs only) | leave [#420](https://github.com/itchyshin/DRM.jl/pull/420) + [#406](https://github.com/itchyshin/DRM.jl/pull/406) OPEN |

## What's left

- Wait for #453 then #454 auto-merge (docs-only; unique files; update-branch needed because repo requires up-to-date base).
- #420 / #406: owner after vacation (close-as-superseded vs docs-only rebase).
- Optional next G0: Binomial Cox–Reid — **needs issue + `/goal`**. Not this chat.
- Capability chip AGHQ still **missing**. Do not flip.

## OPEN GATE

Shinichi (after vacation): (1) confirm #453/#454 landed; (2) decide #420/#406;
(3) only then consider Binomial Cox–Reid G0. Do not restart AGHQ / Cox–Reid
in this chat. Do not merge #420/#406 from this scout.

| 2026-08-19 | **Scout sequence 1–5 STOP** | #452 merged `aa9ce55f`; #453/#454 auto-merge armed; #420/#406 left OPEN (DIRTY) | ✅ docs-only; no `src/`; no chip; no #49 | Shannon |
