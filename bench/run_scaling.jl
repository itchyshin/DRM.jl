# run_scaling.jl — THE TIME TRIAL. Wall-clock of the winning engine (Julia-2,
# TMB-like exact-gradient LBFGS) as p grows, to expose O(p) scaling. drmTMB
# anchors (measured): p=100 → 2.48s, p=354 → 13.9s (already superlinear; its
# dense marginal Hessian + non-PD issues). Synthetic balanced-tree q4 PLSM data.
using LinearAlgebra, SparseArrays, Random, Statistics, Printf
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))

const βt = (mu1=[1.0,0.5], mu2=[-0.3,0.4], s1=[-0.4], s2=[-0.5], rho=[0.3])
const Λt = Matrix(Symmetric([0.25 0.10 0.05 0.0; 0.10 0.25 0.0 0.04; 0.05 0.0 0.09 0.02; 0.0 0.04 0.02 0.09]))
# Tight σ-axis init prior (axes 3,4 ≈ true 0.09) anchors the scale latents so the
# inner Laplace mode is WELL-POSED at scale (loose 0.3 → σ-field collapse / no mode;
# the workflow proved this is a model degeneracy, not a solver bug).
const Λ0 = Matrix(Symmetric([0.3 0.02 0.01 0.01; 0.02 0.3 0.01 0.01; 0.01 0.01 0.08 0.005; 0.01 0.01 0.005 0.08]))

function gen(p; seed=1, nrep=4)
    Random.seed!(seed)
    phy = random_balanced_tree(p; branch_length=0.2)
    # O(p) phylo-RE sampler (VERIFIED _verify_sampler.jl p=8: Cov(û)≈inv(P) and
    # leaf-Cov≈kron(Σ_phy,Λt), both max-rel-err<0.03). Draw the FULL augmented
    # state u ~ N(0, P^-1), P = kron(Q_cond, inv(Λt)) (sparse, PD, O(p) nnz), via
    # sparse CHOLMOD Cholesky + triangular solve — NO dense p×p Σ_phy (the O(p³)
    # cap at ~p=3000). CHOLMOD idiom: A^-1 = Pperm' L^-T L^-1 Pperm, so
    # u = Pperm' (L^-T z) = F.UP \ z for z~N(0,I) (permutation handled internally).
    keep = setdiff(1:phy.n_total, [phy.root_index])
    Q_cond = phy.Q_topology[keep, keep]
    P = prior_precision(Q_cond, inv(Λt))                             # kron(Q_cond, inv(Λt)), node-major
    F = cholesky(Symmetric(P))
    u_aug = F.UP \ randn(size(P, 1))                                 # u ~ N(0, P^-1), O(p)
    pos = Dict(node => i for (i, node) in enumerate(keep))           # kept-node id -> position (O(p))
    leaf_pos = [pos[phy.leaf_indices[t]] for t in 1:p]               # leaf k -> kept-node idx
    U = zeros(4, p)                                                  # 4×p per-SPECIES REs (leaves)
    @inbounds for k in 1:p, a in 1:4; U[a, k] = u_aug[4*(leaf_pos[k]-1) + a]; end
    species = repeat(1:p, inner=nrep)                                # data row → species (nrep reps/species)
    n = length(species)                                              # n_obs = p*nrep
    x1=randn(n); X1=hcat(ones(n),x1); X2=hcat(ones(n),x1)
    Xs1=reshape(ones(n),n,1); Xs2=reshape(ones(n),n,1); Xr=reshape(ones(n),n,1)
    y1=zeros(n); y2=zeros(n)
    for i in 1:n
        k=species[i]                                                 # this row's species
        m1=dot(X1[i,:],βt.mu1)+U[1,k]; m2=dot(X2[i,:],βt.mu2)+U[2,k]
        s1=exp(dot(Xs1[i,:],βt.s1)+U[3,k]); s2=exp(dot(Xs2[i,:],βt.s2)+U[4,k])
        ρ=RHO_GUARD*tanh(dot(Xr[i,:],βt.rho))
        e=cholesky([s1^2 ρ*s1*s2; ρ*s1*s2 s2^2]).L*randn(2); y1[i]=m1+e[1]; y2[i]=m2+e[2]
    end
    prob,Q = make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr; species=species)
    β0 = (mu1=X1\y1, mu2=X2\y2, s1=[log(std(y1.-X1*(X1\y1)))], s2=[log(std(y2.-X2*(X2\y2)))], rho=[0.0])
    return prob, Q, β0
end

fitp(prob,Q,β0) = fit_q4_sparse_tmb(prob,Q; β0=β0, Λ0=Λ0, g_tol=1e-3, iterations=400, n_newton=40)

function run_trial()
    let (pr,Q,b)=gen(50); fitp(pr,Q,b); end                          # compile warmup
    println("=== TIME TRIAL: Julia-2 (TMB-like) scaling, q4 PLSM (O(p) precision sampler) ===")
    @printf "%6s %10s %8s %12s %12s %10s\n" "p" "wall(s)" "iters" "logLik" "per-obs" "ms/node"
    results = Tuple{Int,Float64,Int}[]
    ps = [100, 500, 1000, 2000, 5000]                                # headline curve
    for p in ps
        try
            prob,Q,β0 = gen(p); nobs = length(prob.y1)
            t = @elapsed r = fitp(prob,Q,β0)
            @printf "%6d %10.3f %8d %12.2f %12.3f %10.3f\n" p t r.iterations r.loglik (r.loglik/nobs) (1000*t/(2p-1))
            push!(results,(p,t,r.iterations))
            # only attempt p=10000 if a single p=5000 fit was < 300 s (task gate)
            if p == 5000 && t < 300.0
                p2 = 10000
                prob2,Q2,β2 = gen(p2); nobs2 = length(prob2.y1)
                t2 = @elapsed r2 = fitp(prob2,Q2,β2)
                @printf "%6d %10.3f %8d %12.2f %12.3f %10.3f\n" p2 t2 r2.iterations r2.loglik (r2.loglik/nobs2) (1000*t2/(2p2-1))
                push!(results,(p2,t2,r2.iterations))
            end
        catch e
            @printf "%6d   FAILED: %s\n" p sprint(showerror,e)[1:min(80,end)]
        end
    end
    if length(results) >= 2
        p1,t1,_ = results[1]; pe,te,_ = results[end]
        exponent = log(te/t1)/log(pe/p1)
        println("\nempirical scaling exponent (wall ~ p^k): k = ", round(exponent;digits=2), "  (1.0 = perfect O(p))")
        @printf "max p reached = %d (wall %.1fs)\n" pe te
        @printf "drmTMB anchors: p=100→2.48s, p=354→13.9s (k≈%.2f, superlinear)\n" (log(13.9/2.48)/log(354/100))
        @printf "Julia-2 at p=%d: %.2fs.  If drmTMB held its k, it'd be ~%.0fs there.\n" pe te (2.48*(pe/100)^(log(13.9/2.48)/log(354/100)))
    end
    println("=== done ===")
    return results
end
run_trial()
