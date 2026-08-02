# Rose claim-vs-evidence — Phase 1.5 #5 (2026-08-01)

**Scope:** DRM.jl [#349](https://github.com/itchyshin/DRM.jl/pull/349) ↔ drmTMB [#878](https://github.com/itchyshin/drmTMB/pull/878)  
**Personas:** Rose (gate) + Shannon (coord). No spawned subagents.

## Verdict: **PASS — merge OK (experimental bar)**

Hopper #5 bar (Gaussian uni / bivariate residual / first phylo-mean + gate rejections) is **evidenced** as an **experimental** bridge finish. Safe to merge both PRs when CI is green. Do **not** treat this as CRAN/registry promotion.

## Claims checked

| Claim | Evidence | OK? |
|---|---|---|
| Stay **experimental**; no new families | Matrix + R `claim_status = partial`; new cells `r_bridge_status = experimental`; vignette untouched / CRAN-deferred | Yes |
| No CRAN **Depends** on JuliaCall | drmTMB `DESCRIPTION` unchanged: JuliaCall remains **Suggests** only; PR bodies / matrix fence say do not Depend | Yes |
| No vignette flip to “supported” | Neither PR edits `vignettes/julia-engine.Rmd` | Yes |
| Result-shape for #5 trio | Julia `test/test_bridge.jl` gap fill; R offline `new_drmTMB_julia` + gate assertions; live JuliaCall parity still skip-guarded | Yes |
| License boundary | No drmTMB GPL source vendored into DRM.jl | Yes |
| Close DRM.jl #5 | Yes for the Hopper experimental bar; optional always-on `DRM_PARITY_TESTS=1` remains out of this bar | Yes |

## Oversell watch

- **No oversell of CRAN/JuliaCall Depends.** Explicit fence in both finish matrices; Suggests-only preserved.
- **Resolved (tip honesty, 2026-08-01):** uni cells `base_gaussian_location_scale` and `gaussian_response_mask` now use `r_bridge_status = "experimental"` to match `claim_status = partial` (drmTMB registry + regenerated `julia-capabilities.tsv`). Not a capability promotion.
- Live Route A/B/C TMB↔Julia numeric parity remains **optional / skip-guarded** — docs correctly mark it as such, not as always-on CI evidence.

## Merge advice / outcome (2026-08-01)

- **DRM.jl #349:** MERGED @ `d296703` (CI green after main rebase).
- **drmTMB #878:** MERGED @ `fb59cd3` after ASCII fix (em-dash → ASCII); bridge-only; no Codex #858 overlap.
- **S4 Registrator / AutoMerge:** out of scope — still waiting separate Shinichi OK.

*Rose: PASS. Perspectives active: Rose + Shannon. No spawned subagents.*
