# Plan vs actual — the overnight run (2026-08-15 → 16)

Brief: *"go till 5am, do as much as possible, you make the best decisions."*

This is the reconciliation, written to the same standard as the A4 one: it
surfaces **drift and error**, not a list of wins. The wins are in the PRs.

## The one decision I made and did not take back

**drmTMB #1049 (binomial × phylo) is open, green, and NOT merged.** It changes
the structured-effect gate in a release-candidate repo with nine live lanes —
precisely what the STOP gate exists for. Merging it unattended at 3am would have
been the single irreversible act of the night, and "best decisions" at 3am means
leaving a reviewed thing for daylight rather than being maximally productive.

Everything else ran, because everything else is reversible: a PR can be closed, a
branch deleted, an issue edited.

## Shipped

| # | arc | state |
|---|---|---|
| [#419](https://github.com/itchyshin/DRM.jl/pull/419) | A6 tree-scale: `phylo_tree_height` + fit-time warning | armed |
| [#420](https://github.com/itchyshin/DRM.jl/pull/420) | loop checkpoint (items 1–4) | armed |
| [#421](https://github.com/itchyshin/DRM.jl/pull/421) | rosetta `corpair` fix | armed |
| [#423](https://github.com/itchyshin/DRM.jl/pull/423) | **A8 bivariate meta `V_known`** + meta-analysis guide | armed |
| [#424](https://github.com/itchyshin/DRM.jl/pull/424) | A9 general-covariance audit | armed |
| [#425](https://github.com/itchyshin/DRM.jl/pull/425) | **A10 boundary polish (#422)** + Binomial refusal | armed |
| [#418](https://github.com/itchyshin/DRM.jl/pull/418) | A5 non-Gaussian phylo parity | **merged** |
| drmTMB [#1049](https://github.com/itchyshin/drmTMB/pull/1049) | binomial × phylo | **open, gate held** |
| drmTMB [#1032](https://github.com/itchyshin/drmTMB/pull/1032) | registry evidence | **merged** |
| DRM.jl [#422](https://github.com/itchyshin/DRM.jl/issues/422) | under-convergence, root-caused **and fixed** | fix in #425 |

## Where the plan was wrong

**"The C++ is family-generic" — I said that, and it was wrong.** Sizing #1048 I
reported zero family-conditioned structured branches in `src/drmTMB.cpp` and
concluded the work was R-side only. Model 18 (binomial) builds its own `eta_mu`
and never read the phylo field; it needed the ordinal branch's block ported. My
grep answered a narrower question than the one I asked of it.

**And the real blocker was in neither layer I predicted.** `make_tmb_data`
hard-coded `has_phylo_mu = 0L` for binomial, silently discarding a parsed,
*validated*, stored structure at data assembly and leaving free `u_phylo`
parameters entering nothing. That surfaced only as an `NA/NaN gradient` when I
ran the fit. Three layers, and I had predicted one.

**A8 was refused in the A4d design pass and shipped tonight.** That refusal was
correct *at the time* — "the output would have no consumer" — and the way to
change it was to build the consumer, not to reclassify the verdict.

## Errors I made, and how each was caught

Recorded because the catches are the reusable part.

| error | caught by |
|---|---|
| Chased a **~30% variance-component "bias"** that was my own DGP's tree scale — the **A4c trap, walked into again the same day, after documenting it** | checking a suspicious magnitude against a mechanism (√h) before reporting |
| `0/30 converged` beside 30 summary values — Julia's top-level `for` makes `conv += 1` a *local* while `push!` mutates | the internal contradiction; impossible outputs are a gift |
| Boundary-polish patch matched **7** call sites, 4 with q≥2 variance blocks where "log_sd is last" is **false** | an assertion on the expected count, before any write |
| A test threshold assuming the polish floor always engages | it doesn't on every seed — **corrected the test, not the code** |
| Unnamed `K` in the A9 audit — drmTMB rejects before reaching its gate | results implausibly uniform across families |
| Split test specs on `|`, colliding with `(1|species)` | three bogus "REFUSED" lines that didn't match the source |
| **Armed auto-merge on #425, then pushed a second commit** | noticed on review; PR body corrected to describe both changes |

The pattern in the first four: **when a measurement indicts the package, suspect
the measurement first.** It was wrong four times out of four tonight.

## The counterweight

Two guards fired *before* damage: the 7-vs-4 assertion, and the A5 baseline cell
that caught the tree-scale mismatch as a units error rather than an engine bug.
Both were cheap to write and each saved a wrong claim.

## What is NOT done

- **drmTMB #1049 unmerged** — deliberate; yours.
- **No full `R CMD check`** on #1049 (five targeted files only, 12 + 301 assertions).
- **Six DRM.jl PRs unmerged**, saturating the CI queue. I stopped opening new
  ones once that was visible; they land on green. **A6/A8/A10 all insert after
  the same anchor in `test/runtests.jl`** — whichever merges second will
  conflict, and that is expected, not a fault.
- **`meta_vcov_bivariate` ledger entry** removed on #423 only; the countdown
  reads raw 18 until that merges.
- **A2b, A-tag, `corpair`, `engine_control_surface`** — still gated.
- **The 11 capability rows remain un-`supported`.** Nothing tonight promoted
  anything; promotion is drmTMB's claim decision. A5, A8 and A9 produced
  *evidence*, which is the input to that decision, not a substitute for it.

## The measurement that actually moved

Not the export countdown (still 0 owed, as it was). What moved is that three
capability rows now have comparators where none existed: `phylo_gamma_beta_binomial`
(2 of 3 families, the third having no native comparator at all — filed as
drmTMB#1048 and fixed in #1049), `general_covariance_structured` (full family
table, one asymmetry found), and the bivariate meta path (3/3, plus an
independent MVN anchor).
