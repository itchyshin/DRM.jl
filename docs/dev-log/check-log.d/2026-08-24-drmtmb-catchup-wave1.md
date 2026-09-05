| 2026-08-24 | **drmTMB catch-up — Wave 1** (#465 #466 #467 #468 · drmTMB#1080 for DRM.jl#460) | `julia --project=test --startup-file=no test/runtests.jl` · `tools/check_test_deps.py` · `tools/parity_ledger.py` · `tools/check_capability_citations.py` · `DRM_PARITY_TESTS=1` bridge-formula fixtures · drmTMB targeted `testthat` | ✅ see below | Shannon |

<!--
Detail for the row above. The renderer takes the row; this note is for readers.

## What was gated

**#465 — nine orphan test files.** Six wired into `runtests.jl` (+100 assertions),
including the first running tests for the Cox–Reid work merged in #451, which until
now had no test executing at all. Two recommended for deletion with stated reasons
(`test_analytic_grad.jl`: its premise is false at 3–690% relative error vs central
differences; `test_q4_laplace.jl`: exercises a dense O(p³) POC superseded by the
verified sparse engine, and would need 5 undeclared deps for zero coverage of shipped
code). One left unwired because it **genuinely fails** — filed as #472 rather than
weakened or skipped.

**#466 — `niterations`.** Wired across ~18 family routes. Routes with no single
attributable `Optim.optimize` call (Gaussian `meta_V`/phylo/relmat/animal/spatial and
multi-ranef; the Cox–Reid REML branch, whose θ̂ comes from an untracked secondary
restricted refit; every family's sparse-Laplace structured route) keep an **honest
`-1`** rather than a fabricated count. No fitted value, logLik, or convergence flag
moved — verified by re-running 20+ existing family test files and confirming their
parameter-recovery assertions unchanged.

**#467 — bridge formula constructs.** `scale()`, `I()`, `factor()`, `(...)^k` and
mechanical `- term` removal LANDED, each with an R-parity fixture generated from
byte-identical CSV (never `Random.seed!` vs `set.seed`). `poly()` **deliberately still
rejected**: R defaults to `raw = FALSE` (QR-orthogonal), which a raw-power
implementation would silently disagree with — the message now names the two faithful
workarounds. `- term` through an unexpanded `*` also still rejected, with a new guard
that throws rather than silently leaving the removed interaction in the Julia model.

**#468 — coverage pre-run only.** Smoke + reachability + D-139 estimate. **Stopped at
the go/no-go; no grid run, no fence touched, no coverage claimed.** The smoke earned
its keep by failing first: `stderror` is `Inf` on the sigma/phylo-SD axes, and the
fixture's `q4_vcov = false` returns all 17 Wald rows as (−Inf, Inf) while appearing to
run normally.

**DRM.jl#460 → drmTMB#1080** (open, NOT merged; D-164 release hold stands). Profile and
bootstrap now accept ordinary `fixef:<dpar>:<coef>` targets through
`engine = "julia"`; Wald row count reconciled with native drmTMB.

## Defects found by the gate, not by inspection

- **#472** `mstep_Lambda` descends the true marginal at p=100 for every step size —
  found only because an orphan test finally ran.
- **#473** `drmTMB 0.7.0` identifies at least 16 different builds; the installed one
  predates 16 shipped-file commits on `origin/main`. Every banked parity number used
  it. `tools/drmtmb_provenance.R` added so a build is identifiable.
- **#474** `readdlm` silently makes numeric fixture columns categorical when any column
  in the CSV is a string.
- **#475** the R bridge reaches DRM.jl's non-exported helpers by qualified name.
- **Ledger fix `d265d876`** — the "N unsupported capability rows" countdown was
  `len(caps)` by construction and could never move; `supported` is not in the governing
  vocabulary at all. Now reports the real distribution.
- **7 stale citations** in `capability-status.md`, plus a new guard
  (`tools/check_capability_citations.py`) that caught two more within minutes of the
  Wave 1 merges shifting `runtests.jl` line numbers.
-->
