# Rose-reviewed fixed-outer Gamma oracle contract

This is an independent diagnostic of the SAME Laplace approximation, not an
outer refit, an exact-integral claim or a production rewrite.

Freeze serialized input SHA d8727b67ae76c66fcc76cdd9f672b1f2bed72c165bf47e526caf50f769998434.
Assert G=4, Q=I4, positive finite responses, canonical group-interleaved latents
and engine ordering [beta_mu_intercept,beta_mu_x,beta_psi,logL11,L21,logL22].
Do not permute public and engine covariance coordinates twice.

L=[[exp(lambda1),0],[lambda2,exp(lambda3)]], B=I4 kron L, a=B*z.
eta=Xmu*beta_mu+a_mu; psi=Xpsi*beta_psi+a_psi; s=exp(psi); r=s*exp(-eta).
Independent full Gamma NLL: logGamma(s)-s*log(r)-(s-1)*log(y)+r*y.
The scale axis is log SHAPE, not log residual standard deviation.

J(z)=sum(NLL)+z'z/2. Solve grad J=0 independently. Final undamped Hessian
Hz=I8+B'DB must be positive definite. Reference M=J(z_hat)+logdet(Hz)/2.
Do NOT add logdet(L), prior determinants or 8*log(2*pi)/2: they cancel.
Reuse the independent density expression from verify_tracked_saved_oracles.jl,
not production likelihood, gradient or inner-solver functions. Every predictor
must stay strictly inside the production clamp; otherwise reject the comparison.

Convert saved Float64 inputs directly to BigFloat, preserving exact binary values.
Rebuild at128 and256bits, including modes and exponentials. Mode residual gates
are1e-25 and1e-50 respectively. Require finite/PD, agreement from zero and a
transformed saved-mode start, and record one further Newton correction because
the log determinant varies to first order with mode error. Cross-precision
objective and directional-numerator agreement <=1e-20. Future directional
reference derivative stability <=1e-10 with halving/Richardson checks.
Unmet gates mean unresolved oracle, never relaxed thresholds.

First pilot: exact lower-intercept terminal point plus a labelled moderate-L
interior control with identical data/design, both precisions and start checks.
Runtime unmeasured; three-minute process-group cap; no expansion until measured.
Expanded work must include actual saved Float64 perturbations and separately
symmetric BigFloat steps. All four original terminal points remain obligations.
No production optimizer/tolerance/budget/fixture changes are authorized.

## Seed provenance clarification before implementation

The frozen artifact contains outer states and Optim results, not latent modes.
Do not substitute or invent an original saved latent mode. A separate, capped
fixed-outer acquisition may compute the current production inner mode solely
to supply a second starting point. Serialize it as a newly captured seed with
source/state hashes; do not modify the original artifact. This acquisition is
not an outer refit or part of the reference evaluator. Reference J, derivatives,
Hessian, mode acceptance and 128/256-bit results stay independently implemented.
Both zero and transformed newly captured starts must independently pass the
same precision and agreement gates. If acquisition fails, that start gate stays
unmet; partial feasibility results cannot become a full oracle pass.
