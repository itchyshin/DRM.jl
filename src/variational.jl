# variational.jl — opt-in Gaussian-variational (VA/ELBO) marginal as an
# alternative to the Laplace (LA) marginal for latent-integral models. See #136.
# Numerical ELBO kernels are intentionally NOT implemented here yet; this file
# establishes the method-selection surface the fitters will dispatch on.

"""
    MarginalMethod

How a model's random-effect integral is approximated. Subtypes: [`Laplace`](@ref)
(mode + curvature; the default, what drmTMB/TMB use) and [`Variational`](@ref)
(maximize an ELBO over a Gaussian q; opt-in, steadier on dispersion/shape — #136).
"""
abstract type MarginalMethod end

"""    Laplace <: MarginalMethod

Laplace marginal: Gaussian approximation at the posterior mode. The default."""
struct Laplace <: MarginalMethod end

"""    Variational <: MarginalMethod

Gaussian-variational (VA/ELBO) marginal — opt-in alternative to [`Laplace`](@ref)
for bias-sensitive random-effect models (#136). Not yet implemented."""
struct Variational <: MarginalMethod end

# Resolve a user-facing `method` symbol (:LA/:VA, case-insensitive) to a type.
_marginal_method(m::MarginalMethod) = m
function _marginal_method(s::Symbol)
    t = Symbol(uppercase(String(s)))
    t === :LA && return Laplace()
    t === :VA && return Variational()
    throw(ArgumentError("unknown marginal method `:$s`; use :LA (Laplace, default) or :VA (variational, #136)"))
end

# Stub entry point. The VA marginal is not implemented yet; calling it errors
# clearly rather than silently falling back, so opt-in callers know the state.
function _fit_va(args...; kwargs...)
    error("The variational (VA/ELBO) marginal is not yet implemented — see " *
          "https://github.com/itchyshin/DRM.jl/issues/136. Use method = :LA (Laplace, the default).")
end
