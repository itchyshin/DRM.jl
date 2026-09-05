# Prospective q2 whitening prototype — same Laplace likelihood

Diagnostic only. No production API, estimator or tolerance change authorized by
this note. Source baseline0b88a01c plus pending gradc0369528/inner94f54c74.
Current original finiteCI test still12pass4fail; keep that obligation intact.

Let a=Bz, B=I_G tensor L; Pz=Q tensor I2; per-observation W=ZL.
Jz=sum_i nll_i(eta0_i+W_i z_g)+0.5*z'Pz*z.
Hz=Pz+sum_i W_i'D_i W_i.
M=Jz+0.5logdetHz-logdetQ (same intended L/Q model).
This is NOT an identity for the frozen rounded P64 unless Pz=B'P64B.

Outer derivative: Sg=(Hz^-1)gg, Ri=Wi*Sg*Wi',
kappa_i[a]=0.5sum_bc T_i[b,c,a]*Ri[b,c]; v_g=sum_i Wi'*kappa_i;
w=Hz^-1*v; r_i=s_i+kappa_i-D_i*Wi*w_g.
For a covariance coordinate lambda:
M_lambda=sum_i r_i'*(dWi*z_g)-s_i'*(dWi*w_g)
             + frobenius(D_i*Wi*Sg,dWi).
For mean/scale fixed effects, contract r_i with the corresponding design column.
The three dL matrices differentiate logL11, L21, logL22 respectively.
Q fixed; normalization is independent of lambda after whitening.

Original-coordinate certificate stays ||B^-T g_z||_2 <= 1e-9*(1+||Bz||_2).
Require an undamped positive-definite final Hessian and finite predictions.
All base and perturbed predictors must lie strictly inside production clamps;
the smooth derivative contract does not cover clamp crossings.
A returned rounded a64 is a distinct point: independently certify that image
against intended L/Q, and retain its back-transform/round-trip discrepancy.
A transformed certificate alone must not silently certify an invalid returned a.
No fitted parameters, failures, budget, or fixed-point labels may be substituted.

Prospective checks before production consideration:
1. Fixed saved-state objective arithmetic and conditioning vs256bit frozen-kernel
   reference, with point round-trip and intended/frozenP targets distinguished.
2. Float solver at every saved endpoint with original-coordinate certificate;
   independent128/256bit modes/objectives and returned-a64 check.
3. Covariance and beta derivatives against independent converged-mode finite
   differences; multiple steps, actual residuals, and coordinate maps retained.
4. GeneralQ/noncanonicalZ and normalization controls; unsupported cases refused.
5. Original default-SE and finite-profile tests, unchanged. Existing14/28/155
   and profile-status suites still required; coefficient threading not excused.

Local prototypes capped before each run; no remote or >30min campaign here.
