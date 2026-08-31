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

## Diagnostic support and globalization, 2026-08-31

Installed SpecialFunctions has no BigFloat trigamma method. The independent
reference may approximate it by a fourth-order Richardson derivative of BigFloat
digamma, with fixed steps1e-8/1e-16 at128/256bits. Require h-versus-h/2 agreement
within1e-27/1e-55 and retain the independent scalar-NLL derivative checks. This
is approximate Hessian support, not a full-domain special-function accuracy claim.

Required controls include the independent Erlang density anchor (shape3,rate2,
y4 gives NLL8-log64), B=0 prior identity, and a nonzero-B Gaussian exact marginal
using the SAME Laplace composition helper. For B=[2 0;1 1],y=[1,2],unit noise,
the exact marginal is log(2pi)+log(11)/2+15/22. Deliberately omitted and doubled
logdet corrections must fail. Write explicit multiplication in derivative
stencils: Julia's `8f1` is a Float32 literal, not `8 * f1`.

The first lower-terminal reference passed both precisions and starts, but the
unchanged moderate-L control encountered an indefinite Hessian during the search.
Do not replace that control or infer that its final mode is indefinite. A bounded
damped-Newton/Armijo search is authorized for the independent reference J:
positive-definite step matrix H+delta*I, descent direction, unchanged J in Armijo,
strict clamp checks. Damping NEVER enters final H/logdet/M. Near roundoff a full
undamped Newton step may use a tiny-step, bounded-objective-change acceptance
with strict residual decrease. Record this explicitly. Preserve100iterations,
both starts, residual tolerances, final undampedPD and crossprecision gates.
Do not swallow special-function or derivative-control assertions as rejected
line-search trials. This solver change has no effect on production code.
