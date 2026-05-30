# em_squarem_fit.jl — SQUAREM-accelerated sparse Laplace-EM. Turns the EM's
# slow LINEAR convergence into near-superlinear (Varadhan & Roland 2008),
# typically 3-8x fewer iterations → the lever that makes the SINGLE fit win.
#
# State θ = [β(7); log-Cholesky(Λ)(10)] (17). log-Cholesky keeps Λ PD under
# SQUAREM extrapolation (which overshoots), retiring the PD-floor hack.
#
# Run q4_p100:
#   cd .../drm_q4 && julia --project=.. em_squarem_fit.jl

using LinearAlgebra, SparseArrays, ForwardDiff, Random, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "sparse_em_fit.jl"))

# --- pack/unpack: β(7) + log-Cholesky Λ(10) <-> θ(17) -----------------------
function pack(β, Λ)
    C = cholesky(Symmetric(Λ)).L
    lc = Float64[]
    for j in 1:4, i in j:4
        push!(lc, i == j ? log(C[i, j]) : C[i, j])    # log diagonal, raw off-diag
    end
    return vcat(β.mu1, β.mu2, β.s1, β.s2, β.rho, lc)
end
function unpack17(θ)
    β = (mu1=θ[1:2], mu2=θ[3:4], s1=θ[5:5], s2=θ[6:6], rho=θ[7:7])
    lc = θ[8:17]; C = zeros(4, 4); k = 0
    for j in 1:4, i in j:4
        k += 1; C[i, j] = i == j ? exp(lc[k]) : lc[k]
    end
    return β, Matrix(C * C')
end

# One MONOTONE (guarded) EM step as a fixed-point map θ -> θ'. Each block
# (β, then Λ) is accepted only if it does not decrease the true marginal —
# so F is a genuine ascent map and SQUAREM extrapolation is well-founded.
function make_em_map(prob, Q_cond, u_ref)
    function ev(β, Λ, u0)
        P = prior_precision(Q_cond, inv(Λ))
        u, ch, _ = estep_mode(prob, P, β; u0=u0)
        return laplace_ll(prob, P, β, u, ch), u, ch
    end
    function F(θ)
        β, Λ = unpack17(θ)
        ll, u, ch = ev(β, Λ, u_ref[])
        # β block (guarded)
        βn = mstep_beta(prob, u, β)
        lln, un, chn = ev(βn, Λ, u)
        if lln >= ll; β, ll, u, ch = βn, lln, un, chn; end
        # Λ block (guarded)
        Λn = mstep_Lambda(prob, Q_cond, u, ch)
        lll, ul, chl = ev(β, Λn, u)
        if lll >= ll; Λ, ll, u, ch = Λn, lll, ul, chl; end
        u_ref[] = u
        return pack(β, Λ)
    end
    return F
end
function marginal_at(prob, Q_cond, θ, u_ref)
    β, Λ = unpack17(θ)
    P = prior_precision(Q_cond, inv(Λ))
    u, ch, _ = estep_mode(prob, P, β; u0=u_ref[])
    return laplace_ll(prob, P, β, u, ch)
end

# SQUAREM (SqS3) with marginal-monotone stabilisation.
function squarem(prob, Q_cond, θ0; max_it=100, tol=1e-6, verbose=true)
    u_ref = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    F = make_em_map(prob, Q_cond, u_ref)
    obj(θ) = marginal_at(prob, Q_cond, θ, u_ref)
    θ = copy(θ0); ll = obj(θ); ll_hist = [ll]
    verbose && @info "SQUAREM init" loglik=round(ll;digits=4)
    iters = 0
    for it in 1:max_it
        iters = it
        θ1 = F(θ); θ2 = F(θ1)
        r = θ1 .- θ;  v = (θ2 .- θ1) .- r
        nv = norm(v)
        θprop = nv < 1e-12 ? θ2 : begin
            α = -norm(r) / nv
            α = min(α, -1.0)                            # SqS3: step length ≤ -1
            cand = θ .- 2α .* r .+ α^2 .* v
            # stabilise: one more EM step from the extrapolated point
            F(cand)
        end
        llp = obj(θprop)
        if llp >= ll                                   # accept accelerated step
            θ, ll = θprop, llp
        else                                           # fall back to plain EM (θ2)
            ll2 = obj(θ2)
            if ll2 >= ll; θ, ll = θ2, ll2; else break; end
        end
        push!(ll_hist, ll)
        verbose && (it<=5 || it%10==0) && @info "SQUAREM it $it" loglik=round(ll;digits=4) Δ=round(ll-ll_hist[end-1];digits=6)
        ll - ll_hist[end-1] < tol && it > 2 && (verbose && @info "converged" it loglik=round(ll;digits=4); break)
    end
    β, Λ = unpack17(θ)
    return (β=β, Λ=Λ, loglik=ll, iters=iters, ll_hist=ll_hist)
end

if abspath(PROGRAM_FILE) == @__FILE__
    FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
    df = CSV.read(joinpath(FIX, "q4_p100.csv"), DataFrame); p = nrow(df); n = p
    phy = augmented_phy(read(joinpath(FIX, "q4_p100_tree.nwk"), String))
    name2row = Dict(String(s)=>i for (i,s) in enumerate(df.species))
    perm = [name2row[phy.leaf_names[k]] for k in 1:p]
    y1=Vector{Float64}(df.y1)[perm]; y2=Vector{Float64}(df.y2)[perm]; x1=Vector{Float64}(df.x1)[perm]
    X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
    prob,Q_cond = make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
    β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
    θ0 = pack(β0, Matrix(0.3*I(4)))
    squarem(prob,Q_cond,θ0; max_it=3, verbose=false)   # warmup
    t1=@elapsed r=squarem(prob,Q_cond,θ0; max_it=200, tol=1e-6)
    t2=@elapsed squarem(prob,Q_cond,θ0; max_it=200, tol=1e-6, verbose=false)
    tmed=(t1+t2)/2
    println("\n=== SQUAREM sparse EM, q4_p100 ===")
    @printf "logLik=%.4f  iters=%d  wall=%.3fs (median of 2)\n" r.loglik r.iters tmed
    @printf "vs plain EM (300 iters, 2.47s, logLik -262.8) and drmTMB (2.585s, -513.99)\n"
    @printf "SPEEDUP vs drmTMB = %.2fx\n" (2.585/tmed)
    println("Λ diag=", round.(diag(r.Λ);digits=3))
    println("=== done ===")
end
