# After-task — docs #9 fix + GLLVM.jl cross-examination & coordination posts (2026-06-13)

## 1. Docs build (#9) — FIXED + CI-verified green
- PR: [DRM.jl#282](https://github.com/itchyshin/DRM.jl/pull/282), branch `shannon/fix-docs-build-9`.
- Documenter CI: **success** on commit `415cdfd` (run 27479132603).
- Root cause was NOT a Documenter-version regression (the `1.11-1.16` pin was a no-op; reverted to `"1"`). Two real causes:
  1. **FATAL** — vitepress build exited 1 on **2 dead `./@ref` links** in `docs/src/cross-family.md` (lines 90, 226) to `` `DRM.link_residual` ``. The docstring was **never attached**: a 5-line `# NB:` comment sat between the `"""docstring"""` and the `link_residual(::Gaussian,…)` method, which voids Julia's docstring→definition attachment (verified via `Base.Docs.doc(Binding(DRM,:link_residual))` → "No documentation found"). Fix: move the comment after the method (`src/link_residual.jl`) + add a `## API` `@docs DRM.link_residual` anchor in cross-family.md. Re-verified locally: docstring now attaches.
  2. **WARNINGS** — `docs/src/tutorials/animal-models.md:85-91` `ranef(fit)[:id]` threw `KeyError(:id)`: `ranef(fit)` is an **empty Dict** for the single structured `animal()`/`relmat()` path (only the two-component / crossed Gaussian paths call `_withranef`). Fix (docs-only): dropped the two broken `@example` blocks, added an honest note. Surfacing BLUPs there is a separate **engine** enhancement (mirror `_withranef` in `gaussian_structured.jl`) — left for the engine owner.
- Commits: `caba73b` (dead-ref + ranef + pin revert), `415cdfd` (docstring attachment).
- Status: green, **left for the user to merge** (merges are the user's call).

## 2. DRM.jl ⇄ GLLVM.jl cross-examination (read-only, 6-agent workflow) + coordination posts
Workflow `wf_e1e7119c-4b9`: 5 parallel finders (per-direction dependency maps, Matérn duplication audit, adversarial #8-inheritance refutation, completeness critic) + synthesis. 30 raw findings → ~10 distinct points, all code-cited.

### Two corrections to the earlier solo cross-examination (verdicts unchanged):
- **#8 safety mechanism corrected.** "GLLVM is safe because it whitens to N(0,I)" only describes the *latent* path. The real analog of DRM's phylo precision is GLLVM's non-whitened *structured/SPDE* path. Correct reason GLLVM escapes #8: it **never ridge-escalates** a Hessian without putting the same ridge in the prior logdet (jitter baked symmetrically into the covariance before inversion → matched). DRM #8 = `sparse_pd_chol` escalates a ridge onto `logdetH` while `logdetP` keeps a fixed `+1e-10I` (unmatched). Verdict: **GLLVM does not inherit #8** (adversarial refutation failed).
- **REML hold (#97) overstated.** GLLVM's integration trunk **already ships** `fit_gaussian_reml` (basic restricted term, Gaussian-only). The accel #97 wants (AI-REML / analytic gradient) is absent on **both** sides → hold should stay for that piece only.

### Audit correction by me: DRM **has Aqua** (`test/test_aqua.jl`); only **JET** is missing (GLLVM has both).

### Posts made (user-authorized "post all coordination items"):
- GLLVM.jl: #62 (Matérn adopt), #13 (corrected #8 note + log refresh), #97 (REML clarify), #96 (mode-finder borrow — unblocked, ready to start), #27 (response-missing reference), **#98 NEW** (per-column family companion to DRM #280).
- DRM.jl: #270 (adopt GLLVM #62 + split Matérn/NNGP), #8 (durable fix guidance), #49 (cross-link #27), #280 (companion link to GLLVM #98).
- Bidirectional cross-links completed (#280 ↔ #98, #270 ↔ #62, #49 ↔ #27).

### Matérn verdict (high confidence): DRM has zero SPDE code; GLLVM #62 is real+tested+dependency-light → factor its FEM core into a tiny shared MIT package; don't rebuild. Split DRM #270 into (a) adopt #62, (b) NNGP net-new.

## Open / user-gated
- Merge PR #282 (DRM docs) + drmTMB PR #538 — user's call.
- GLLVM-side execution of #96/#98/#27 etc. — triggered by the filed issues; their team picks up.
- DRM #8 engine fix (matched ridge) — engine owner.
