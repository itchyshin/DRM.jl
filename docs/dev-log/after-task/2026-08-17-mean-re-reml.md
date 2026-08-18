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
- Invert `test/test_reml.jl` (already in the default suite) so the old
  `@test_throws` does not go red
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

S2 writer (05b28cf8) reported on `fab5e00e`:

| file | result |
|---|---|
| `test/test_reml_ordinary_ranef.jl` | 15/15 |
| `test/test_reml.jl` | 23/23 |
| `test/test_gaussian_ranef.jl` | 9/9 |

This close adds FD ≤ 1e-6 and the REML `lrtest` mean-structure guard to the
standalone file. Re-run those three files before merge.

## Rose

**clean-with-limitations.** B chip flipped after src+test. Default-suite
include of the *new* file deferred. Do not claim `Pkg.test()` covers
ordinary-RE REML via the new file (the inverted `test_reml.jl` cell *will*
run in the default suite).
