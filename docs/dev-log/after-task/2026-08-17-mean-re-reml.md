# 2026-08-17 — ordinary Gaussian mean `(1 | g)` REML (#439)

**Lane:** `claude/lane-mean-re-reml` @ `~/local-scratch/lanes/DRM.jl-mean-re-reml`
**Personas:** Shannon (conductor) · Noether · Curie · Pat · Rose · Ada.
**Nested Task subagents:** 52d3af10 (stalled after S1/S2 draft) · 14d09e01 (S1 commit) · 05b28cf8 (S2 commit) · 34c90dd9 (duplicate Shannon; deferred).
**closes:** #439

Opt-in `method = :REML` for **Gaussian mean `(1 | g)` only**, on the existing
Woodbury spine. ML stays the default. Capability-status B-row flipped
`rejected` → `implemented` **after** src + standalone test, with footnote
that the new file is **not in the default suite yet**.

## What landed

- Narrow hole in `src/gaussian_core.jl` (live `method === :REML` guard;
  cite 413–423, not stale `:407`) for a single intercept `(1 | g)`
- Patterson–Thompson term `½ logdet(Xμ′ V⁻¹ Xμ)` in `src/gaussian_ranef.jl`
  on the existing `S`/`M` capacitance; `_withreml`; restricted Hessian vcov
- Keep `test/test_reml.jl`'s default-suite rejection focused on random slopes;
  it does not exercise ordinary mean `(1 | g)` REML
- Standalone `test/test_reml_ordinary_ranef.jl` (worked example in the header)
- `docs/src/capabilities.md` REML-scope warning + Inference row
  **Impl, untested**
- B-card flip in `docs/design/capability-status.md` with honest snapshot recount

## What this is not

- Not a `test/runtests.jl` include (Option A waits on #423+#428)
- Not Documenter **Tested** / **Stable**
- Not TSV `supported`; not “parity complete”; not AI-REML
- Not σ-RE / slopes / multi-ranef / non-Gaussian REML
- Not a q4 / `reml_q4.jl` / −256.51 / 2.18× change
- DoD item 2 incomplete until Option A include
- Do **not** cite #434/#438 as a B-chip-flip precedent (they were A fixtures)

## Verify (log, not exit code)

| file | result |
|---|---|
| `test/test_reml_ordinary_ranef.jl` | **18/18 pass** on `f51fcaa9` (current PR tip before these docs-only corrections), including the FD ≤ 1e-6 and REML `lrtest` guards added after `fab5e00e` |

Command:
`julia --project=. -e 'using DRM, Test; include("test/test_reml_ordinary_ranef.jl")'`.
The standalone file remains outside `test/runtests.jl`; no default-suite
coverage of ordinary mean `(1 | g)` REML is claimed.

## Rose

Rose's review of `f51fcaa9` returned **FAIL** for false default-suite coverage
claims and an inconsistent capability snapshot. These docs-only corrections
remove those claims and recount the table as 46 total: 40 `implemented`,
1 `rejected`, 1 `planned`, and 4 `missing`. The B chip remains
`implemented`, while Documenter remains **Impl, untested** because the
standalone file is not in the default suite.
