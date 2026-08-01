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
- **Mild pre-existing tension (not blocking):** uni cell `base_gaussian_location_scale` still has `r_bridge_status = "supported"` while `claim_status` stays `partial` and the claim_boundary now stresses CRAN readers use TMB / vignette deferred. Do not promote that row further in this slice; a later honesty pass can align `supported` → `experimental` if desired.
- Live Route A/B/C TMB↔Julia numeric parity remains **optional / skip-guarded** — docs correctly mark it as such, not as always-on CI evidence.

## Merge advice

- **DRM.jl #349:** merge when `test (1)` + `test (1.10)` (+ docs) green.
- **drmTMB #878:** bridge-only; no file overlap with open Codex Lane B [#858](https://github.com/itchyshin/drmTMB/pull/858). First CI run failed on **non-ASCII WARNING** (em-dash in Route C `claim_boundary` string; tests `FAIL 0`). ASCII fix pushed; **leave open until re-check green**, then merge.
- **S4 Registrator / AutoMerge:** out of scope — still waiting separate Shinichi OK.

*Rose: PASS. Perspectives active: Rose + Shannon.*
