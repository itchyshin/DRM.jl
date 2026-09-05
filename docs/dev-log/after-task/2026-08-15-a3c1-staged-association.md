# After-task — A3c-1: staged association, `gaussian_bernoulli`

Date: 2026-08-15 · lane: DRM.jl (Claude) · arc A3c-1 · anchor drmTMB **0.7.0**

## What shipped

`src/associate_pairs.jl` — `associate_pairs()`, `latent_normal()`,
`association()`, `PairAssociation`. The staged, frozen-margin latent-normal
association for the **`gaussian_bernoulli`** pair class.

Estimated 0.5–1 day in the A3c design pass; landed inside that.

## Why this pair class first

It is the only one of drmTMB's five reviewed classes whose likelihood is
**closed form**. The Gaussian margin's latent is *observed exactly*
(`z = (y − mu)/sigma`), so the Bernoulli's contribution is a conditional
univariate normal CDF at a shifted threshold. No rectangle probability, no
quadrature — and therefore **no new dependency**, while still exercising the
entire staged architecture (freeze → associate → optimise → diagnose).

The other four classes censor *both* latents and need a 1-D adaptive integral
with a retained error estimate; they are deferred to A3c-2 and the `QuadGK.jl`
decision, and they **error rather than silently approximating**.

## Estimator, mirroring drmTMB

- `eta = 0.999999·tanh(alpha)`, `alpha` bounded to `[-8, 8]`.
- **Multistart** from `-1, 0, 1` — the profile is not assumed unimodal.
- **Finite-difference score and curvature** at the optimum (`h = 1e-4`), and no
  report at all when the optimum sits on the box boundary.
- `near_boundary` when `|eta| ≥ 0.995`; `multistart_disagreement` when the three
  optima differ beyond `1e-7·(1+|obj|)`.

**Sign convention checked, not assumed:** drmTMB's `curvature` negates the
objective's second difference, so it is the *loglikelihood* curvature and is
**negative** at a maximum. A test pins that sign — reporting `+826` where the
twin reports `−826` would be a silent parity break.

## Evidence

Rather than trust one seed, an 8-seed check at n = 3000:

```
eta: [0.5225 0.5459 0.5331 0.5483 0.5565 0.5412 0.5505 0.5482]
mean 0.5433   sd 0.0108   true 0.55   bias -0.0067
```

Essentially unbiased, and the test tolerance (0.05 ≈ 4 sd) is derived from that
measurement rather than picked to make a single run pass. Score ≈ 0 at the
optimum; curvature negative.

## Refusals are tested, not just the happy path

A staged route that silently accepts an unreviewed pair class is worse than one
that errors. Tested refusals: implicit kernel; gaussian × poisson and
gaussian × gaussian (not among the five reviewed classes); a non-Bernoulli
binomial margin (trials > 1); a varying `association` formula.

## The limitation, carried in the result object

`association()` returns
`uncertainty = "conditional on frozen margins; experimental"`, and a test
asserts the wording contains both "conditional" and "frozen". Because the
margins are treated as exact, the association's standard error **ignores margin
estimation error** — it is not a joint SE. Matching drmTMB, no simultaneous
`eta` bands and no profile intervals are offered.

## Not claimed

No parity fixture against drmTMB's own `associate_pairs()` yet — the R side
needs two fitted margins plus the staged call, which the current
`tools/parity_fixture.R` harness does not construct. That comparison is the
natural first task of A3c-3 and is **not** asserted here.

## Next

- **A3c-2** — the four quadrature pair classes. **Blocked on an owner decision:**
  may DRM.jl take `QuadGK.jl` as a dependency? Without it the integration-error
  diagnostics drmTMB reports cannot be matched.
- **A3c-3** — diagnostic/warning parity plus the R-side parity fixture.
