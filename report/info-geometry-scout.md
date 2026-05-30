# Information geometry & singular learning theory — scout report

**For:** the q=4 phylogenetic bivariate location–scale Laplace engine (DRM.jl).
**Question:** what do Amari-style information geometry and Watanabe-style
singular learning theory contribute to our three pain points — EM-variance
overshoot, the removable singularity at the symmetric init, and the
identifiability-boundary flatness?

**Scope note / honesty.** This is an *algorithmic* scout, not a survey. Several
primary PDFs (Lin 2019, Pennec 2006, Amari 1995 RIKEN tech report, the EM/em
arXiv papers) would not extract through the web tool — their binary streams were
unreadable. Where a formula below is standard textbook material I know with
confidence (affine-invariant SPD maps; exponential-family duality), I state it
and flag it; where the exact constants matter (Lin's log-Cholesky exponential
map, RLCT values for our model) I mark it **VERIFY against the source PDF before
coding**. The natural-gradient-Cholesky update (Idea 1) is the one I could
extract verbatim and is the most directly implementable.

This report assumes the reader has already absorbed `q4-sparse-status.md` and
`em-acceleration-recipe.md`. It does not re-explain PX-EM, SQUAREM, or the
implicit-function-theorem gradient — it sits underneath them and explains *why*
the diagnosed overshoot happens and *which* corrected step is the right one.

---

## Bottom line — the 5 most actionable ideas, ranked by payoff

1. **Replace the EM closed-form Λ-step with a natural-gradient / Fisher-scoring
   step in the log-Cholesky chart — and recognise this *is* AI-REML.** The
   overshoot in pain point #1 is exactly what vanilla/EM gradient does when the
   metric is wrong: at a far-from-optimum init the Euclidean step length is
   mis-scaled by the curvature of the SPD cone. Pre-multiplying the gradient by
   the inverse Fisher information rescales every component to its natural unit,
   which is what AI-REML (Gilmour–Thompson–Cullis 1995) already does and why it
   converges in <10 iters without overshoot. **This unifies your two existing
   leads (natural gradient + AI-REML) into one update and is the single highest-
   payoff item.** Established, proven. Cost: medium (you already have the exact
   gradient; you need the AI matrix, which is cheap from the same Takahashi
   quantities). See Idea 1.

2. **Use the analytic O(d²) natural-gradient-Cholesky update of Tran, Nott &
   Kohn (2021, arXiv:2109.00375) for the Λ factor specifically.** They prove the
   Fisher information in the Cholesky chart is *block-diagonal* and that its
   inverse acts on the gradient by a closed-form triangular-matrix product — no
   d×d (here 10×10) Fisher matrix is ever formed or inverted. For our q=4 (d=4
   Cholesky factor, 10 free parameters) this is essentially free and gives a
   PD-by-construction, correctly-scaled Λ step. This is the *concrete instance*
   of Idea 1. Established. Cost: low–medium. See Idea 2.

3. **Desingularise pain point #2 by switching the Λ off-diagonal block to a
   non-centered (whitened) parameterization, or by L'Hôpital-limiting the four
   blow-up components.** The removable singularity (only the Cholesky entries
   coupling each response's own mean & log-scale blow up, exactly when ρ=0 and Λ
   is diagonal) is the standard centered-parameterization funnel: the gradient
   has a 0/0 form there. The information-geometry cure is a coordinate change
   that flattens the metric near the singular fibre. Either (a) reparameterize
   u = L·z with z ~ N(0,I) (non-centered), which moves the coupling out of the
   denominator, or (b) compute the analytic limit of those four components and
   hard-code it at ρ=0 / diag-Λ. Established (Stan/PyMC practice; Papaspiliopoulos
   et al. 2007). Cost: low for (b), medium for (a). See Idea 3.

