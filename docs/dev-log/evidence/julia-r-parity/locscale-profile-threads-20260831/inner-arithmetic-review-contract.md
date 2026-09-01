# Fixed-point arithmetic discrimination and unselected whitening alternative

Independent reviewer: Rose, requested Sol/high. This is a diagnostic/design
contract, NOT approval of a production change or an inference-completion claim.

At identical a64, compare native residual with Big(P64)*Big(a64) plus individually
lifted Float64 observation-gradient terms. Rebuild Gamma terms independently in
BigFloat to separate kernel/predictor rounding. Rebuild precision from exact
binary lambda/Q to isolate (P64-Ptrue)*a. An independently solved true-P mode
alone does not establish attainability for the fixedP64 problem. If necessary,
solve fixedP64 in BigFloat and inspect bounded adjacent-float candidates. For QI,
a found per-group2D candidate establishes attainability; failure of round-to-nearest
or of a finite neighborhood search does not prove universal unrepresentability.

If prior multiplication/summation dominates and an acceptable Float64 point
exists, compensated sparse multiplication plus data accumulation is the minimal
candidate. Preserve genericQ/generalZ and non-Float64 fallback. Do not call a
bilinear helper once per basis vector: that worsens complexity. Retain the
actual Euclidean certificate ||g_a||2 <= tol*(1+||a||2), tol=1e-9.

Unselected exact alternative: B=I_G⊗L, a=Bz, Pz=Q⊗I2, W_i=Z_i L.
J=sum ell_i(t0_i+W_i z_g)+z'Pz z/2; H=Pz+sum W_i'D_iW_i.
M=J+logdet(H)/2-logdet(Q). Covariance-normalization terms cancel.
Let dW=Z_i*dL, b=dW*z_g, S_g=(H^-1)_gg, R_i=W_i*S_g*W_i',
kappa_c=.5*sum_ab T_abc*R_ab, v_g=sum_i W_i'*kappa_i, w=H^-1*v.
Then the covariance derivative is
sum_i [(s+kappa-D*W*w_g)'*b - s'*dW*w_g + <D*W*S_g,dW>_F].
Both explicit dW terms are required. The original-coordinate certificate uses
L^-T*g_z,g via triangular solves and tol*(1+||Bz||2); it cannot be replaced by
the same numeric tolerance in whitened coordinates. GeneralQ sparse-factor and
selected-inverse costs depend on fill; only the local contractions are generally
O(n+nnzQ). Tests would need nonidentityQ, noncanonicalZ, all covariance directions,
zero-loadings normalization and near-boundary original-coordinate certificates.
This alternative changes internal coordinates used by inference/random effects
and requires separate integration review. It is not selected or implemented.

Root pre-run review also caught diagnostic support/validation defects: denseQ
instead of sparseQ, dynamic helper loading inside main (world-age risk),
Float64 aggregation before lifting individual observation terms, missing explicit
crossprecision/start-agreement gates, and comparing cold packed objective with
warm raw objective. Correct these before trusting an OK marker; keep failed runs.


## Rose follow-up: objective arithmetic experiment (2026-08-31)

Supplied fixed-point direction174337Z supports a controlled experiment only.
Use q(a)=0.5*sum_ij a_i*P_ij*a_j over every stored entry; fully stored symmetric
off-diagonals occur twice. Triple-product FMA residuals and tracked addition
must retain low terms until final accumulation. Existing prior helper's
quadratic field uses ordinary products and is not a compensated quadratic.

Preserve Float64 predictor evaluation and each kernel output. Arithmetic
bounds cover multiplication/summation, not kernel errors. Compare (a) BigFloat
sum of frozen Float64 kernel outputs plus exact fixedP prior and (b) independently
rebuilt256-bit fullfixedP objective. Retain baseline, gradient, objective and
combined cases for four starts, fixed alpha1/0.5/0.25 trial differences, and
independent Euclidean acceptance. Candidate success requires zero fallbacks;
unsupported arithmetic is reported, never silently discarded. No universal
cancellation cure or production approval follows from this diagnostic.

Reviewer used supplied evidence and read source helper; no numerical run/edit.
Existing review assignment: Sol/high; builder assignment: Terra/high.
Active agent-hours are not instrumented.
