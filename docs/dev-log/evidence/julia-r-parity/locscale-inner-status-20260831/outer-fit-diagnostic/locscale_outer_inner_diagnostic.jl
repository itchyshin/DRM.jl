using DRM
using Random, LinearAlgebra, SparseArrays, Distributions, SHA

# Read-only, process-local instrumentation.  The checked-out solver is copied
# verbatim under a diagnostic name, then the original method is shadowed only
# for this Julia process so the real fit/gradient/observed-information routes
# retain their normal warm starts and h = 1e-5 calls.
const DIAG_SOURCE = "/private/tmp/drm-parity-20260830/integration/DRM.jl/src/locscale_inner.jl"
const DIAG_RECORDS = Any[]
const DIAG_LAST_FULL = Ref{Any}(nothing)
const DIAG_CALL = Ref(0)

@eval DRM begin
    const _outer_inner_diag_records = Main.DIAG_RECORDS
    const _outer_inner_diag_last_full = Main.DIAG_LAST_FULL
    const _outer_inner_diag_call = Main.DIAG_CALL

    function _outer_inner_diag_snapshot(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ,
                                        a, grad, step, f0, trial, ft, tol)
        try
            tgrad = _ls_joint_grad(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)
            Htrial = _ls_joint_hess(kind, y, η0, ψ0, gidx, G, trial, P, Zη, Zψ)
            Hfinite = _ls_allfinite(Htrial)
            Ftrial = Hfinite ? cholesky(Symmetric(Htrial); check = false) : nothing
            anorm, gnorm = norm(a), norm(grad)
            tnorm, tgnorm = norm(trial), norm(tgrad)
            return (
                f0=f0, ft=ft, delta=ft-f0,
                ulp=max(eps(abs(f0)), eps(abs(ft))),
                displacement=norm(trial .- a),
                predicted_descent=dot(grad, step),
                base_norm=anorm, base_gnorm=gnorm, base_bound=tol*(1+anorm),
                trial_norm=tnorm, trial_gnorm=tgnorm, trial_bound=tol*(1+tnorm),
                trial_finite=all(isfinite, trial), trial_grad_finite=all(isfinite, tgrad),
                trial_H_finite=Hfinite,
                trial_pd=(Ftrial !== nothing && issuccess(Ftrial)),
                representably_changed=any(trial .!= a),
            )
        catch err
            return (snapshot_exception=string(typeof(err)), message=sprint(showerror, err))
        end
    end

    function _outer_inner_diag_failure(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ, a, tol)
        grad = try _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ) catch err; nothing end
        H = try _ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ) catch err; nothing end
        anorm = try norm(a) catch; NaN end
        gnorm = grad === nothing ? NaN : try norm(grad) catch; NaN end
        Hfinite = H === nothing ? false : try _ls_allfinite(H) catch; false end
        return (
            call=_outer_inner_diag_call[],
            final_a_finite=all(isfinite, a),
            final_grad_finite=(grad !== nothing && all(isfinite, grad)),
            final_H_finite=Hfinite,
            final_anorm=anorm, final_gnorm=gnorm,
            final_bound=tol*(1+anorm),
            full=_outer_inner_diag_last_full[],
        )
    end
end

src = read(DIAG_SOURCE, String)
start = findfirst("function _ls_inner_mode(", src)
start === nothing && error("missing _ls_inner_mode in frozen source")
solver = src[first(start):end]
solver = replace(solver, "function _ls_inner_mode(" => "function _diagnostic_inner_mode("; count=1)
solver = replace(solver,
    "a = a0 === nothing ? zeros(2G) : copy(a0)" =>
    "a = a0 === nothing ? zeros(2G) : copy(a0)\n    _outer_inner_diag_last_full[] = nothing";
    count=1)
solver = replace(solver,
    "ft = _ls_joint(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)" =>
    "ft = _ls_joint(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)\n                    if λ == 0.0 && α == 1.0\n                        _outer_inner_diag_last_full[] = _outer_inner_diag_snapshot(\n                            kind, y, η0, ψ0, gidx, G, P, Zη, Zψ, a, grad, step, f0, trial, ft, tol)\n                    end";
    count=1)
Core.eval(DRM, Meta.parse(solver))

