# Joint location-scale bootstrap contract (before implementation)

Fixed original fit and model; no estimator or public coefficient change here.
Let Q be the G x G group precision, L the fitted 2 x 2 loading, Lambda=L L'.
Draw E with G x 2 independent standard normals; B=chol(Q).UP \ E, A=B L'.
Cov(A[g,:], A[h,:])=inverse(Q)[g,h] Lambda. Draw every latent group, including
unobserved/internal tree nodes; apply the recorded row indices afterwards.
eta_i=Xmu_i beta_mu + A[gidx_i,1]; psi_i=Xpsi_i beta_psi + A[gidx_i,2].
Q is a precision, never multiply its Cholesky by normal noise or solve Q E.
A is group by axis; interleaving is vec(transpose(A)), not vec(A).

| Symbol | Model field | Draw | Verification | Truth |
|---|---|---|---|---|
| beta_mu | :mu | fixed Xmu beta | rebuilt designs | fitted vector |
| beta_psi | :sigma, current engine convention | fixed Xpsi beta | kind-specific density | fitted vector |
| L | :recov=[logL11,logL22,L21] | A=B L' | dense-small covariance oracle | fitted Lambda |
| Q | LocScaleObjective.Q | triangular precision solve incl permutation | T T'=Q^-1 | fitted group precision |
| gidx | objective row map | A[gidx,1:2] | shuffled/repeated rows and mismatch refusal | original model row mapping |
| y | conditional family | distribution below | independent logpdf / seeded draws | conditional density |

NB2: mu=exp(eta), size=exp(-2psi). Gamma: mu=exp(eta), shape=exp(psi).
Beta/BetaBinomial: mu=logistic(eta), precision=exp(-2psi); BB trials fixed.
Retain current likelihood clamps: eta +/-30; Gamma psi +/-30; other psi +/-15.
Do not truncate/redraw Gaussian latent states to enforce these numerical guards.
No mutable factor/solver scratch shared by coefficient/replicate workers.
Preparation may share copied immutable triangular sparse factors and permutation;
each draw allocates its own normals, solves, effects, predictors and response.

Generic simulator must use NB2 size=sigma^-2, including zero/hurdle/truncated
neighbours. Gamma's existing `_gamma_sigma_is_shape` distinguishes coupled shape
from ordinary CV slots. New private sigma override has the SAME slot convention
as the fit. No public keyword or Gamma coefficient normalization in this repair.

Required separate parity debt: coupled Gamma still exposes logshape/shape under
sigma whereas Gamma docs promise logCV/CV. Full normalization requires beta/2
with negative sign, latent covariance D Lambda D (D=diag(1,-1/2)), complete outer
covariance Jacobian, inverse objective/profile maps and decreasing CI endpoint
reversal. This remains required, not excluded from the approved programme.

Verify sampler/data compatibility before using stored objective rows; invalid
rows, trials, design or covariance must error, never fall back to fixed effects.
Final proofs: distribution tests and damaged-oracle controls; tiny B2 refits and
serial/threaded parity; bridge tree forwarding; no coverage inference from B2.
