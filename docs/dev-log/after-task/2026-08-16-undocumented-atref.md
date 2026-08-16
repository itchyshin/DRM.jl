# After-task — close the undocumented-export `@ref` gap

Date: 2026-08-16 · lane: **catch-up @ref docs** (Cursor Shannon) · no spawned subagents
Anchor: drmTMB **0.7.0**. Scratch worktree only
(`/Users/z3437171/local-scratch/lanes/DRM.jl-catchup`). Branch cut from
`origin/main` (`394b62d9`); **#426 left untouched**.

## What shipped

`docs/src/reference/model-fitting-and-postfit.md` gained `@docs` homes for the
exported symbols that `[\`name\`](@ref)` pointed at while no manual page
rendered them. That is the same defect that turned `warnonly = true` Documenter
warnings into VitePress/npm failures on #423 and #428.

`src/variational.jl`: `Laplace` and `Variational` are **unexported** (a bare
`Laplace` would clash with `Distributions.Laplace`). Their `@ref`s became plain
code spans.

## Ledger (re-measured, read-only)

```
COUNTDOWN: 0 export gaps (18 raw, 18 accounted for) · 11 unsupported capability rows · 14 closed gates
```

See `docs/dev-log/evidence/2026-08-16-parity-ledger-countdown.md`.

## Parked because of fences

| Target | Why parked |
|---|---|
| `_group_index`, `_general_cov_setup`, `_fit_phylo_mean_laplace_nuisance`, `_fit_crossed_mean_laplace_nuisance` | Internals; only `@ref`s live in `src/sparse_laplace_glmm.jl`, owned by **#425** |
| `make_problem_from_Q` | Not exported; only `@ref` is in fenced `src/gaussian_bivariate.jl` (**#423**) |
| New sidebar page | `docs/make.jl` is fenced (**#423**). Existing unfenced reference page used instead |
| #428 auto-merge, #429 rebase, #406, #423 ρ̂ | Other lanes. Not this slice |
| 11 unsupported capability rows | Next frontier; not this slice |

## Rose audit

- **Claim vs evidence:** this PR claims the *exported* undocumented `@ref`
  targets now have a `@docs` home. It does **not** claim Documenter was rebuilt
  locally (CPU-light; CI is the check) and does **not** claim the 11-row
  capability campaign is done.
- **Scope honesty:** docs + one internal-docstring edit. No `bf()` / grammar
  change; `DRM_PARITY_TESTS=1` not required. No GPL vendoring.
- **No drift:** does not touch `AGENTS.md` / `HANDOVER.md` / the coordination
  board / fenced src or docs paths.
- **#136:** stays OPEN. This slice does not close, fix, or resolve it.

## Perspectives

Shannon (coordination) + Pat (reference home) + Rose (claim-vs-evidence).
Noether not invoked — no engine change. No spawned subagents.
