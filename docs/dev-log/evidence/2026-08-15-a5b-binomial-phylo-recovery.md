# A5b — recovery evidence for Binomial × phylo, and two simulator bugs of my own

Date: 2026-08-15 · lane: DRM.jl (Claude, arc-loop) · relates to [drmTMB#1048](https://github.com/itchyshin/drmTMB/issues/1048)

## Why

drmTMB's structured-effect gate says non-Gaussian structured routes *"remain
deferred until **family-specific recovery evidence is stable**."* So the blocker
on wiring `binomial × phylo` is **evidence, not code** — and DRM.jl already
implements the route, so the evidence is producible here.

## Result — recovery is good

Unit-height tree, 30 replicates, `β0 = 0.3`, `β1 = 0.8`, `sd_phylo = 0.7`,
12 observations per tip, Bernoulli response.

| G (tips) | n | converged | `sd_phylo` bias | `β1` bias | `β0` bias |
|---|---|---|---|---|---|
| 40 | 480 | 30/30 | −8.9% (1.4 MCSE) | +1.7% | −34.7% |
| 80 | 960 | 30/30 | −9.5% (1.8 MCSE) | −1.8% | −12.3% |
| 160 | 1920 | 30/30 | **−0.1%** | +0.3% | +31.6% |

- **The slope recovers cleanly at every size** (|bias| ≤ 1.8%).
- **The phylo SD is essentially unbiased by G = 160**, with a modest ~9%
  attenuation at G = 40–80 that is ~1.4–1.8 MCSE and shrinks with tips — the
  expected small-sample behaviour of a Laplace approximation on binary data, not
  a defect.
- **The intercept is noisy, not clearly biased.** The percentages look alarming
  only because the true value is 0.3; in MCSE units the deviations are 1.6, 0.8
  and 2.1, and they do not move in one direction. Thirty replicates is too few to
  say more, and this note does not.

**Read against the gate's own standard, this is what "stable recovery evidence"
looks like** for the parameters the route is fitted for.

## Two simulator bugs — both mine, both nearly reported as package defects

This is recorded because the corrections are more instructive than the result.

**1. "0/30 converged" — a Julia scoping bug.** The first run reported zero
convergences alongside thirty summary values, which is impossible. Cause:
`conv += 1` inside a top-level `for` creates a **local** binding in Julia, while
`push!` *mutates* and therefore worked. The fits had converged all along; only
the counter was lost. The contradiction between "0 converged" and "30 values" is
what exposed it — worth noticing rather than reading past.

**2. A ~30% "bias" that was the tree-scale trap, again.** The first corrected run
showed `sd_phylo` biased −25.6% / −31.6% / −29.4%, apparently not shrinking with
G. That is a serious-looking claim about the package. It was wrong: the DGP built
`u` from the **correlation** matrix while DRM.jl estimates on the **raw
branch-length** scale, whose tip variance is the tree height `h`. Predicted
inflation from `sqrt(h)` alone:

| G | h | predicted "bias" | observed |
|---|---|---|---|
| 40 | 1.50 | −18.4% | −25.6% |
| 80 | 1.75 | −24.4% | −31.6% |
| 160 | 2.00 | **−29.3%** | **−29.4%** |

At G = 160 the entire effect is the scale mismatch. Normalising the tree to unit
height gives the table at the top.

**This is the A4c finding, which this same lane documented earlier today, walked
into a second time.** Writing a lesson down does not prevent repeating it; the
thing that caught it was checking a suspicious magnitude against a mechanism
before reporting it. The reflex worth keeping is: *when a simulation indicts the
package, suspect the simulator first.*

## What this evidence supports, and what it does not

- It **supports** wiring `binomial × phylo` in drmTMB: the route recovers its
  parameters, so the gate's stated blocker is addressable.
- It is **DRM.jl** evidence. It says the Laplace route for binary + phylo behaves;
  it is not a statement about a drmTMB implementation that does not yet exist.
- It covers **Bernoulli with a unit-height balanced tree, 12 obs/tip, one slope**.
  Not the two-column form, not `relmat`/`animal`/`spatial`, not varying
  `sd_phylo`, not coverage of intervals — only point recovery.
- **30 replicates.** Enough to see a ~9% attenuation against ~1.5 MCSE; not
  enough to characterise the intercept.
