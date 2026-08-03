# Design note — #166 beta-binomial sparse-Laplace kernel

**Scope:** constant-σ (overdispersion) beta-binomial only. Derives the
`:betabinomial_fixed` analytic derivative kernel for `src/sparse_laplace_glmm.jl`
by generalizing the verified `:beta_fixed` kernel (`src/beta.jl` /
`_laplace_v123(::Val{:beta_fixed}, …)`) from Beta's continuous data term to
beta-binomial's discrete known-trials data term.

## Likelihood

Beta-binomial pmf for successes `s` out of `n` trials, logit-mean `μ`,
precision `φ = 1/σ²`, shape parameters `a = μφ`, `b = (1-μ)φ`:

```
P(S=s) = C(n,s) · B(s+a, n-s+b) / B(a,b)
log P  = logchoose(n,s) + loggamma(s+a) + loggamma(n-s+b) - loggamma(n+φ)
                         - loggamma(a) - loggamma(b) + loggamma(φ)
```

(using `a+b = φ`). `NLL_i = -log P`. Write `sa = s+a`, `nsb = (n-s)+b`.

## Mean-axis derivatives (η → μ = logistic(η), φ fixed)

Define, for any pair `(x, y)`:

```
A(x, y) = φ · (digamma(x) - digamma(y))
B(x, y) = φ² · (trigamma(x) + trigamma(y))
C(x, y) = φ³ · (polygamma(2,x) - polygamma(2,y))
```

`:beta_fixed`'s kernel is `A(a,b) - φ·ylogit`, `B(a,b)`, `C(a,b)` (the data term
`ylogit = logit(y)` is a μ-independent constant since Beta's data `y` doesn't
shift with `a`/`b`). Beta-binomial's discrete data term does shift with
`a`/`b` — the "shifted digamma/trigamma/polygamma" from the headline — so the
whole `(a,b)` form gets a shifted-argument counterpart evaluated at `(sa,
nsb)`, not a scalar subtracted constant:

```
d(NLL)/dμ   = A(a,b) - A(sa, nsb)   =: A_bb
d²(NLL)/dμ² = B(a,b) - B(sa, nsb)   =: B_bb
d³(NLL)/dμ³ = C(a,b) - C(sa, nsb)   =: C_bb
```

Chain-ruled through the logistic link exactly as `:beta_fixed` (`v = μ(1-μ)`,
`vp = v(1-2μ)`, `vpp = v(1-2μ)² - 2v²`):

```
d1(η) = A_bb · v
d2(η) = B_bb · v² + A_bb · vp
d3(η) = C_bb · v³ + 3·B_bb·v·vp + A_bb·vpp
```

Derived by direct differentiation of `log P(μ)` (chain rule through
`a=μφ, b=(1-μ)φ, sa=s+a, nsb=(n-s)+b`; `∂a/∂φ=μ`, `∂sa/∂φ=μ`, etc., held fixed
here since these are the μ-only partials at fixed φ) — see the arithmetic
worked out in the S1/Noether pass; cross-checked against the `:beta_fixed`
special case by confirming `A_form(a,b)` alone (the non-shifted half)
reproduces `:beta_fixed`'s existing, verified formula term-for-term.

## Nuisance-axis (φ) derivatives, constant-σ only

Needed for the phylo/crossed *nuisance* Laplace spine (φ estimated jointly
with the random effects, not profiled). By Clairaut's theorem the φ-mixed
partials of the same log-density reuse the mean-axis machinery:

```
dL   = d(NLL)/dφ  = digamma(n+φ) - digamma(φ) + μ·(digamma(a)-digamma(sa))
                                                + (1-μ)·(digamma(b)-digamma(nsb))
dA   = ∂A_bb/∂φ   = (digamma(a)-digamma(b)-digamma(sa)+digamma(nsb))
                    + φ·μ·(trigamma(a)-trigamma(sa))
                    - φ·(1-μ)·(trigamma(b)-trigamma(nsb))
dB   = ∂B_bb/∂φ   = 2φ·[(trigamma(a)+trigamma(b))-(trigamma(sa)+trigamma(nsb))]
                    + φ²·μ·(polygamma(2,a)-polygamma(2,sa))
                    + φ²·(1-μ)·(polygamma(2,b)-polygamma(2,nsb))
```

Chained to `ψ = log σ` (`φ = exp(-2ψ)`, `dφ/dψ = -2φ`) exactly as `:beta_fixed`:

```
nuisance_value(η) = -2φ·dL
nuisance_d1(η)     = -2φ·dA·v
nuisance_d2(η)     = -2φ·(dB·v² + dA·vp)
```

## Aux struct (`:betabinomial_fixed`)

Mirrors `_beta_laplace_setup`'s `aux_from(logsigma)` closure shape exactly:

```julia
aux = (s = sint, ntr = nint, logchoose = logchoose,       # data-only, precomputed once
       precision = φ, lgamma_nphi = loggamma.(ntr .+ φ),  # φ-dependent, rebuilt per outer iterate
       lgammaφ = loggamma(φ), digammaφ = digamma(φ))
```

`lgamma_nphi[i] = loggamma(n_i + φ)` is the one φ-dependent *and*
per-observation precompute the Beta kernel didn't need (Beta has no trials
axis); everything else — `precision`, `lgammaφ`, `digammaφ` — is scalar,
identical in shape to `:beta_fixed`'s aux.

## Value

```
value_i = -(logchoose_i + loggamma(sa) + loggamma(nsb) - lgamma_nphi_i
            - loggamma(a) - loggamma(b) + lgammaφ)
```

## Verification plan (S2/S4)

Analytic-vs-FD outer gradient ≤ 1e-6 on both the phylo and crossed routes
(the CLAUDE.md engine bar) is the actual proof obligation — the algebra above
is scaffolding for writing the kernel correctly the first time, not a
substitute for the FD check. Parameter-recovery tests follow the existing
`test_beta_phylo_laplace.jl` / `test_binomial_phylo_laplace.jl` shape.
