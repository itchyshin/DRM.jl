# Laplace Speed Scout

This note records algorithm signals from Julia's GLM / mixed-model ecosystem
that are relevant to the DRM.jl sparse-Laplace engine. It is a design note, not
a benchmark claim.

## What To Borrow

- **GLM.jl pattern:** fit GLMs as direct matrix problems with explicit
  convergence controls, line-step controls, offsets, and starting values. The
  practical lesson for DRM.jl is to make starting values and warm-started
  weighted least-squares steps first-class, not incidental optimizer state.
  Source: https://juliastats.org/GLM.jl/v1.2/api/
- **MixedModels.jl PIRLS pattern:** GLMM conditional modes are determined by
  penalized iteratively reweighted least squares. DRM.jl's inner mode solver is
  already a PIRLS/Newton equivalent for scalar crossed random intercepts; the
  next speed pass should cache and update the weighted crossed Hessian instead
  of rebuilding dense arrays every inner iteration.
  Source: https://juliastats.org/MixedModels.jl/dev/api/
- **MixedModels.jl blocked sparse pattern:** the mixed-model objective is
  organized around mutating model state and updating Cholesky factors under new
  covariance parameters. DRM.jl should move from the current proving-slice dense
  `Hinv` to selected inverse / block solves for larger `q`, matching the q=4
  Takahashi discipline.
  Source: https://github.com/JuliaStats/MixedModels.jl
- **Bootstrap/profile ergonomics:** MixedModels.jl treats bootstrap and profile
  workflows as refit pipelines with optimizer controls. DRM.jl should expose
  warm starts and relaxed bootstrap optimizer tolerances in benchmark scripts
  before claiming pipeline speed.
  Source: https://juliastats.org/MixedModels.jl/dev/api/

## Immediate DRM.jl Consequences

- Single-fit crossed Poisson is already fast; the next single-fit work is
  generality and exact nuisance-parameter handling for NB2/Gamma/Beta. Fixed
  Binomial and NB2 kernels are already clean in the internal sweep; Gamma
  recovers parameters but needs convergence-diagnostic work on larger cells;
  Beta is correct on the recovery test but slower because each observation
  evaluates digamma/trigamma/polygamma.
- Profile-likelihood CIs on crossed Gaussian models are now the clearest local
  slow path: `bench/profile_inference_quick.jl` shows profile CI taking orders
  more than one crossed fit because each endpoint refits nuisance parameters.
  Bench-only prototypes preserved endpoints exactly on the test fixture:
  warm-starting reduced crossed-profile time from 8.04 s to 5.82 s, and
  threaded warm profiling on 4 Julia threads reduced it to 2.56 s. This is the
  concrete next inference implementation target.
- For fixed-q large-n cells, the engine should get faster per observation as
  `n` grows because the expensive factorization dimension is `q = G + H`, while
  the observation loop is linear and cache-friendly. The family-profile report
  keeps that check explicit.
- The next algorithmic target is a mutable crossed-Hessian workspace:
  preallocated `grad`, `H`, work vectors, and family derivative buffers, then a
  selected-inverse derivative path for larger crossed structures.
- The Beta-specific target is derivative cost: either cache stable special-
  function pieces within each objective evaluation or derive a cheaper
  fixed-precision approximation suitable for warm-started outer optimization.

## Guardrails

- Do not claim NB2/Gamma/Beta drmTMB parity from the current family sweep; those
  rows fix the nuisance parameter to isolate the mean-side crossed-Laplace
  engine.
- Do not cite or reference private uploaded manuscripts in code or reports.
- Treat public formula routing for additional families as a later coordinated
  front-end slice.
