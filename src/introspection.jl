# introspection.jl — A4d-2. Two post-fit inventories, the Julia twins of
# drmTMB's `profile_targets()` (R/profile.R) and `structured_effects()`
# (R/methods.R).
#
# Neither changes a fit. Both exist so downstream code does not have to re-parse
# formula text or guess what `confint(..., method = :profile)` will accept — and
# both are careful to report what is ACTUALLY available on THIS fit rather than
# what the package can do in general. A readiness column that always says "ready"
# would be worse than no column at all.

"""
    profile_targets(fit::DrmFit; ready_only = false) -> Vector{NamedTuple}

Every parameter [`profile_result`](@ref) / `confint(..., method = :profile)` can
be asked for on **this** fit, with an honest readiness flag — drmTMB's
`profile_targets()`.

Runs no optimisation: it walks the fitted object. One row per coefficient with

- `parm` — the coefficient name;
- `param` — its block (`:mu`, `:sigma`, `:resd`, …);
- `index` — its position in `fit.theta`;
- `estimate` — the fitted value **on the estimation scale**;
- `scale` — `:log` for a variance-component / scale coefficient, `:identity` otherwise;
- `profile_ready` — whether a profile interval can actually be computed here;
- `profile_note` — why, when it cannot.

Pass `ready_only = true` to drop the unavailable rows.

# Example
```julia
tg = profile_targets(fit)
filter(r -> !r.profile_ready, tg)        # what will refuse, and why
```
"""
function profile_targets(fit::DrmFit; ready_only::Bool = false)
    jobs = _profile_jobs(fit, nothing)
    stored = _glsp_stored_profile_rows(fit)
    stored_params = Set(r.param for r in stored)

    # Mirror `profile_result`'s dispatch exactly — if the readiness rule and the
    # dispatch rule ever disagree, this inventory becomes a liar.
    route, note = if fit.nll isa LocScaleObjective
        (:locscale, "")
    elseif fit.nll isa LocOnlyObjective && !isempty(jobs) && all(j -> j.param === :resd, jobs)
        (:loconly, "")
    elseif !isempty(stored)
        (:stored, "profile CI precomputed at fit time (σ-phylo route has no re-optimisable objective)")
    elseif fit.nll === nothing
        (:none, "the fitted objective was not stored on this fit; for the σ-phylo " *
                "location-scale route refit with `profile_ci = true`")
    else
        (:generic, "")
    end

    rows = NamedTuple[]
    for j in jobs
        ready, why = if route === :none
            (false, note)
        elseif route === :stored
            j.param in stored_params ? (true, note) :
                (false, "no precomputed profile row for block `$(j.param)` on this fit")
        else
            (true, note)
        end
        ready_only && !ready && continue
        push!(rows, (parm = j.coef, param = j.param, index = j.k,
                     estimate = fit.theta[j.k],
                     scale = _profile_target_scale(j.param),
                     profile_ready = ready, profile_note = why))
    end
    return rows
end

# Which coefficients live on a log scale in `theta`. The variance-component and
# residual-scale blocks are stored as logs; mean coefficients are not.
_profile_target_scale(param::Symbol) =
    param in (:sigma, :resd, :resd_mu, :resd_sigma, :recov, :sd) ? :log : :identity

"""
    structured_effects(fit::DrmFit) -> Vector{NamedTuple}

One row per **structured marker** in the fitted formula — drmTMB's
`structured_effects()`. Fields `dpar`, `kind`, `grouping`.

`kind` is the marker (`:phylo`, `:relmat`, `:animal`, `:spatial`), `grouping` the
factor it wraps, and `dpar` the distributional parameter whose formula carried
it. Exists so downstream code never has to grep or re-parse formula text.

Returns an empty vector for a model with no structured markers, and for a fit
whose formula was not retained.

# Example
```julia
structured_effects(fit)
# 2-element Vector{NamedTuple}:
#  (dpar = :mu,    kind = :phylo, grouping = :species)
#  (dpar = :sigma, kind = :phylo, grouping = :species)
```
"""
function structured_effects(fit::DrmFit)
    rows = NamedTuple[]
    f = fit.formula
    f === nothing && return rows
    forms = _structured_effects_forms(f)
    forms === nothing && return rows
    for (dpar, rhs) in forms
        for (kind, grp) in _collect_structured(rhs)
            push!(rows, (dpar = dpar, kind = kind, grouping = grp))
        end
    end
    return rows
end

# `DrmFormula` stores `forms::Vector{Pair{Symbol,Any}}`. Anything else (e.g. a
# bivariate formula shape) returns `nothing` rather than guessing at a layout —
# an introspection helper that invents structure is worse than one that declines.
function _structured_effects_forms(f)
    hasproperty(f, :forms) || return nothing
    fs = getproperty(f, :forms)
    fs isa AbstractVector || return nothing
    return fs
end
