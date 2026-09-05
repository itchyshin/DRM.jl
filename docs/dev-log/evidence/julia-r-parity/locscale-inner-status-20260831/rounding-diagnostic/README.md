# Rounding diagnosis — candidate 2ab0c168

The exact-fixture diagnostic completed in8.9s and found three stalled cold
inner solves among the Gamma IID and NB2 phylogenetic central-difference points.
At the base parameter values analytic gradients are finite. At the failed
perturbed points the objective returns its existing1e18 failure sentinel and
analytic gradients are NaN. The huge finite differences are sentinel arithmetic,
not measured evidence of an incorrect analytic derivative formula.

Full undamped trials at the stalled states reach the unchanged stationarity
criterion with clean positive-definite curvature and tiny displacement. Their
represented objective increases are3ULP for Gamma plus1 and2ULP for NB2 phy
plus2/minus3. The first full-step log contains an INVALID Gamma section caused
by reused NB variables. Use only its NB sections and the corrected Gamma log.
Both are retained so the failed diagnostic is visible. No source edit occurred
in these probes. The subsequent proposed remedy needs adversarial tests and
all original regression gates; these diagnostics alone are not acceptance.
