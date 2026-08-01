# Handover → Codex team (GLLVM.jl + gllvmTMB twin)

You're running from **`/Users/z3437171/Dropbox/Github Local/DRM.jl`**. The GLLVM.jl +
gllvmTMB work is in sibling folders. **All paths below are absolute** so you can
reach them from DRM.jl. Nothing here needs DRM.jl changes — it's a status + map.

## Repos / worktrees / branches (absolute)

| What | Path | Branch @ tip |
|---|---|---|
| GLLVM.jl (Julia engine), main checkout | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` | `codex/non-gaussian-fitter-gradients` |
| **Build worktree (this session's work)** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl-fullcap` | `full-capability` @ `3d39f85` |
| integration worktree | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration` | `integration` |
| gllvmTMB (R package) | `/Users/z3437171/Dropbox/Github Local/gllvmTMB` | `engine-julia` @ `f046d0f` |

Julia: `/Users/z3437171/.juliaup/bin/julia` (1.10 default). **CI primary = 1.12**: `~/.juliaup/bin/julia +1.12`.
Be a good neighbour on the shared box: `OPENBLAS_NUM_THREADS=2 JULIA_NUM_THREADS=4`.

## What landed (verified on Julia 1.10 AND 1.12)

**GLLVM.jl — merged to `integration` via PR #100 (merge `65a1f10`):**
- `1884b41` T1 missing responses (masked analytic gradient)
- `a24d443` T2 `mi()` for NB/Gamma/Beta
- `0d26398` T3 multiple missing predictors (joint)
- `e6e8f6f` T4 non-Gaussian coevolution (`K*` Laplace; Γ recovery |cor|≈0.98)
- `9e3a79e` `test_twolevel` 1.12 robustness fix
- `0b39bd5` capability NA-masks (COM-Poisson/Tweedie/ordered-beta/beta-binomial + covariate wrappers)
- `4b95b73` **bridge CIs** — `bridge_fit` returns Wald/profile/bootstrap (66/66 both Julias)
- `3d39f85` **bridge X** — fixed-effect covariates for all one-part families (50/50 both Julias)
- Full suite: `Pkg.test()` **3605/0** (1.10) · `runtests.jl` **3593/0** (1.12).

**gllvmTMB — LOCAL on `engine-julia`, NOT pushed (maintainer gates gllvmTMB pushes):**
- `908993d` `confint.gllvmTMB_julia` — R surfaces engine CIs (38/0 live, parity EXACT 0.0)
- `f046d0f` #488 gate-drift fix — relax `engine="julia"` X gate to the 6 X-capable families (47/0 live)

## Merge chain — current state

- **PR #100** full-capability→integration: **MERGED** (`65a1f10`).
- **integration CI** (post-merge, run `27506960385`): **in progress** at handover (~21 min; Documenter green). This is the gate for #95. Expected green — the `test_twolevel` 1.12 fix is now in integration via #100, and the same tree passed `runtests.jl` 3593/0 on 1.12 locally.
- **PR #95** integration→main: **DRAFT, UNSTABLE** (waiting on that CI). When integration is green → `gh pr ready 95` then `gh pr merge 95 --merge`. **Do NOT merge a red integration into `main`.**
- **PR #94** a1-nongaussian-ci→main: **CONFLICTING / superseded** → **close** (content subsumed by integration/#100), do not merge.

## Remaining work (in priority order)

1. **#95 → main** once integration CI is green (mark ready + merge). Lands the whole session on `main`.
2. **Close #94** (superseded) with a "subsumed by #100/integration" comment.
3. **gllvmTMB bridge**: push `engine-julia` (`908993d`+`f046d0f`) and open a gllvmTMB PR — **gated on maintainer** (no-push rule for gllvmTMB).
4. **Issue sweep, both repos** (plan drafted; comment-with-evidence, close on sign-off). Direct hits:
   - gllvmTMB **#488** (FIXED `f046d0f` — close the loop), **#361** (coevolution kernel — non-Gaussian landed), **#486** (`--as-cran`: 0E/1W-env/3N), **#483** (bridge NAMESPACE/man regenerated), **#340** (capability board), **#332/#335–338** (missing-data engine side).
   - GLLVM.jl **#27** (missing-data FIML/EM), **#65** (analytic gradient + non-Gaussian), **#10** (R-bridge fit+CIs+X), **#98** (per-column family).
   - Open bugs NOT touched (leave): GLLVM.jl **#91** (Poisson divergence at high rates, K≥2), **#92** (`phylo_signal_wald_ci` σ_phy exp-scale bug).
5. **gllvmTMB → CRAN**: `NEWS.md` NOTE (reorganise vs accept), **sanity-check the Felsenstein DOI correction**, then submit. For GLLVM.jl: version bump `0.1.0→next` + tag + Julia General registry PR.

## How to verify (absolute paths, copy-paste)

```bash
# GLLVM.jl full suite on CI's Julia (capped)
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl-fullcap"
OPENBLAS_NUM_THREADS=2 JULIA_NUM_THREADS=4 ~/.juliaup/bin/julia +1.12 --project=. test/runtests.jl

# bridge CIs (Julia side)
~/.juliaup/bin/julia +1.12 --project=. -e 'using GLLVM,Test,Distributions,Random,LinearAlgebra,Statistics,ForwardDiff; include("test/test_bridge_ci.jl")'

# gllvmTMB R bridge end-to-end (live R↔Julia round-trip; JuliaCall is installed)
cd "/Users/z3437171/Dropbox/Github Local/gllvmTMB"
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-fullcap" \
  Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::load_all("."); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

## Bridge contract (cross-pollination — DRM shares this architecture)

- **Julia** `GLLVM.jl-fullcap/src/bridge.jl`: `bridge_fit(; y, family, d, N, X, options)` → flat NamedTuple.
  - families: 8 one-part + mixed (vector of families).
  - `X`: gaussian + poisson/binomial/nbinom2/beta/gamma (via `fit_gllvm_cov`); ordinal/nb1/mixed have no covariate kernel (loud reject).
  - CIs: `options["ci_method"]` ∈ none/wald/profile/bootstrap → `ci_lower`/`ci_upper`/`ci_param_names`/`ci_level`.
- **R** `gllvmTMB/R/julia-bridge.R`: `gllvm_julia_fit(..., ci_method=)` + `confint.gllvmTMB_julia()`.
- **The #488 pattern you flagged** (R gate drifting behind the engine): we fixed ours — `.GLLVM_JULIA_X_FAMILIES` mirrors the engine's `_BRIDGE_X_FAMILIES`. Same audit method works for any future engine capability: grep the gate fns, diff vs what `bridge_fit` exposes, relax in lockstep.

## Etiquette / gotchas

- **No push without maintainer instruction** (both repos). #100 was merged on the maintainer's explicit "merge things"; gllvmTMB pushes still gated.
- The ~10 orphaned R workers = the maintainer's `dev/m3-pilot-local-loop.R` (PSOCK) — **not ours, leave them**.
- Watch out for the **HSquared.jl** sim (`sim/phase4b_structured_covariance_recovery.jl`) — it has periodically grabbed ~12 cores; not GLLVM.jl/DRM.
- Live status board: **http://localhost:8770** (static, from `GLLVM.jl/.claude/preview/index.html`, refreshes every 10s).

— GLLVM.jl team (Ada + crew)
