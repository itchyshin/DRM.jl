# A3c-3 found a real DRM.jl bug: the NB2 margin fitter does not converge

Date: 2026-08-15 · lane: DRM.jl catch-up · arc A3c-3 · anchor drmTMB **0.7.0**

## What the parity harness found

`tools/parity_associate.R` compares drmTMB's `associate_pairs()` against DRM.jl's
on identical data. Two classes match to 2e-8; **every class involving NB2 was
attenuated**:

| pair class | drmTMB | DRM.jl | verdict |
|---|---|---|---|
| `gaussian_bernoulli` | 0.5552349 | 0.5552349 | **PASS** (2.7e-08) |
| `bernoulli_bernoulli` | 0.5389335 | 0.5389335 | **PASS** (1.9e-08) |
| `gaussian_nbinom2` | 0.5759 | 0.4184 | **FAIL** |
| `bernoulli_nbinom2` | 0.5932 | 0.4435 | **FAIL** |
| `nbinom2_nbinom2` | 0.5818 | 0.4231 | **FAIL** |

## The cause is NOT the association code

Checked in order, each against the artefact rather than assumed:

1. **Latent intervals are correct.** `_assoc_nb2_endpoints` matches drmTMB's
   `drm_pair_nbinom2_endpoints` to **5e-6** on identical `(y, mu, sigma)` — and
   that residual is just the 5-decimal rounding of R's printed reference.
2. **The likelihood is correct.** Evaluated with TRUE margins it peaks exactly at
   the true `eta = 0.55`.
3. **The margin fit is wrong.** On the failing data:

```
DRM.jl  nb2 coef: [1.421, -0.1894, -14.4011]   converged: FALSE   logLik -3200.76
drmTMB  nb2 coef: [1.4214, -0.1869,  -0.5507]                     logLik -2909.55
```

`log σ = −14.4` ⇒ `σ ≈ 5.6e-7` ⇒ NB2 size `= 1/σ² ≈ 3.2e12`: the dispersion has
**collapsed to the Poisson boundary**. The data is genuinely overdispersed
(mean 4.235, variance 10.857), and drmTMB fits it without trouble. DRM.jl's fit
is 291 logLik units worse and **reports `converged = false`**.

So the association code faithfully consumed a broken frozen margin. Narrower
latent intervals ⇒ attenuated association.

## Two separate defects

**1. DRM.jl's NB2 fitter fails to converge here — NOT fixed in this arc.** It is a
family/optimiser bug in `src/negbinomial.jl`, outside A3c's scope, and it needs
its own arc with its own evidence. Note the earlier `fe_nbinom2` parity cell
PASSES (coef diff 2.8e-08) on `rnbinom`-drawn data, so this is data-dependent
fragility rather than a blanket failure — which is exactly why a single passing
fixture did not catch it.

**2. `associate_pairs` froze a non-converged margin without checking — FIXED.**
This one is mine. A staged estimator conditions on its margins as if exact, so a
non-converged margin is silently load-bearing. `_assoc_require_converged` now
refuses both fits up front, naming the margin and saying why. `is_converged` was
already returning `false` — the information was there and simply was not read.

## RESOLVED — the seed was on the wrong scale

The MoM initialiser computes the NB2 **size** `r = m²/(v − m)`, but the parameter
it seeds is `eta_sigma = log(sigma)`, where `r = exp(-2·eta_sigma)`. The correct
conversion is `eta_sigma = -0.5·log(r)`. **The `-0.5` was missing at six sites.**

On the failing data (m = 4.235, v = 10.857 ⇒ r_MoM = 2.71):

| | seed sigma | seed size r |
|---|---|---|
| correct (`-0.5·log r`) | 0.608 | 2.71 |
| buggy (`log r`) | 2.71 | **0.136** |

A 20× error in the wrong direction. LBFGS recovered on many datasets — which is
exactly why the suite stayed green while a whole region of dispersion space
converged to the Poisson boundary.

After the fix, on the same data: `converged = true`, coef
`[1.4214, -0.1868, -0.5507]` against drmTMB's `[1.4214, -0.1869, -0.5507]`, and
logLik `-2909.5454` against `-2909.545`.

**Staged parity is now 5/5 PASS** (max diff 4.4e-07), up from 2/5.

Guarded by `test/test_nb2_dispersion_seed.jl`, which pins the seed SCALE with a
dispersion sweep either side of `sigma = 1` — the bug is a scale error, so it
worsens as dispersion moves away from 1.

## Status of the arc

The staged association is **parity-verified for the two pair classes whose
margins fit correctly** (2e-8). The three NB2 classes **cannot be parity-claimed**
until the NB2 margin bug is fixed — and they now error rather than returning an
attenuated number.

`docs/dev-log/evidence/parity-associate.tsv` records the measured table.