@eval DRM begin
    function _ls_inner_mode(kind, y, η0, ψ0, gidx, G, P,
                            Zη = _ls_canonical_Zeta(length(y)),
                            Zψ = _ls_canonical_Zpsi(length(y)); a0 = nothing,
                            maxiter::Int = 200, tol::Real = 1e-9)
        _outer_inner_diag_call[] += 1
        a, ch, ok = _diagnostic_inner_mode(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ;
                                             a0=a0, maxiter=maxiter, tol=tol)
        if !ok && length(_outer_inner_diag_records) < 20
            push!(_outer_inner_diag_records,
                  _outer_inner_diag_failure(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ, a, tol))
        end
        return a, ch, ok
    end
end

function nb2_fixture()
    Random.seed!(424242)
    G = 50; m = 35; n = G*m
    species = repeat(1:G, inner=m)
    x = randn(n)
    βμ = [0.5, 0.4]; βψ = [0.3]
    Λ = [0.25 0.05; 0.05 0.16]
    L = cholesky(Symmetric(Λ)).L
    A = [L * randn(2) for _ in 1:G]
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    y = [begin
        η = βμ[1] + βμ[2]*x[i] + A[species[i]][1]
        ψ = βψ[1] + A[species[i]][2]
        r = exp(ψ); μ = exp(η)
        Float64(rand(NegativeBinomial(r, r/(r+μ))))
    end for i in 1:n]
    return Val(:nb2), y, Xμ, Xψ, species, G, sparse(1.0I, G, G)
end

function gamma_fixture()
    Random.seed!(20_260_831)
    G = 4; m = 8; n = G*m
    species = repeat(1:G, inner=m)
    x = repeat(range(-1.0, 1.0; length=m), G)
    eta = 0.70 .+ 0.55 .* x .+ (0.16 .* randn(G))[species]
    psi = 1.05 .+ (0.10 .* randn(G))[species]
    y = [begin
        shape = exp(psi[i]); mu = exp(eta[i])
        Float64(rand(Distributions.Gamma(shape, mu/shape)))
    end for i in 1:n]
    return Val(:gamma), y, hcat(ones(n), x), ones(n,1), species, G, sparse(1.0I, G, G)
end

function run_case(name, fixture)
    empty!(DIAG_RECORDS); DIAG_CALL[] = 0
    kind, y, Xμ, Xψ, gidx, G, Q = fixture()
    println("CASE ", name, " n=", length(y), " G=", G)
    fit = DRM._fit_locscale(kind, y, Xμ, Xψ, gidx, G, Q; se=false)
    println("FIT theta_finite=", all(isfinite, fit.θ), " nll=", fit.nll,
            " converged=", fit.converged, " records=", length(DIAG_RECORDS))
    # Recover the actual mode at theta_hat, then send precisely that a0 through
    # the h=1e-5 observed-information path.  This does not alter fitting.
    pμ = size(Xμ,2); pψ=size(Xψ,2)
    Λ = DRM._ls_lc_to_Λ(fit.θ[pμ+pψ+1:pμ+pψ+3])
    P = DRM.prior_precision(Q, DRM._ls_inv2x2(Λ))
    val,a,ok = DRM._ls_marginal_nll(kind, y, Xμ*fit.θ[1:pμ], Xψ*fit.θ[pμ+1:pμ+pψ],
                                     gidx, G, P; a0=nothing)
    println("MODE value=", val, " ok=", ok, " a_finite=", all(isfinite,a),
            " a_norm=", norm(a))
    empty!(DIAG_RECORDS); DIAG_CALL[] = 0
    H = DRM._ls_obs_information(kind, y, Xμ, Xψ, gidx, G, Q, fit.θ; h=1e-5, a0=a)
    println("OBSINFO finite=", all(isfinite, H), " records=", length(DIAG_RECORDS))
    for (i,r) in enumerate(DIAG_RECORDS)
        println("FAIL_RECORD ", i, " ", repr(r))
    end
end

println("DIAGNOSTIC_SOURCE_SHA ", bytes2hex(sha256(read(DIAG_SOURCE))))
println("JULIA_THREADS ", Threads.nthreads(), " BLAS_THREADS ", BLAS.get_num_threads())
run_case("NB2_RECOVERY_424242_G50_M35", nb2_fixture)
run_case("GAMMA_STATUS_20260831_G4_M8", gamma_fixture)
