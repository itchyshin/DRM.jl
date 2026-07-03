# 2026-06-21 — Location-only Gaussian sparse-MME REML pilot

Goal:

- Add the first exact-Gaussian sparse-MME transfer slice from HSquared: a
  supplied-variance restricted objective for the location-only phylogenetic mean
  cell, a Takahashi trace diagnostic that reports the selected-inverse trace
  mode, an AI-vs-observed-information diagnostic, and boundary fixtures.

Checks:

```sh
sed -n '1,260p' AGENTS.md
sed -n '1,140p' HANDOVER.md
sed -n '1,140p' ROADMAP.md
sed -n '1,220p' docs/dev-log/coordination-board.md
gh pr list --repo itchyshin/DRM.jl --state open --limit 20 --json number,title,headRefName,baseRefName,author,updatedAt,url
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-mme-pilot.md docs/dev-log/after-task/2026-06-21-loconly-reml-mme-pilot.md
```

Result:

- The source edit stayed in the Codex engine lane: `src/location_only.jl`, with
  tests in `test/test_location_only_reml_mme.jl` and a `test/runtests.jl`
  include.
- The only open PR was `#296` (`codex/issue-293-ml-diagnostics`), targeting q4
  ML diagnostics, so this location-only Gaussian helper did not overlap it.
- `Pkg.instantiate()` succeeded and precompiled `DRM`.
- `julia --project=. test/test_location_only_reml_mme.jl` passed:
  36/36 assertions in 5.2 seconds after the AI-information and boundary fixture
  additions.
- `git diff --check` passed.
- The claim-boundary scan found only expected guardrail wording: "not a public
  estimator claim" and "not yet an AI-REML optimizer".

Boundary:

- This is an internal exact-Gaussian helper, not a public estimator claim. It
  does not change q4, sigma-phylo location-scale, non-Gaussian/Laplace, or
  Ayumi-facing capability wording.
