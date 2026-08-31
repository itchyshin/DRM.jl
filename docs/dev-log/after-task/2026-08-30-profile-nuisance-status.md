# Generic profile nuisance status — bounded verification

## 1. Goal
Address Ayumi's inference concerns under programme#563. A finite nuisance
minimum is not usable profile evidence when its optimizer did not terminate
successfully. Preserve failure through Julia intervals, plotting and R status.
All programmeG0–G8 and the strict coefficient parity failures remain OPEN.

## 2. Implemented
Changes add shared nuisance acceptance, per-arm method/fallback/
reason diagnostics, failed endpoint warnings, selected-row bridge status and
indexed plotting errors. Existing CI row shape stays unchanged. The returned
endpoint coordinate must be the coordinate whose likelihood was evaluated.
Specialized location-only/location-scale routes carry neutral not-checked
metadata; their numerical solver contracts are not certified by this repair.

## 3a. Decisions and Rejected Alternatives
Preserve historical optimizer defaults per route, ML/REML likelihoods and
convergence criteria. Do not equate Optim termination with stationarity/global
optimality. Failed endpoints retain signed infinity for compatibility but must
be distinguished from non-crossing within the searched range. Do not change or
bypass gaussian_structured.jl or gaussian_sparse_lss.jl. No likelihood gradient
or large-tree speed improvement is claimed here.

## 4. Files Touched
Terra: generic profiling in src/inference.jl, src/visualization.jl and focused
tests. Root: src/bridge.jl, bridge tests, runner includes, three Julia guide
pages, narrow generated R wrapper and R article guidance, public-R runner and
receipt checker. Foreign JuliaS5 test/include and R ZOB changes are preserved.

## 5. Checks Run
Final combined002 passed212 assertions in31.108seconds with four Julia and
one BLAS thread;100 source/test/dependency hashes were unchanged and current.
It includes74 focused,13 independently written root oracles,10 bridge-status
checks and115 existing neighbours with their original tolerances. docs001
executed19 examples across three guide pages in29.953buildseconds, source
manifests unchanged. This is executable-example evidence, not visual/deployed
proof: subset cross-reference warnings and missing theme assets remain visible.
Ordinary publicR004 completed20.899seconds (22.204processseconds) with the
analytical GaussianML interval and15 injected transport cases passing. Checker003
passes12 damaged-receipt rejections and all141current source hashes. Earlier
public002/003 remain historical as their checker hashes were superseded.
The three executable leaf checks reverified successfully in gates001;
all six bounded leaf gates are met. All prior runs remain retained.

## 6. Tests of the Tests
Historical replay confirms the old40iteration stored-gradient route returned
a finite minimum/minimizer when Optim.converged was false. Initial deterministic
RED002 retained5passes/2failures/4errors; undefined new helper errors are not
independent evidence of old numerical failure. Genuine plotting refusals failed.
The public-R transport cases deliberately inject statuses through
the actual generated wrapper in isolated test modules; they are not numerical
optimizer reproductions. Their preparation is stubbed, so they do not prove
model admission. The old facade tests helper absence, not every prior release.

## 7a. Issue Ledger
Programme#563 and all broader inference/performance gates remain open. Ayumi#29
and issue28comment5472354858 were refreshed read-only; update timestamps are
unchanged. No collaborator message or issue closure was sent.

## 8. Consistency Audit
Rose Sol/high approved the design and bridge approach, then rejected interim
abdbf00a source despite passing tests. Required repairs: exact per-route solver
options; floating-point cancellation bounds; warning test scope; public
profile_curve docstring; interrupts in autodiff selection; three-parameter
surface failure; stronger returned-coordinate regression. Final numerical source286fec89 and root independent oracles approved.
Checker review found missing scalar/shape/provenance validation and incomplete
source-set coverage; twelve negative controls now reject those damaged receipts.
The final checker5ffc8eff was approved; public004 unchanged-receipt
validation passes. Rose independently reran the final checker and approved the receipt.
All three executable checks reran and all six bounded leaf gates are met.
Terra Melissa reconciliation retains the entire approved programme scope.

## 9. What Did Not Go Smoothly
Passing tests missed changed iteration/tolerance policy and a likelihood-shift
sensitivity. Preserve combined001 as historical, not final qualification.
The initial warning assertion did not enclose the warned call. Code and test corrections passed fresh combined002; no normal-root
tolerance relaxation was accepted. Checker002 failed on missing R AST formal
arguments; extraction was limited to the intended setup function body.
public001 was a Julia depot-lock permission failure before fitting, not a model
failure. Subsequent runs used the approved scoped execution permission.

## 10. Known Residuals
No stationarity/global optimum or coverage proof follows from successful
optimizer termination. Nonmonotone profile search need not find the first
crossing. Generic objective workspace thread safety, profile gradients,
large-tree cost, full native-R interval parity, strict near-boundary raw
coefficient parity and specialized profilers remain separate obligations.

## 11. Team Learning
Numerical policy is part of the estimator workflow: a refactor must preserve
per-route defaults. Testing selected-row transport with deliberately failed
results catches misleading success labels that ordinary successful fits cannot.
Root actualSol/medium, Terra/high builder, RoseSol/high and Luna/low scouts;
active agent-hours are uninstrumented. Local bounded tests only this slice.

## 12. Cross-Product Coverage
This does NOT cover every native capability, interval coverage, shared sparse
workspaces, registered warm-workflow wins,1/2/4/8threadpolicy, all24native missing-
predictor cells, worktree/stash cleanup, whole-site visual/deployment or clean
integration. No new remote compute, release, registration or publication.
Mission Control058f16f four-field update is served and verified. Scoped
source/evidence commits: Julia bf7504a7, R6c25d5d82, CARRIED-OVER on the isolated
branch, unmerged/undeployed. Next sparse ML gradient attachment needs fresh
authorization for the previously denied file; see profile-gradient-next-slice.md.
