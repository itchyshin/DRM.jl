> Current status: the bounded inner-arithmetic repair is reviewed and committed
> locally in `c7e5b823`; all six local repair gates passed on the committed source.
> This does not establish general fit/profile convergence or programme completion.
> The numbered sections below preserve the **initial investigation**, followed by
> chronological candidate and verification receipts; their older failure/status
> statements are historical, not the current verdict. A different Gamma fixture
> now exposes nonconverged fit/nuisance solves in the profile-threading slice.

## 1. Goal

Require an actually stationary inner mode before reporting a successful non-Gaussian location-scale Laplace solve, within programme #563.

## 2. Implemented

Implementation is under review. The bounded contract preserves the current budget, tolerance, loadings and return tuple while checking final stationarity after the last update, including finite coordinates, gradient and norm arithmetic.

## 3a. Decisions and Rejected Alternatives

A successful Hessian factorization is insufficient to certify a mode. Keep the default 200 iterations and 1e-9 scaled-gradient criterion. A last-step update that reaches stationarity should succeed; exhaustion far from stationarity must fail. Do not change the estimator, likelihood or optimizer policy to make the checks pass.

## 4. Files Touched

Builder owns src/locscale_inner.jl, the new test/test_locscale_inner_status.jl, its runtests include and ignored Unlazy ledger. Root owns this report, evidence and checkpoint. Neither denied Gaussian file is touched. Four preflight refs were inspected; their foundational loading/damping/inverse work is already present, with no existing exhaustion fix to reuse.

## 5. Checks Run

Current source2ab0c168 passes33 focused controls but fails broader regressions. Three files completed: newstatus33, originalinner16 and originalmarginal6 assertions. In the next gradient file, four assertions pass and two fail (Gamma IID and NB2 phylogenetic); the fit file is not reached. Both one/four-thread profile batches error during the Gamma fit's covariance calculation with nonfinite Hessian entries (76 assertions pass before one error). All runs terminated and input hashes match. Local gates: G0met; G1–G3failed; G4unmet. This candidate is not ready to commit as a fix. The exact-fixture diagnostic completed in8.9s: three perturbed solves stall just above tolerance while finite and PD. Full undamped trials meet stationarity with2–3ULP represented objective increases. The strengthened gradient test retained the same two failures in29.46s; seven assertions passed in that file. Source/test hashes were unchanged. Rose approved implementation of a bounded4ULP Newton-polish exception; acceptance is still pending.

## 6. Tests of the Tests

Historical strictly convex controls return ok=true while gradients exceed the criterion; a stationary control remains valid. New tests include convergence on the final update, zero-budget stationary/nonstationary states, nonfinite state/gradient, a real Gamma success/refusal pair and four-dimensional finite-entry overflow. Preserve each failed draft and do not equate defect-reproduction exit0 with correctness.

## 7a. Issue Ledger

Parent programme #563 and all global gates remain open. This slice does not close native-R/direct-Julia/bridge numerical parity or calibrated inference.

## 8. Consistency Audit

The candidate also adds a narrowly guarded local Newton-polish exception, pending tests. Ordinary descent remains the default; the exception must reach the unchanged stationarity criterion with a finite, tiny full undamped step and positive-definite trial curvature. This is not a claim of exact objective monotonicity.  Existing marginal likelihood and gradient functions already consume the ok flag; rejected inner states must continue through their existing failure paths. This code-level defect has not been shown to cause the previously observed Gamma profile failures.

## 9. What Did Not Go Smoothly

Early focused-test drafts had a definition failure and an over-strong assertion about the returned state after an invalid gradient; both are retained separately. The first candidate missed norm overflow despite finite entries. Independent review caught it before the broader runs. A first full-step diagnostic accidentally reused NB variables for Gamma; that Gamma section is invalid and retained alongside a corrected Gamma run. Base analytic gradients were finite; only the failed perturbed points return NaN. The enormous finite differences arise from the existing1e18 failure sentinel, not evidence of an analytic derivative formula error.

