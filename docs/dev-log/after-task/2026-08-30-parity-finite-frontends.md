# Finite-state frontend and R bridge checkpoint

## 1. Goal
Continue the approved Julia–R parity programme (#563) by connecting the shared
ordinal/categorical missing-predictor likelihood to direct Julia and the R bridge.
This is a bounded development checkpoint. Programme G0–G8 remain OPEN.

## 2. Implemented
Direct formulas admit one finite-state predictor with a Gaussian response and
fixed-effect designs. The R route transports native state-expanded designs to
the same unchanged likelihood. Both retain posterior state probabilities,
state-weighted fitted means, original rows, uncertainty statuses and full raw
covariance. R public coefficients/covariance exclude ordinal predictor cutpoints;
predictor metadata retains constrained cuts. Direct Julia retains raw coordinates.

## 3a. Decisions and Rejected Alternatives
Keep native defaults and the strict 4e-6 tolerance. Neither finite-state case
passes that complete comparison. No-intercept means with numeric covariates use
K full state indicators. Direct Julia explicitly refuses additional categorical
covariates in no-intercept means until native first-factor coding is implemented;
this remains required work. Ordinal predictor intercepts are removed automatically.
Categorical metric SEs remain unavailable. No GPL implementation was copied.

## 4. Files Touched
Julia: src/DRM.jl, src/joint_missing_frontend.jl,
src/joint_missing_bridge.jl, new src/joint_missing_finite_bridge.jl,
test/runtests.jl, new test/test_joint_missing_finite_{frontend,bridge}.jl,
tools/check_finite_public_receipt.py, docs/src/r-julia-bridge.md,
docs/src/reference/engine-internals.md, finite-frontends evidence directory,
missing-predictor-progress.json, this report/check-log and LOOP/checkpoint.md.
R: R/julia-joint-{call,methods,missing}.R, new R/julia-joint-finite.R,
tests/testthat/test-julia-joint-finite-{prepare,result}.R,
tools/run-julia-joint-finite-public.R and corresponding evidence/report.
Ignored slice ledgers record executable checks. Mission Control changed only its
three now fields; local vault commit 8fd4ace. Foreign S5 test/include, R ZOB edits,
the denied sparse-engine source files and unrelated vault dirt were preserved.

## 5. Checks Run
Direct finite frontend and primitive bridge gates pass. Existing one/two-predictor
Julia frontend/bridge regressions pass. Seven R joint preparation/result/dispatch
test files pass. Actual public receipt finite-public-003.json records both
adapters PASS on unchanged source, with 21.864 seconds including startup—not a
warm benchmark. Independent likelihood/posterior/SD/covariance replay passes.
Two edited documentation pages execute, including the direct finite example;
this is not visual or deployed-site verification. Both SSH sockets answered
read-only hostname probes; no new remote compute was submitted.

## 6. Tests of the Tests
Missing frontend/schema tests failed before implementation. Review found and
repaired no-intercept coding, lexical numeric ordering, invalid categorical SEs,
a shadowed missing sentinel, and wrong test fixture conversion. R corrupted
result controls reject invalid rows, probabilities, cuts, covariance names,
uncertainty fields and levels. The independent public checker rejects 17 damaged
receipts, including dishonest native verdicts, malformed coefficient blocks,
false cuts, changed imputation labels and an adapter error of 1e-9 exceeding
the declared 1e-10 threshold. Failures and earlier receipts remain retained.

## 7a. Issue Ledger
DRM.jl#563 remains open. All 24 initial native missing-predictor obligations
remain required; no whole axis row closes. Approved programme plan remains
docs/dev-log/plans/2026-08-30-julia-r-parity.md. Do not use the unrelated inherited
LOOP/ultra-plan.md as programme authority.

## 8. Consistency Audit
Rose independently reviewed source and numerical evidence. Melissa identified
stale checkpoint wording and required an explicit raw-Julia/public-R coordinate
gap; this report and the current checkpoint address those findings. Golden Set:
the frozen native 180-row/all-four-mask cases, existing one/two-predictor
regressions, independent finite sums and corrupted-result controls. Ask-brain and
the compute playbook confirmed local/Totoro/DRAC routing; current socket probes,
not historical connection notes, establish connectivity. No new memory rule.

## 9. What Did Not Go Smoothly
Julia cache access required scoped escalation. The first new frontend runs
exposed a keyword/sentinel collision and malformed TOML row conversion. The
documentation checker rejected a build outside docs/build; corrected to a fresh
child directory without weakening its guard. The public checker initially
accepted incomplete flags/blocks and ignored some output fields; Rose's damage
probes drove stricter checks and actual new-data output retention. Native
numerical failures were not repaired by the adapter changes.

## 10. Known Residuals
Ordinal prediction error 7.560571e-6 and imputation error 5.124369e-6 exceed 4e-6.
Categorical theta error 1.740525e-5, prediction 9.576335e-6 and posterior error
1.041132e-5 also exceed it. Earlier single-predictor losses remain open. Required:
no-intercept categorical-covariate coding, raw/public accessor reconciliation,
full capability/output manifest, all original LSS/SE/REML/inference/large-tree
obligations, every registered warm win, work recovery/cleanup and whole-site
visual/deployment proof. Totoro's previous 67-second pilot used older source;
it is not current finite-state or speed evidence. No release, registration,
public deployment, push/merge or collaborator message. Receipts stamp the tested working trees, including preserved foreign R bridge
edits; they are not clean committed-head qualification. Actual agent-hours are
uninstrumented; do not substitute estimates as measured effort.

## 11. Team Learning
Validate the shape and meaning of each returned block, not just a flattened
vector or a true status flag. A receipt's reported error must independently
satisfy its tolerance, as well as agree with a recomputation. Preserve rejected
formula cases as required parity gaps rather than quietly changing model space.

## 12. Cross-Product Coverage
Covers two bounded Gaussian-response finite-state predictor routes, direct
formula construction, R transport/public operations, row metadata and conditional
summaries. This does NOT cover full native admission/argument/accessor parity,
other response families, random/structured effects, REML, profile/bootstrap or
coverage, automatic parallel policy, warm performance, all-page renders,
deployed documentation or worktree retirement. No programme gate is closed.