4. **Treat pain point #3 honestly as a *singular* region (degenerate Fisher
   information), not a convergence bug — and stop near it on the right criterion.**
   When variance components → 0 the model is on the boundary of the SPD cone; the
   Fisher information is rank-deficient, the likelihood is locally a higher-order
   (non-quadratic) bowl, the MLE distribution is a χ̄² (50:50 point-mass mixture),
   and a gradient that plateaus at ‖g‖≈0.2–0.4 without reaching 0 is the
   *expected* behaviour, not a solver failure. Both your engines hit it because
   it is a property of the *model*, not the *optimizer*. Practical consequence:
   (i) switch the stopping rule there to a *step-size / objective-change*
   criterion rather than a gradient-norm criterion; (ii) for inference near the
   boundary use the χ̄² reference or a profile/parametric-bootstrap CI, not the
   Wald/Hessian SE (the Hessian is singular — this is exactly why drmTMB's
   sdreport returns NaN). Established (Self–Liang 1987; Stram–Lee 1994; Watanabe
   2009). Cost: low (it's mostly a stopping-rule + reporting change). See Idea 4.

5. **The em-algorithm-as-dual-projection view explains *why* the EM Λ-step is
   linearly convergent and structurally wrong here, and tells you when to prefer
   the marginal-ascent route.** EM = alternating m-projection (M-step) and
   e-projection (E-step) in dually-flat coordinates; its linear rate is set by
   the "angle" between the model and data manifolds, and the projection is only
   an exact ascent of the *true* marginal when the posterior is genuinely
   Gaussian. Under Laplace on the nonlinear log-scale axes it is not, which is
   precisely your diagnosed "EM ascends Q but decreases the true marginal."
   Conclusion: this view *confirms* your decision to ascend the true marginal
   directly for Λ (TMB-like) rather than chase a geometric EM acceleration.
   Mostly conceptual, high *decision* value, low implementation value. See Idea 5.

A one-line synthesis: **ideas 1–2 fix the overshoot, idea 3 fixes the removable
singularity, idea 4 fixes the boundary-flatness misdiagnosis, and idea 5 tells
you the EM acceleration path is a dead end for Λ here — so you should invest the
effort in the natural-gradient/AI-REML Λ-step, not in a fancier EM.**

---

## Idea 1 — Natural gradient = Fisher scoring = AI-REML for the Λ update

### The claim and why it cures the overshoot

Vanilla gradient ascent moves `θ ← θ + ρ·∇L`. This treats all coordinates as
Euclidean and equally scaled. On the SPD cone (and in the log-Cholesky chart)
they are not: a unit change in an off-diagonal Cholesky entry changes Λ far more
than a unit change in a log-diagonal entry, and the disparity *grows* as Λ moves
away from the identity. That mis-scaling is exactly the mechanism you diagnosed
("the direction ascends; the step is ~100× too big," off-diagonals blow up ~25×).

The **natural gradient** (Amari 1998) replaces the Euclidean step with the
steepest-ascent direction *in the Fisher–Rao metric*:

```
θ ← θ + ρ · G(θ)^{-1} ∇L(θ),     G = Fisher information matrix.
```

`G^{-1}` rescales each direction by its statistical curvature, so the natural
step is automatically short in the steep (off-diagonal) directions and long in
the flat ones. This is the precise sense in which it "cures the overshoot": it
makes the step *invariant to the parameterization* and correctly scaled
regardless of how far Λ is from the identity.

### Equivalence chain (this is the unification)

For our problem these are the *same* update, viewed three ways:

- **Natural gradient.** `G^{-1}∇L` in the Fisher metric.
- **Fisher scoring.** Newton's method with the observed Hessian replaced by the
  *expected* information `G = E[−∇²L]`. Identical to natural gradient when the
  metric used is the Fisher information. For exponential-family / canonical-link
  pieces, observed = expected information, so Fisher scoring = Newton there
  (confirmed: "Fisher scoring and Newton–Raphson are identical for GLM with
  canonical link," KL Ch.14; Gauss–Newton = Fisher for exponential families).
- **AI-REML.** Gilmour–Thompson–Cullis (1995) replace the Hessian of the REML
  log-likelihood by the **average information** matrix `AI = ½(observed +
  expected)`. AI-REML is a quasi-Newton method that requires only first
  derivatives plus this AI matrix, and it is the production variance-component
  algorithm (ASReml) precisely because it converges in a handful of iterations
  without overshoot.

So your two separate leads ("natural gradient" and "AI-REML") are one update.
The natural-gradient lens explains *why* it is well-scaled; the AI-REML lens
gives you the *cheapest computable* version of the metric (the average of
observed and expected information, both of which you can get from the Takahashi
selected-inverse quantities you already compute).

### Concrete update for Λ

Let `s = vech(log-Cholesky params of Λ)` (the 4 log-diagonals + 6 off-diagonals,
10 numbers). Let `g = ∂L/∂s` be your **exact** marginal gradient (the
implicit-function-theorem one validated to 6.5e-9 — *not* the cheap gradient,
which you already proved has the wrong sign on the scale axes). Then:

```
AI(s)  = ½ ( H_obs(s) + I_exp(s) )            # 10×10, SPD near the optimum
Δs     = AI(s)^{-1} g                          # natural / AI step
s_new  = s + α · Δs,   α ∈ (0,1] by line search (Armijo on the true marginal)
```

- The 10×10 solve is O(1) — trivial at q=4.
- `I_exp` is the expected information for the variance components; in a Gaussian
  REML setting its entries are `½ tr(Λ^{-1} ∂Λ/∂s_i Λ^{-1} ∂Λ/∂s_j)`-type traces,
  which under your sparse phylo structure are assembled from `Σ_phy^{-1}` and the
  Takahashi blocks (the same C = Σ Q[s,t]·(H⁻¹ block) you already form).
- The Armijo line search on the *true* Laplace marginal is what makes overshoot
  impossible — and crucially you already learned the guard must use a
  **fully-converged** E-step for the marginal comparison, not a warm-stopped one.

### Why this beats both vanilla gradient and the closed-form EM step

- vs **vanilla gradient**: correct per-direction scaling ⇒ no off-diagonal
  blow-up; superlinear near the optimum (AI ≈ Hessian there).
- vs **closed-form EM M-step**: the EM step is `AI^{-1}g` with `AI` replaced by a
  *fixed, posterior-independent* scaling that is only correct for an exact
  Gaussian posterior. Under Laplace on the nonlinear scale axes that scaling is
  wrong, which is the overshoot. AI-REML uses the *actual* information at the
  current point, so it self-corrects.

**Does natural gradient cure pain point #1? Yes — this is the established fix.**
It is exactly what your own diagnosis (`q4-sparse-status.md` "THE FIX") already
points at; the information-geometry framing tells you the three names are one
method and that the *expected*-information half of AI is what gives the EM-like
robustness while the *observed* half gives the Newton-like speed.

**Status:** established and proven (Amari 1998; Gilmour et al. 1995; Meyer 1997).
**Cost:** medium. You have `g`; you need `I_exp` (trace formulas from quantities
already computed) and a 10×10 solve. The line search you also already have.

---

## Idea 2 — The analytic O(d²) natural-gradient-Cholesky update (the concrete instance)

This is the most directly liftable result I found, and it is the one your own
`em-acceleration-recipe.md` already cites (arXiv:2109.00375). It makes Idea 1
concrete *in the log-Cholesky chart you already use*, with no Fisher matrix ever
formed.

**Setup (Tran, Nott & Kohn 2021).** Write Σ = C Cᵀ with C lower-triangular
(our Λ = L Lᵀ, L the Cholesky factor). Let `G` be the Euclidean gradient of the
objective w.r.t. `vech(C)`, i.e. `∇_{vech(C)} L = vech(G)`.

**Theorem 1(i) — the natural-gradient update (extracted verbatim):**

```
μ_{t+1} = μ_t + ρ_t · Σ_t · ∇_μ L_t
C_{t+1} = C_t + ρ_t · C_t · H̄̄_t
```

where the triangular correction `H̄̄` is built in two cheap steps:

```
H   = Cᵀ Ḡ            # Ḡ = G with all strictly-above-diagonal entries set to 0
H̄̄  = H with its diagonal halved
```

**Lemma 1(iii) — why no Fisher inverse is needed (extracted):** the Fisher
information in the Cholesky chart is block-diagonal,

```
F = [ Σ^{-1}   0   ]
    [   0    ℑ(C)  ]
```

and `ℑ(C)^{-1} vech(G) = vech(C · H̄̄)`. So the natural gradient for the Cholesky
factor is *literally* `vech(C·H̄̄)` — a product of triangular matrices, **O(d²)**,
versus O(d⁶) to form-and-invert ℑ(C) naively. For q=4, d=4: the update is a pair
of 4×4 triangular products. Negligible.

**Why it helps pain points #1 and (partly) #3.**
- PD-by-construction: C stays a valid Cholesky factor, so Λ = C Cᵀ never leaves
  the SPD cone — no projection, no ridge patch (this is what your
  `q4-sparse-status.md` flags as "needs principled hardening rather than ridge
  patches").
- The block-diagonal Fisher means the mean (β/μ) block and the covariance (Λ)
  block are *orthogonal in the Fisher metric* — you can update them with
  independent, correctly-scaled steps, which is the principled version of your
  conjugate-block split.
- The authors note explicitly that *precision-matrix* natural-gradient updates
  do **not** preserve positive-definiteness, but the *Cholesky-factor* update
  does. That is the argument for staying in the log-Cholesky chart you chose.

**Caveat — sign / direction convention.** Tran et al. derive this for a
maximization (variational lower bound) with a *Gaussian variational posterior*.
Your objective is the Laplace marginal, not a VI bound, so:
- use it for the **outer** Λ update where `G` is the **exact** marginal gradient
  w.r.t. `vech(L)` (not a VI gradient), and
- keep the Armijo line search from Idea 1 — the closed-form ρ_t step has no
  monotonicity guarantee on the true marginal.
In other words, take their *direction* (`C·H̄̄`, which is the inverse-Fisher-scaled
gradient) and your *step control* (line search on the true marginal). The
combination is exactly Idea 1 specialized to the Cholesky chart, with the Fisher
inverse evaluated analytically.

**Status:** established (peer-reviewed; the formulas extracted above are from the
paper's Theorem 1 / Lemma 1). **VERIFY** the index conventions (which triangle is
zeroed, vech ordering) against the paper before coding — sign/orientation bugs
here are silent. **Cost:** low–medium.

---

## Idea 2b — SPD-manifold optimization: which metric, and the retractions

You asked specifically about the affine-invariant and log-Euclidean Riemannian
metrics and how a manifold update relates to your log-Cholesky chart. Three
metrics are standard; here is the concrete comparison and the update each gives.

### (a) Affine-invariant Riemannian metric (AIRM; Pennec 2006)

The natural Fisher–Rao metric for zero-mean Gaussians. Standard formulas (these
are textbook — Pennec 2006; the source PDF would not extract, so treat as
**VERIFY** for exact constants, but these are the universally cited forms):

```
Inner product at Σ:   ⟨V, W⟩_Σ = tr(Σ^{-1} V Σ^{-1} W)
Exponential map:      Exp_Σ(V)  = Σ^{1/2} expm( Σ^{-1/2} V Σ^{-1/2} ) Σ^{1/2}
Log map:              Log_Σ(Λ)  = Σ^{1/2} logm( Σ^{-1/2} Λ Σ^{-1/2} ) Σ^{1/2}
Geodesic distance:    d(Σ,Λ)    = ‖ logm( Σ^{-1/2} Λ Σ^{-1/2} ) ‖_F
Riemannian gradient:  grad_Σ L  = Σ (∇L) Σ      (from Euclidean ∇L, sym.)
Gradient-ascent step: Σ_new     = Exp_Σ( α · Σ (∇L) Σ )
```

**Key property for pain point #3:** AIRM is **geodesically complete** and the
boundary of the SPD cone (a singular matrix, i.e. a zero variance component) is
at **infinite geodesic distance**. A geodesic step therefore *cannot reach or
cross the boundary* — variance components are pushed toward 0 only
asymptotically, never overshooting to indefinite. This is the manifold-level
reason an affine-invariant update is robust where a Euclidean step on Λ is not.
The cost is two symmetric eigendecompositions per step (for Σ^{±1/2}, expm,
logm) — fine at 4×4.

### (b) Log-Euclidean metric (Arsigny et al. 2006)

Pull the Euclidean metric back through the matrix log:

```
d_LE(Σ,Λ) = ‖ logm(Σ) − logm(Λ) ‖_F
Update: work in X = logm(Σ) (a flat vector space), take ordinary gradient
        steps in X, map back Σ = expm(X).
```

Cheaper than AIRM (one logm up front, one expm back), still PD-by-construction
and boundary-avoiding (X→−∞ as Σ→singular). It does **not** have full affine
invariance, but for a *single* covariance block (not averaging many) the
difference is minor. **This is essentially your current log-Cholesky idea's
cousin** — both put the parameter in an unconstrained flat space and map back.

### (c) Log-Cholesky metric (Lin 2019) — the one closest to what you do

Lin (2019) builds a bi-invariant Lie-group metric on the Cholesky space (lower-
triangular, positive diagonal) and pushes it to SPD. The construction splits a
lower-triangular L into its **strictly-lower part ⌊L⌋** and its **diagonal
𝔻(L)**, and treats the diagonal *additively in log* and the strict-lower part
*additively*. The headline advantages over AIRM/log-Euclidean:

- **No swelling effect**: the determinant of the Fréchet mean stays between the
  min and max input determinants (AIRM and Euclidean can inflate it). Relevant if
  you ever *average* covariance estimates (bootstrap aggregation, multiple
  imputation), less so for a single fit.
- **Cheapest of the three**: closed-form, no eigendecomposition, parallel
  transport in closed form.
- It is *literally the geometry of your log-Cholesky parameterization*, so the
  Riemannian-gradient step in Lin's metric is the principled version of "take a
  gradient step in (log-diag, off-diag) coordinates and reconstruct Λ."

**The exact exponential-map / retraction formula (⌊L⌋, 𝔻(L), exp on the
diagonal) is in Lin 2019 §3–5; I could not extract it from the PDF through the
tool. VERIFY against arXiv:1908.09326 / SIAM J. Matrix Anal. 40(4):1353-1370
before coding.** The structure is: tangent step splits into a strict-lower
additive part and a log-diagonal additive part, recombined and squared to give a
PD matrix.

### Recommendation among (a)/(b)/(c)

For *your* setting — single 4×4 block, already in log-Cholesky, want PD-by-
construction + no overshoot + boundary robustness — **the practical choice is the
Tran/Nott/Kohn natural-gradient-Cholesky update of Idea 2** (it is the Fisher-
metric steepest ascent expressed in your existing chart, O(d²), and PD-safe).
Use the **AIRM geodesic step (a)** as a robust fallback specifically when a step
threatens to drive a variance component to the boundary, because AIRM's infinite-
distance-to-boundary property is the strongest guarantee against overshooting
into a near-singular Λ. Lin's log-Cholesky metric (c) is the most elegant and the
cheapest but the exact maps need verifying; it is the natural "v0.2 cleanup" of
the ridge patches.

**Status:** AIRM/log-Euclidean established and standard; Lin's log-Cholesky
established (peer-reviewed) but exact maps unverified here. **Cost:** AIRM low
(eigendecomp at 4×4); log-Cholesky low once the maps are confirmed.

---

## Idea 3 — Desingularising the removable singularity (pain point #2)

### What the singularity *is*, geometrically

At the symmetric init (ρ=0, Λ diagonal) the two responses decouple and the four
Cholesky entries that couple *response j's own mean with its own log-scale* are
exactly zero. You observe that *only* those gradient components blow up. That is
the textbook signature of a **removable (0/0) singularity in a centered
parameterization** — the random effect u enters scaled by an entry of L that is
itself zero, so the chain-rule derivative ∂L/∂(that entry) has a finite numerator
over a vanishing-scale denominator. Information-geometrically: at that point the
Fisher information has a *degenerate sub-block* (the map from those coordinates to
the distribution is locally non-injective), so the metric used to define the
gradient is singular along that fibre — and an unscaled gradient explodes while
the *natural* gradient (Idea 1, metric-rescaled) stays finite.

Two clean, well-established fixes; do (b) first (cheap, surgical), consider (a)
if (b) is fragile.

### (a) Non-centered / whitened parameterization (the structural cure)

Replace the centered latent representation `u ~ N(0, Λ ⊗ Σ_phy)` by the
**non-centered** one:

```
u = (L ⊗ C_phy) z,     z ~ N(0, I),     Λ = L Lᵀ,   Σ_phy = C_phy C_phyᵀ.
```

Now L multiplies z in the *numerator*; the dependence of the objective on the
coupling Cholesky entries is smooth and the 0/0 form disappears. This is exactly
the centered↔non-centered switch that removes "funnel" geometry in hierarchical
models (Papaspiliopoulos, Roberts & Sköld 2007; standard Stan/PyMC practice). The
trade-off is the usual one: non-centered is better when the data are *weakly*
informative about u (our near-boundary / small-variance regime — i.e. precisely
pain point #3), centered is better when data are strongly informative. Because
your hard region is the small-variance one, **non-centered is the right default
near the boundary.** Cost: medium — it changes the inner Laplace problem's
variables (and the Jacobian of the logdet term), so the exact gradient must be
re-derived in z-coordinates.

### (b) Analytic limit at the singular point (the surgical cure)

Since the singularity is *removable*, the gradient has a finite limit as
(ρ, off-diag-L) → 0. Compute that limit once by L'Hôpital / Taylor expansion of
the four offending components and hard-code it (or evaluate the gradient at a
tiny ε-perturbed point) whenever the init is within a tolerance of the symmetric
configuration. Concretely:

- detect `|ρ| < ε_ρ` AND `|off-diagonal L entries| < ε_L`;
- in that region, substitute the analytic limiting expression for the four
  components (or perturb ρ ← ε, off-diag ← ε, take the gradient, and let the
  optimizer step away — one step is enough to leave the measure-zero singular
  set, after which the ordinary exact gradient is finite again).

This is the same spirit as your existing `atanh_guarded` ρ-clamp (`0.99999999 *
tanh`) and log-SD floor: a tiny, principled nudge off a measure-zero bad set.
**Cost: low.** It is the minimum-change fix and I would ship it first.

### Why natural gradient *also* helps here

Note that Ideas 1–2 partially pre-empt this: the natural/Fisher-scaled gradient
divides the blowing-up Euclidean component by the same vanishing curvature that
created it, so the *natural* step at the symmetric init is finite where the
*Euclidean* one is not. The cleanest production setup is **natural gradient
(Idea 2) + the ε-nudge (3b)** — the nudge guarantees you are off the exact
singular fibre, and the natural scaling keeps the step finite and correctly sized
as you leave it.

**Status:** non-centered reparameterization — established (Papaspiliopoulos et
al. 2007; Betancourt & Girolami 2015). Removable-singularity limit — established
calculus; the *exact* limiting expressions for our model must be derived
(VERIFY by finite-difference at ε = 1e-3, 1e-4, 1e-5 and check convergence).
**Cost:** (b) low, (a) medium.

---

## Idea 4 — The identifiability boundary is a *singularity*, not a solver bug (pain point #3)

### Diagnosis from singular learning theory

When a variance component → 0 the model sits on the **boundary of the SPD cone**,
and there the map parameter → distribution is non-injective (the random effect
vanishes, so its correlations are unidentified). Watanabe's singular learning
theory (2009) is the rigorous account of exactly this situation: the Fisher
information is **degenerate** (rank-deficient), the log-likelihood is **not**
locally quadratic (it is a higher-order bowl), the Laplace approximation's
regularity assumptions fail, the MLE does not have a Gaussian distribution, and
**a plateaued gradient that never reaches 0 is the generic behaviour** — not a
bug. This is why *both* your Julia engine and the R/TMB baseline stall in the
same flat region with ‖g‖≈0.2–0.4: it is a property of the model's geometry, and
no optimizer change removes it.

Three practical consequences (all established, all cheap):

### (i) Change the stopping criterion in the flat region

A gradient-norm tolerance (‖g‖ < tol) is the *wrong* convergence test on a
singular plateau — it will report "false convergence" forever (which is exactly
what drmTMB's nlminb does: "false convergence (8)"). Switch to a **relative
objective-change** and **step-size** criterion there:

```
stop when  |L_{k+1} − L_k| / (|L_k| + 1) < tol_f   AND   ‖Δθ‖ < tol_x
```

This is what nlminb's `false convergence` flag is actually telling you — the
function has stopped improving even though the gradient is non-zero. Accept it as
convergence *to the boundary* rather than fighting it. Cost: trivial.

### (ii) Don't trust the Hessian SE at the boundary — use χ̄² / profile / bootstrap

On the boundary the (expected and observed) information is singular, so the
inverse-Hessian Wald SE is undefined — **this is the direct cause of drmTMB's
`sdreport` returning NaN** (`drmTMB-q4-numerical-recipes.md` §5: "Hessian not
positive definite → NaN SEs"). The correct inferential tools are non-standard:

- **Likelihood-ratio test for a zero variance component**: the null distribution
  is a **χ̄² (chi-bar-squared) = 50:50 mixture of a point mass at 0 and χ²₁** for
  one boundary component (Self & Liang 1987; Stram & Lee 1994), not χ²₁. For a
  q×q block going singular the mixture weights follow Shapiro (1985,1988).
- **CIs near the boundary**: use a **profile-likelihood** or **parametric-
  bootstrap** CI, not Wald. Your threaded bootstrap pipeline is *already* the
  right machine for this — it sidesteps the singular Hessian entirely. Frame the
  bootstrap not just as a speed win but as the *correct* inference tool here.

### (iii) Optional, advanced — model selection that tolerates singularity (WBIC)

If you ever need to *compare* models whose difference is a variance component
that may be 0 (e.g. "is the μ–logσ phylogenetic coupling real?"), classical
BIC/AIC are biased because they assume a regular model (penalty d/2·log n). The
singular-learning replacement is the **free-energy expansion**

```
F_n  ≈  n·L_n  +  λ·log n  −  (m−1)·log log n + O(1),
```

where **λ is the real log canonical threshold (RLCT)** and m its multiplicity;
for *singular* models **λ < d/2**, so the effective penalty is *smaller* than
BIC's. Watanabe's **WBIC** estimates this without knowing the truth:

```
WBIC  =  E_{w}^{β}[ n·L_n(w) ],     β = 1 / log n,
```

i.e. the posterior mean of the scaled negative log-likelihood at inverse
temperature 1/log n (one tempered posterior expectation — computable by the same
MCMC/bootstrap machinery). WBIC → BIC for regular models and is the correct
generalization for singular ones.

**Is there a known desingularizing reparameterization for variance-component
models?** Watanabe's *method* is resolution of singularities (Hironaka blow-up):
introduce new coordinates in which the degenerate likelihood factorizes into
monomials, making the integral tractable. For *factor-analysis / random-effects*
covariances specifically there is active work computing the RLCT (e.g. "Singular
Learning Theory for Factor Analysis," arXiv:2511.15419, which gives upper bounds
and exact RLCTs for special cases). **Practically**, the blow-up that matters for
*optimization* (as opposed to Bayesian model selection) is the same coordinate
change as Idea 3: the non-centered/whitened parameterization is a concrete,
implementable partial desingularization. A full algebraic resolution of your
specific q=4 phylo block is research-grade, not an engineering task — I would not
attempt it; the RLCT machinery's payoff for you is the *model-selection* formula
(iii) and the *diagnosis* (i)/(ii), not a magic reparameterization.

**Status:** χ̄² boundary asymptotics — established and classical (Self–Liang 1987;
Stram–Lee 1994; Crainiceanu & Ruppert 2004 for LMMs). Watanabe SLT/WBIC —
established (Watanabe 2009, 2013). The RLCT-for-our-model is **open / research-
grade** — flagged speculative. **Cost:** (i)/(ii) low; (iii) medium (needs a
tempered posterior); full desingularization — not recommended.

---

## Idea 5 — em-algorithm as dual projection: why the EM Λ-step is structurally wrong here

This is the information-geometry explanation of the bug you already diagnosed; it
has high *decision* value (it tells you not to invest in EM acceleration for Λ)
and low implementation value.

**The picture (Amari & Nagaoka 2000; Amari 1995).** In dually-flat coordinates,
let `M` be the model manifold (an e-flat / exponential family) and `D` the data
("observed") manifold (an m-flat / mixture family fixing the observed marginals).
The **em-algorithm** alternates two orthogonal projections:

- **e-step = e-projection** onto `D`: along an e-geodesic, orthogonal to `D` at
  the foot — this is the conditional-expectation step;
- **m-step = m-projection** onto `M`: along an m-geodesic, orthogonal to `M` —
  this is the maximization step.

Each projection decreases a KL divergence (the Pythagorean theorem in dually-flat
space), which is the geometric proof that EM monotonically improves its
*surrogate* objective Q.

**Two consequences for us:**

1. **Linear convergence is geometric.** The rate is governed by the "angle"
   between `M` and `D` at the fixed point (equivalently the curvature / the
   fraction of missing information). When the manifolds meet shallowly — large
   missing information, which is exactly the near-boundary small-variance regime —
   the projections inch forward and EM crawls (your 300+ iters). SQUAREM/Aitken
   accelerate by extrapolating along this nearly-linear trajectory; the geometry
   says there is *no* second-order EM trick that beats a true Newton/natural-
   gradient step on the marginal, because the slowness is intrinsic to alternating
   projection, not to the step computation.

2. **The EM (statistical) and em (geometric) algorithms coincide only when the
   relevant submanifold is flat / the posterior is in the exponential family.**
   Under the Laplace approximation your *effective* posterior on the nonlinear
   log-scale axes is **not** the exact Gaussian the m-projection assumes, so the
   m-step (the closed-form Λ MLE) is an exact ascent of the surrogate Q but
   **not** of the true marginal — it can *decrease* the true marginal. This is
   *precisely* your observed "EM ascends Q, the monotonicity guard rejects it
   because the true marginal drops, Λ freezes." The geometry names the cause:
   you are m-projecting onto the wrong (Gaussian-surrogate) manifold.

**Decision.** This *confirms* the route you already chose in `q4-sparse-status.md`:
ascend the **true** Laplace marginal directly for Λ (the TMB-like / natural-
gradient route of Ideas 1–2), and demote SQUAREM-EM to a robust **warm-start for
β** only. Do **not** spend effort on a geometric EM acceleration for the variance
components — the dual-projection view says the payoff ceiling is low and the
surrogate is biased exactly where you need it (the boundary). One legitimate
refinement the geometry *does* endorse: a **REML-flavoured projection** that
projects onto the model manifold *orthogonal to the fixed-effect directions*
(Idea 6) — that is the principled fix to the EM bias, and it is cheap.

**Status:** established theory (Amari–Nagaoka); the application to your Laplace-
surrogate bias is a sound inference but not something I found stated for this
exact model — call it well-grounded interpretation. **Cost:** conceptual; no new
code beyond what Ideas 1–2 already require.

---

## Idea 6 — ML vs REML through the information-geometry lens

**Why REML's variance estimates are less biased.** ML estimates the variance
components while *plugging in* the fixed effects, ignoring that the p_fixed df
spent on β were "paid for" out of the same data. Geometrically, ML m-projects
onto the full model manifold; **REML projects onto the submanifold orthogonal to
the fixed-effect (β) directions** — equivalently it integrates the likelihood
over the error contrasts (the residual space after projecting out X). That
orthogonal projection is exactly the "−½·logdet(I_ββ)" correction: it removes the
curvature contributed by the β-block from the variance-component information.
Concretely (matching your design note):

```
REML objective  =  ML Laplace marginal  +  ½ · logdet( I_ββ ),
```

with β profiled out, where I_ββ is the fixed-effects information block. Same
machinery as ML; one extra logdet term in the Λ update.

**Is the REML correction what makes the variance update well-behaved/fast?**
Partly — and this is the subtle point relevant to your overshoot. The REML
correction de-biases the variance *estimate* (especially at small p, where ML
shrinks variances toward 0 and thus *toward the singular boundary* — the very
region that is flat and ill-conditioned). By keeping the variance estimate away
from the boundary, REML keeps you out of the degenerate-Fisher region of Idea 4,
which makes the optimization better-conditioned. So the REML correction helps the
overshoot **indirectly** (better conditioning, less boundary-seeking), while the
*direct* cure for the overshoot is the natural-gradient/AI scaling of Idea 1.
The AI-REML literature (Idea 1) bundles both: it is REML (the correction) solved
by average information (the scaling).

**Recommendation (consistent with your existing decision).** Keep **ML as the
default** (model comparison via LRT/AIC needs comparable likelihoods across
different fixed effects — REML likelihoods are not comparable), and offer
`method = :REML` as the option for unbiased variance components, adding the
½·logdet(I_ββ) term. This is exactly what `q4-sparse-status.md` already
specifies; the information-geometry lens just explains *why* the REML projection
both de-biases and improves conditioning.

**Status:** established (Patterson & Thompson 1971; Harville 1977; the geometric
"projection orthogonal to fixed effects" view is standard). **Cost:** low (one
logdet term you can already compute).

---

## Japanese-language sources worth knowing

The major works are available in English, but a few Japanese sources carry
detail or pedagogy not well-covered in translation:

- **甘利俊一 (Amari Shun-ichi), 『情報幾何の方法』** (Iwanami, 1993; with Nagaoka).
  The Japanese precursor to *Methods of Information Geometry*. The dual-flat /
  e-m projection treatment of EM is developed more discursively than in the
  English book.
- **甘利俊一, 『情報理論』 / 『神経回路網の数理』**. The em-algorithm-for-neural-
  networks material (the 1995 RIKEN tech report) originates here; the
  missing-information / projection-angle convergence argument (Idea 5) is laid
  out in the Japanese lecture notes more explicitly.
- **渡辺澄夫 (Watanabe Sumio), 『代数幾何と学習理論』** (森北出版, 2006) and the
  newer **『ベイズ統計の理論と方法』** (コロナ社, 2012). The 2012 book is the most
  usable practical reference for RLCT computation, WBIC, and worked singular-model
  examples; substantially more applied detail than the 2009 Cambridge monograph.
  Watanabe's homepage hosts six lecture PDFs (some only fully detailed in
  Japanese) with explicit RLCT examples — e.g. the cited
  `λ = (h + j² + j)/(4j + 2)` form.
- **渡辺澄夫の講義資料 / 学生の論文** (e.g. Shaowei Lin's RLCT notes, in English,
  derived from this lineage). The factor-analysis RLCT work (arXiv:2511.15419)
  is the closest published analysis to a random-effects covariance singularity.

If someone on the team reads Japanese, the 2012 Watanabe book (Ch. on WBIC and
worked examples) and the Amari–Nagaoka Japanese EM chapter are the two with the
highest marginal value over the English literature for *this* project.

---

## References

**Natural gradient / Fisher scoring / information geometry**
- Amari, S. (1998). *Natural Gradient Works Efficiently in Learning.* Neural
  Computation 10(2):251–276.
- Amari, S. & Nagaoka, H. (2000). *Methods of Information Geometry.* AMS/Oxford.
  (Japanese original: 甘利・長岡, 岩波, 1993.)
- Martens, J. (2020). *New Insights and Perspectives on the Natural Gradient
  Method.* JMLR 21(146). (Natural gradient ↔ Gauss–Newton ↔ Fisher.)
- KL = Kenneth Lange, *Numerical Analysis for Statisticians*, Ch.14 (Newton &
  Fisher scoring; canonical-link equivalence).
- Exponential-family duality (F = ∇²A(θ), μ = ∇A(θ), natural grad = mean-param
  grad): <https://antixk.github.io/blog/nat-grad-exp-fam/> and
  <https://andrewcharlesjones.github.io/journal/natural-gradients.html>.

**AI-REML / variance components**
- Gilmour, A.R., Thompson, R. & Cullis, B.R. (1995). *Average Information REML:
  An Efficient Algorithm for Variance Parameter Estimation in Linear Mixed
  Models.* Biometrics 51(4):1440–1450.
- Meyer, K. (1997). *An "Average Information" REML algorithm…* (Genet. Sel. Evol.)
  <https://faculty.washington.edu/tathornt/BIOST551/articles_2012/AI_Meyer.pdf>
- Computationally-efficient AI-REML, genomic era (2024), Genet. Sel. Evol.:
  <https://link.springer.com/article/10.1186/s12711-024-00939-x> /
  <https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11580194/>
- Patterson, H.D. & Thompson, R. (1971); Harville, D. (1977) — REML foundations.

**SPD-manifold geometry**
- Lin, Z. (2019). *Riemannian Geometry of SPD Matrices via Cholesky
  Decomposition.* SIAM J. Matrix Anal. Appl. 40(4):1353–1370.
  <https://arxiv.org/abs/1908.09326> (**VERIFY exact exp-map/retraction here**).
- Pennec, X., Fillard, P. & Ayache, N. (2006). *A Riemannian Framework for Tensor
  Computing.* IJCV 66(1):41–66. (Affine-invariant exp/log/distance.)
  Lecture notes: <https://www-sop.inria.fr/asclepios/cours/MVA/chapter3.pdf>
- Arsigny, V. et al. (2006). *Log-Euclidean metrics for fast and simple calculus
  on diffusion tensors.* Magn. Reson. Med. 56(2):411–421.
- Tran, M.-N., Nott, D. & Kohn, R. (2021). *Analytic natural gradient updates for
  Cholesky factor in Gaussian variational approximation.*
  <https://arxiv.org/abs/2109.00375> (HTML v9:
  <https://arxiv.org/html/2109.00375v9> — Theorem 1, Lemma 1; the O(d²) update).
- SPD-learning survey (AIRM boundary-completeness): <https://arxiv.org/abs/2504.18882>.

**EM as dual projection**
- Amari, S. (1995). *Information Geometry of the EM and em Algorithms for Neural
  Networks.* Neural Networks 8(9):1379–1408.
- "Geometry of EM and related iterative algorithms" (2022):
  <https://arxiv.org/abs/2209.01301>.
- "The EM Algorithm in Information Geometry" (2024):
  <https://arxiv.org/abs/2406.15398>.

**Singular learning theory / boundary asymptotics**
- Watanabe, S. (2009). *Algebraic Geometry and Statistical Learning Theory.*
  Cambridge. (Japanese: 渡辺, 『代数幾何と学習理論』, 森北, 2006; applied:
  『ベイズ統計の理論と方法』, コロナ社, 2012.)
- Watanabe, S. (2013). *A Widely Applicable Bayesian Information Criterion
  (WBIC).* JMLR 14:867–897. <https://jmlr.org/papers/v14/watanabe13a.html>
- "Singular Learning Theory for Factor Analysis" (2025):
  <https://arxiv.org/abs/2511.15419> (RLCT for covariance/loadings models).
- Shaowei Lin, *Singular Learning Theory* notes (RLCT, resolution of
  singularities): <https://shaoweilin.github.io/public/cmnd2RLCT.pdf>
- Self, S.G. & Liang, K.-Y. (1987). *Asymptotic properties of MLE and LRT under
  nonstandard conditions.* JASA 82:605–610.
- Stram, D.O. & Lee, J.W. (1994). *Variance components testing in the longitudinal
  mixed-effects model.* Biometrics 50:1171–1177. (χ̄² for zero variance.)
- Shapiro, A. (1985, 1988) — general χ̄² mixture weights on the boundary.
- Crainiceanu, C. & Ruppert, D. (2004). *LRTs in LMMs with one variance
  component.* JRSS-B 66:165–185.

**Reparameterization / desingularization**
- Papaspiliopoulos, O., Roberts, G.O. & Sköld, M. (2007). *A general framework
  for the parametrization of hierarchical models.* Statistical Science 22:59–73.
  (Centered vs non-centered.)
- Betancourt, M. & Girolami, M. (2015). *Hamiltonian Monte Carlo for hierarchical
  models.* (Funnel geometry; the small-variance regime favours non-centered.)

---

*Compiled 2026-05-30. Confidence: Ideas 1, 2, 4(i–ii), 6 rest on established,
proven methods and are safe to implement. Idea 2's index conventions and Idea
2b(c)'s Lin log-Cholesky maps need source-PDF verification (flagged). Idea 3(b)'s
exact limiting expressions must be derived and finite-difference-checked. Idea
4(iii) WBIC is established but a larger build; full algebraic desingularization of
the q=4 block is research-grade and not recommended as an engineering task.*
