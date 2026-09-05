# Gaussian stopping diagnostic — #563

Rose verdict: approve this bounded diagnostic; oracle agreement is not optimizer or parity success.

Four frozen default native fits reproduce exactly. Analytic Gaussian ML likelihood and gradients agree with native TMB (likelihood error≤1.08e-12; gradient error≤3.26e-14). Central finite-difference errors are below1e-7. The oracle gate PASS means those checks and reproduction pass, not that the tighter fits converged.

| Case | Default native gradient max | Recorded Julia gradient max | Tight native status | Restart coefficient difference from Julia (native TMB) |
|---|---:|---:|---|---:|
| numeric | 0.000267791 | 5.54497e-10 | 1: singular convergence (7) | 4.65645e-08 |
| factors | 0.0015333 | 4.62527e-09 | 1: singular convergence (7) | 6.14191e-08 |
| default_scale | 1.11282e-05 | 2.06613e-13 | 0: relative convergence (4) | 3.47757e-08 |
| known_variance | 6.65901e-06 | 1.39888e-13 | 1: singular convergence (7) | 2.27494e-08 |

Tighter controls alone returned the same coefficients; three fits reported singular convergence. Explicit diagnostic restarts from the default values using analytic and native-TMB objectives gave closely agreeing solutions. Their gradients still reach3.54e-5, so these are closer diagnostic solutions, not certified optima. Evidence supports a stopping-accuracy explanation for these fixtures. No native default or Julia source changed.

**Original parity failure remains:** factor stored-mean difference6.260969154e-6 exceeds4e-6. Neither tighter fits nor restarts replace the frozen baseline. The current evidence does not close full parity or establish performance.

The older input JSON dropped coefficient names. The runner recovers coefficients from the complete stored link predictions using explicit full-rank design matrices, checks projection errors<1e-12, and verifies agreement with the recorded coefficient arrays. It does not silently guess factor ordering.

Negative controls add0.01 to every analytic gradient component; all8checks reject the damage. In receipts001/002, runner_sha256 identifies the unmodified base script. negative-control.R is the retained mutation recipe. Later explicit negative_control fields, when present, bind the wrapper and executed text. Both archived runner versions match their original receipt hashes.

Timing: first eight-fit diagnostic1.902s; extended diagnostic1.902s (eight fits plus eight short restarts). Native-only local runs; no Julia rerun, remote campaign, or timing comparison claim.

Source/build: each receipt binds the unchanged native methods and loaded DLL against the original frozen prediction receipt. Candidate source is the previously reviewed isolated S10 candidate, excluding unfinished ZOB changes. Runner versions and input hashes retained. Parent R/Julia revision identities are in the prediction-contract-pilot provenance; these diagnostic tools were uncommitted when run.
