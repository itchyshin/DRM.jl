# Inner-mode repair — integration remains open

The original certificate-only candidate2ab0c168 passed33focusedchecks but
failed GammaIID/NB2phylogenetic gradient tests and profile covariance construction.
Exact-fixture diagnosis found three rejected perturbed modes with fullNewton
trials meeting the unchanged stationarity criterion despite2–3ULP objective rises.

Guarded-polish candidate608c24c8 restored all30perturbed points(150assertions,
plus2runnerchecks) and all9originalgradientassertions. It did NOT restore full
fitting: NB2recovery had outergradient48.7476(required<.001) and SDmu.3; both
profile batches errored inGamma covariance. See round001-regression-summary.json.
All source/testhashes were unchanged during those runs. Never cite these failures
as passing evidence for the committed profile-status checkpointde4620c7.

Rose then found a premature whole-damping exit on coordinate-identical trials.
A consistent anisotropic quadratic exposed it(49pass2fail); candidate572f46bb
preserves higher-damping retries and passed51focusedassertions. Rose approves
this narrow correction; integrated fitting/inference gates are still unmet.
Source/test snapshots for each candidate and failed test drafts are retained.

The independent perturbation verifier was tested against an explicit in-process
load of preserved2ab0c168:138pass12expectedfail,9.18s,exit1,unchangedinputs.
It detects allthree failing points through four related checks each. The
negative-control override is recorded in its receipt; on-disk source was572f46bb
and was not changed. Final BLASrestoration assertion was not reached onfailure.

Next: diagnose exactfailedNB2/Gamma fits using realwarmstarts and h1e-5 Hessian
perturbations. No tolerance/budget/ULPallowance relaxation, no hidden skipping,
no covarianceexception suppression as a substitute for a working fit. The
robustE-step neighbour finding is a separate unproved follow-up.