## 10. Known Residuals

The certificate received Rose approval, but three required regression gates failed. The existing gradient tests use NaN != 0 in preliminary assertions, so their printed passes alone do not prove finite analytic gradients. Local slice acceptance remains unmet. Valid profile endpoints, bootstrap calibration, threading, every-workflow performance, cleanup and documentation visual/deployment obligations remain open.

## 11. Team Learning

Root Sol/medium, builder Terra/high, Rose Sol/high; active agent-hours not instrumented. Golden Set: exact convex kernel controls plus existing response-family likelihood/gradient tests. Memory receipt: no Codex memory changed. No DRAC or Totoro campaign launched.

## 12. Cross-Product Coverage

This does NOT cover general optimizer convergence, full numerical inference parity, bootstrap/profile calibration, performance superiority, publication or programme completion.


### Continuing checkpoint: guarded polish and damping repair

Candidate608c24c8 restored the original nine gradient assertions and all30
independent perturbed-point certificates (150checks plus2runnerchecks). The
full module still failed the NB2 recovery test: exact outer gradient48.7476
versus required0.001 and mean-effectSD0.3 versus recovery target0.5. Eight
smoke assertions and four recovery assertions passed; two recovery checks
failed. Both profile batches still error in Gamma covariance construction.
No full inference acceptance follows from restored pointwise derivatives.

Rose found a new candidate regression: an unchanged trial stopped all damping
retries. A consistent anisotropic quadratic exposed it (49pass2fail); candidate
572f46bb preserves higher-damping directions (51pass focused). Rose approves
that source correction, while integrated acceptance remains open. The current
read-only diagnostic targets the exact failed fits and warm Hessian perturbations.
No broad test rerun or larger compute campaign has been launched on that source.


### Arithmetic checkpoint

Read-only128/256bit full-endpoint evaluation confirms that both exact rejected
steps decrease the mathematical joint objective, while Float64 term/predictor
arithmetic reverses the sign. BigFloat sums of rounded terms stay positive;
compensating only the outer sum is insufficient. Saved endpoints, scripts,
failed attempts, order/constant controls and hashes are retained. The next
stable-integral comparison is a prototype only; source572f46bb is still not
accepted. No production allowance/tolerance/budget change or source expansion.

Historical negative control of the independent30point verifier:138pass,
12expectedfail,9.18s, explicitly loading preserved2ab0 into an isolated process.
The source on disk was unchanged572f46bb; no production edits occurred.


### Stable comparison prototype

The smooth-identity prototype matches full high-precision NLL differences in
sign and magnitude and rejects opposite uphill steps. Quadratic/quartic controls
show the need for sufficient quadrature. BigFloat Hessian evaluation fails
explicitly because trigamma(BigFloat) is unsupported; this is retained, not
silently downgraded. Quadrature agreement is an error estimate, not a rigorous
bound. Rose agrees the approved programme requires finite numerical validation,
not a newly invented universal libm proof; a bounded estimated-error contract
is being prepared before any production comparison change.

### Implementation checkpoint: estimated comparison under review

The builder implemented the bounded fallback and reported 66 focused assertions
passing on candidate `781da0ae`. This is not the five-step independent oracle
campaign or the original fit/profile regression suite. A two-state preliminary
check returns negative estimated margins, but the Gamma estimate differs from
the earlier high-precision reference by approximately `3.7e-4` relative, above
the frozen `1e-4` criterion. The exact discrepancy remains under investigation;
neither the criterion nor the margin constants have been relaxed.

Rose found that the first scale calculation loses cancellation inside loading
products and the NB2/Gamma gradient expressions. The builder is correcting that
scale, including predictor construction, before freezing a new candidate. This
is a concrete implementation gap, not a request for formal interval proof.

Melissa independently approved evidence-only checkpoint `2b015936`, retaining
all failures and open gates. Mission Control commit `56bdd946` was checked at
the served URL; its exact-file lease is released. Existing connections to Totoro
and all five DRAC hosts were verified without starting compute or a new login.

