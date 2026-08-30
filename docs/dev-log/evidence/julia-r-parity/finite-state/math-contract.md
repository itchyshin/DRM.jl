# Shared finite-state missing-predictor contract

For row i and state k, mean mu_ik = Xstate[i,k,:]' beta, residual SD
sigma_i = exp(Xsigma[i,:]'delta), predictor probabilities pi_ik.
Observed predictor state j contributes log(pi_ij), plus Gaussian response density
when y is observed. Missing predictor contributes logsumexp(log(pi_ik)+logfy_ik)
when y is observed, otherwise exactly zero. Observed x/missing y still contributes
its predictor probability. Missing-state posterior normalizes those same weights.

Ordinal: P(x<=k)=logistic(c_k-eta_i), eta_i=Xp_i'alpha with NO intercept.
c1=t1; c_k=c_(k-1)+exp(t_k). K states, K-1 cutpoints. Use stable log differences;
never subtract two saturated sigmoid probabilities. Predictor mean is expected
score sum(k*p_k); reported route SD is sqrt(sum((k-Ek)^2*p_k)), conditional on
fitted parameters, subject to native covariance/status availability conventions.

Categorical: state1 baseline logit0; nonbaseline eta_ik=Xp_i'alpha_k.
Raw alpha is level-major, then design-term order. Normalized logsoftmax. Imputed
point is first maximum-probability category code; probabilities retained. No
metric SE for unordered codes: NA/route_conditional_se_unavailable, with fit
covariance failures propagated instead where applicable.

Native public tests and R preparation provide contracts, not code for Julia.
R source anchors: missing-data.R1539-1635,1729-1855,4325-4410,5328-5355;
drmTMB.R17370-17376,18842-18866. Immutable generated outputs provide numerical
oracles; the Julia implementation is independently written under MIT.

Rose clarifications before implementation: fitted mean is the posterior-weighted
state-expanded mean, never a model-matrix evaluation at expected ordinal score
or categorical mode. Raw theta order is beta,delta,alpha,ordinal raw cutpoints;
raw covariance remains in these coordinates. Natural cutpoint covariance, if
exposed, needs its full Jacobian. Observed rows and se=false retain fit OK status;
categorical route-unavailable applies only missing rows when SE requested. Fit
covariance failures dominate every row. Ordinal SD has no parameter delta term.
Native R postfit ordinal helper floors state probabilities at machine epsilon;
its likelihood uses stable log differences. Do not floor the Julia objective or
claim extreme-tail postfit parity without investigating that native limitation.
