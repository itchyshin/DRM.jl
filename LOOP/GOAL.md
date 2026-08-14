# GOAL — DRM.jl catch-up so drmTMB can do `engine = "julia"` (IMMUTABLE — re-read every arc)

Read this first, every cycle. Auto-compact eats messages, not this file. Unsure
after a compaction? Re-read THIS, then `checkpoint.md`, then continue.

## Mission

**Solo platform:** Claude Code. **Lane:** DRM.jl (full) + drmTMB (**narrow**:
`R/julia-bridge.R`, `tests/testthat/test-julia-*`, `vignettes/julia-engine.Rmd`
only).

Close the capability gap so an R user can write `drmTMB(..., engine = "julia")`
and have DRM.jl fit it, returning a drmTMB-shaped object. The unit of progress is
a **bridge-admitted model cell**, not a Julia-facing export.

**Bar:** [[DECISIONS#D-111]] readiness condition (1) — *"caught up with the R twin
on the shared surface that matters for a public twin claim"*. Registration is
**not** the goal; D-111 forbids pursuing Registrator at all.

## Anchor

**drmTMB 0.7.0 @ `origin/main` `f5ec53634`.** Refresh the countdown with:

```bash
python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main
```

Measured 2026-08-14: **25 export gaps · 11 capability rows (6 partial, 4
experimental, 1 unsupported) · 14 gates closed by intentional error.**

## Headline

The **bivariate non-Gaussian cluster** new in drmTMB 0.7.0 — `biv_lognormal`,
`biv_student`, `biv_associate`, `associate_pairs`, `association`,
`latent_normal`, plus the `bivariate-nongaussian` vignette. DRM.jl has no twin
for any of it. Prior research exists: deep-research notes **dr18** (bivariate
lognormal contract) and **dr19** (exact bivariate Student-t) — read them before
designing, do not re-derive.

> **Superseded 2026-08-14 by arc A0.** The original headline was "fixed-effect
> non-Gaussian families cannot use `engine = "julia"`". That was read off a
> drmTMB working checkout **987 commits stale**; PR #499 (2026-08-09) had already
> moved that row to `experimental`/`partial` and deleted the `base_nonphylo_count`
> gate. Read the twin via `git show <ref>:<path>`, never its working tree.

## Invariants (fences)

- Issue **#136 stays OPEN** — never `close`/`fix`/`resolve` near that number.
- **#49 / missing-data / the bridge `impute` payload: PARKED** — owner-named only.
- `engine_control_surface` is **unsupported by design** — needs an R API design first.
- **No Julia General / Registrator** (D-111). **No GPL vendoring** — DRM.jl is MIT;
  parity uses generated outputs only.
- Never regress the verified q=4 core (2.18×, logLik −256.51).
- Never stage `.worktrees/` or `.codex/agents/shannon-coordinator.toml`; never `git add -A`.
- In drmTMB: stay inside the narrow lane. Its tree is busy — 9 live lanes, a 0.7.0
  release slice, and `docs/design/` numbering races (claim a number by committing).
- `src/` authority is **full, incl. formula grammar**; the human gate is at **tag**.
  Any arc touching `bf()`/`drm_formula()` must run `DRM_PARITY_TESTS=1` and attach
  the result to its PR — that is the rail replacing human grammar review.

## Definition of done (per arc)

Impl + tests + docstrings + worked example + `docs/dev-log/check-log.d/` entry +
after-task report + Rose audit. One issue → one branch → one PR.

**A capability row is promoted ONLY on a native-vs-Julia same-target comparison**
(matching coefficients and logLik within the row's declared tolerance). Direct
DRM.jl evidence is **not** R-via-Julia bridge support. Export-name presence is
**not** capability parity.

## Closure

Every registry row is either `supported` with a parity fixture, or carries an
explicit written `claim_boundary` saying why it is not.