Root added duplicate-label refusal and exclusive log creation to the three
private regression runners. Invoking each with an existing label exits before
Julia starts; previous log and receipt hashes remain unchanged. Copies and the
verification receipt are retained under `retained-runner-guards/`.

### Frozen candidate and original regression results

Candidate `2c534141` and focused test `194b91bd` address Rose's cancellation
findings and pass78 focused assertions. Rose approved these source/test changes
at their bounded scope. All five retained failure steps pass independent128/256
bit comparisons: maximum relative discrepancy1.446e-5 against the unchanged1e-4
criterion. A later review caught a missing opposite-step assertion in the pilot;
pilot004 adds it and passes, while deliberate corruption is rejected in005.
Earlier failed script drafts remain evidence, not passing runs.

Root's separate48-case grid covers both families, n=5/17/64, general loadings,
coupled dense/sparse priors, both step directions, row reversal and objective
shifts. It passes294 assertions in4.43s. Corrupting estimates by1% produces96
expected failures and198 passes in7.85s, exit1. Source/probe hashes are unchanged.

The actual Unlazy commands were rerun on the frozen source. G0 passes; G1 passes
123 test assertions plus2 runner checks in34.66s, including the previously failed
NB2 convergence/recovery test. G4 passes150 perturbation assertions plus2 runner
checks in5.72s. G2 and G3 each still produce76 passes and one Gamma covariance
error, before profiling, in15.10s and14.23s respectively. One Optim warning about
early termination due to a NaN Hessian remains in the otherwise passing G1 log.
All run inputs are unchanged. This candidate is **not integrated acceptance**.

The next diagnostic uses the actual public Gamma fit and fitter-held warm state.
A copied-loop replay and the public marginal status disagree; distinguish inner
failure from prior-factor failure before changing production code. No tolerance,
iteration budget, likelihood or requested uncertainty calculation was weakened.

### Documentation and coordination delta

Four additional retained Documenter pages were visually sampled. Root inspection
rejected the initial mobile verdict because two screenshots were invalid. A fresh
browser check found a normal342pixel article within the390pixel viewport both
on direct navigation and after resize settled; immediate resize captures can
contain a transient sidebar overlay. All original and corrected receipts remain.
This is not a fresh build, all-page or globalG6 verdict.

The small tutorial line-wrap edit was not performed: auto-review rejected its
ownership claim. No retry or indirect source change was attempted. Mission
Control commit `260abcb` was checked at its served URL and its exact-file lease
released. No remote fit/allocation, publication or cleanup action was launched.

### Gamma arithmetic diagnosis and reconnected compute

The apparent replay disagreement above is now resolved: the public fit stores
its covariance parameters in a different order from the internal engine. Using
the captured engine-order vector reproduces exactly one failed covariance
perturbation (theta1 minus h). Its prior factor is valid. Independent 128/256-bit
objective evaluation gives a decrease of 5.4686167e-20 and confirms the trial is
stationary, while the current estimated-error margin correctly refuses it.

The read-only compensated-prior prototype reduces the directional estimate error
from 7.45e-22 to 1.25e-25 on that sixth case. All five earlier states and the sixth
case have dense/sparse state, row-order and group-coordinate checks (the
prototype still traverses sparse states by dense indexing). This does not
accept a production repair: source remains frozen at 2c534141 and the current
margin still refuses. Rose is reviewing tracked residual arithmetic before any
new source change. Final prototype003 and earlier failed attempts are retained
with hashes; earlier script bytes are not claimed to match the final script.

At 2026-08-31 14:56 UTC, live hostname probes succeeded through existing sockets
for Totoro, Fir, Nibi, Rorqual, Trillium and Narval. Fresh login fallback was
disabled. No jobs or allocations were submitted. The initial sandbox refused
socket access; the authorized read-only probe then succeeded. The Mac remains
the appropriate target for this seconds-long arithmetic check.

