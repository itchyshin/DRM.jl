# GOAL — complete Julia–R parity and better

Approved by Shinichi in Codex task `01a05261-cd5c-7ca3-a654-cebea9f187fb`, 2026-08-30.
Read this file and checkpoint.md at every continuation. The active app goal is the same programme.
The approved execution plan is docs/dev-log/plans/2026-08-30-julia-r-parity.md.
LOOP/ultra-plan.md is an inherited unrelated Cox-Reid plan; do not use it for this programme.

All currently implemented native drmTMB capabilities must work directly in Julia and through
`engine = "julia"`, with retained correctness evidence. Every registered warm full-workflow
benchmark must beat a comparably configured R baseline using a reliable automatic thread policy.
Cold startup is reported separately. Polish the whole Documenter/VitePress site, repair the R
bridge documentation, preserve/reconcile unfinished work in both repos, and update Mission Control.

## Immutable choices
- Full native-R scope, not the older 12-row bridge ledger. Keep experimental boundaries honest.
- Separate complete capability/output coverage from the finite benchmark manifest.
- Targeted validation, not a universal interval-coverage claim. Native bugs need independent adjudication.
- Warm timing includes preparation, transfers, construction, requested uncertainty and return conversion.
- Report 1/2/4/8 threads; calibration fixtures are separate from policy evaluation fixtures.
- Missing, skipped required, stale or absent output evidence never passes a required gate.
- A remaining speed loss keeps the programme open. Re-estimate after the 8–20 agent-hour reserve;
  never silently drop cases or run an unbounded further optimization campaign.

## Approved boundaries
Routine scoped edits, tests, builds, checkpoints and local commits proceed without repeat permission.
Both repositories are in scope; current source checkouts and other lanes are preserved. Named branch
PR preparation is in scope. Engine/grammar changes follow the approved mathematical contracts with
Noether/Rose review. Do not change an estimator merely to agree with a buggy reference.
No release, registration, collaborator message, credentials/security changes, forced Git operation,
or deletion of historical work. Retire worktrees only against a concrete recoverability/disposition list.
Respect separate repository merge/ownership gates. No new publication workflow or permission changes.
Estimate every fit/benchmark before running; >30 min campaigns need measured pre-run + owner approval.
Totoro CPU <=150 cores, BLAS=1; DRAC allocated jobs only. No campaigns in GitHub Actions.

## Completion
All required unlazy gates reverified on final sources; Rose independent verdict; Melissa reconciles
original promises plus this plan. First-pass completion is not programme completion.

## Execution locations
- Julia: `/private/tmp/drm-parity-20260830/DRM.jl`, branch `codex/julia-r-parity`.
- R: `/private/tmp/drm-parity-20260830/drmTMB`, branch `codex/julia-r-parity`.
- Preserve these branches as durable checkpoints. `/private/tmp` itself is not durable storage.
- Initial sources: DRM f47789646f27221ba4fad29a8ba1b3b8a790b521;
  drmTMB b35642b4560072cadba7e595e66e00209ebdeb40.

The goal skill wrapper could not resolve its launcher; the canonical launcher inspected was
Claude-specific and rewrote permission settings. Used isolated git worktrees with unchanged
permissions and the required codex/ prefix instead. This is not a permission workaround.
