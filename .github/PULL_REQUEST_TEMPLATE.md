<!-- DRM.jl pull request. Keep slices narrow: one issue → one branch → one PR. -->

Closes #

## What changed

<!-- One paragraph. Which persona's lane? -->

## Definition of Done

- [ ] Implementation wired into the module
- [ ] Tests (failing-first where applicable) in `test/runtests.jl`
- [ ] Docstrings + a worked example
- [ ] `docs/dev-log/check-log.md` updated
- [ ] After-task report in `docs/dev-log/after-task/`
- [ ] Rose audit — claim-vs-evidence, status tag honest, no doc drift

## Verification

<!-- Paste the commands you ran and their output. Verify before claiming. -->

- [ ] Engine not regressed (`bench/run_sparse_tmb_nd.jl` → logLik −256.51) *(if `src/` touched)*
- [ ] License boundary intact (no drmTMB GPL source vendored)