Rose subsequently approved the tracked-residual contract for implementation and
testing. The contract is retained before edits. Builder is implementing only
within its existing lease; source is now mutable until a new hash freeze. The
prototype's uphill check used the old helper and its sparse traversal was dense
indexing, so neither supports acceptance of the new code. Required new controls
explicitly address both. Pat's read-only receipt review found one missing
connectivity checksum; it has now been added to the manifest. No completion or
performance claim follows from this authorization.

Melissa independently approved the exact 99-file evidence-only checkpoint. It
contains no working source, test or reader-page files; embedded source snapshots
are explicitly unaccepted evidence. Her clarity comment about dense/sparse state
checks versus actual CSC traversal was incorporated above. The global programme
and the new candidate's acceptance remain open.

### Tracked arithmetic and original regression verification

Frozen source `7f9571e7` implements the independently reviewed tracked prior
arithmetic. Final focused test `59fb2c45` passes 78 existing and 32 new assertions.
The new controls include a nonzero discarded tail and show that setting its
bound to zero invalidates the certificate. Rose independently reviewed the source
and final test addition. Tolerances, iteration budget, data envelopes and all
mode acceptance safeguards remain unchanged.

The independent 48-case grid passes 294 assertions in3.53s; its one-percent
corruption is rejected (96 failures,198 passes) in4.47s. A new independent
explicit-likelihood oracle checks all six fixed diagnosed states under dense/CSC,
row/group permutations and opposite steps:96 variations,480 passes in12.51s.
All96 deliberately corrupted comparisons fail the relative criterion; there are
184 failed assertions and296 passes in13.74s. Some conservative error margins
cover a1% error, so the negative-control count is184 rather than192. Each probe,
source and serialized-state hash remains unchanged. The captured Gamma base and
trial come from the retained old trace, not from refitting with new source.

The actual Unlazy local G0–G4 commands now pass. The original inner/gradient/NB2
module passes155 assertions plus2 runner checks in34.21s; perturbations pass
150 plus2 in5.64s. One-thread profiles pass194 plus2 in19.25s, four-thread
profiles198 plus2 in18.95s. Gamma no longer fails at covariance construction.
One pre-existing Optim early-termination/NaN-Hessian warning remains in the
passing smoke module; these results do not establish universal convergence.
LocalG5 verifies the immutable Rose receipt against current source/test hashes;
its stale-hash negative control fails. The gate checker reports ALL MET(6).
The first run was denied access to its standard approval registry and executed
no checks; the authorized retry is retained separately. Local gate numbers do
not close identically numbered global programme gates.

Mission Control commit `03933b3` updates only the two claimed status fields;
served fields were checked and the lease released. No remote jobs, allocations,
publication, main merge, release or worktree retirement occurred. The fresh
52-page documentation source build is running with a240second cap; rendered
verification, source checkpoint and wider programme work remain pending.

### Fresh documentation verification

Build004 failed on a missing canonical manual entry for the new helper. The
owned reference now includes that entry. Build005 passed document checks but
failed during rendering when the sandbox refused Julia's package-usage lock;
its receipt is retained. Authorized build006 passes52pages/134executable
examples in147.18s, with all source hashes unchanged. Fresh Vitepress HTML
rendering passes in8.54s with emitted inputs unchanged; cached dependencies
were reused without a package installation. The changed reference expressly
labels the helper internal and without a stability guarantee. Pat approves the
prose and claim boundaries; visual review of the fresh reference is in progress.
No live-site deployment or whole-site visual verdict follows from these checks.

### Fresh visual closeout

Root recovered the in-app browser after Pat's recorded unavailable attempt and
visually inspected fresh desktop light and390x844phone light/dark screenshots.
Phone page width equals viewport390; main width342. Text and inline formulas
wrap. Direct section fragments hide their heading beneath sticky navigation
(P2), retained for the site-layout slice. The raw audit retains106missing
deployment-metadata links across53pages. No G6/all-site visual pass is claimed.
The viewport was reset, owned tab closed and temporary server89140stopped.
