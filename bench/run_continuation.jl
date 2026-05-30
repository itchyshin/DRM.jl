# run_continuation.jl — OUT-OF-BOX IDEA #1: warm-start / continuation across a
# simulation (bootstrap) grid. The real goal is THROUGHPUT (1000s of fits of the
# SAME model), not a single fit. In a bootstrap/sim study every dataset is near
# the MLE, so warm-starting each refit FROM the MLE should need far fewer
# iterations than cold-starting. This measures the per-refit multiplier (which
# then compounds with threading).
using LinearAlgebra, SparseArrays, Random, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))
const FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))

# load real q4_p100
df=CSV.read(joinpath(FIX,"q4_p100.csv"),DataFrame); p=nrow(df); n=p
phy=augmented_phy(read(joinpath(FIX,"q4_p100_tree.nwk"),String))
name2row=Dict(String(s)=>i for (i,s) in enumerate(df.species)); perm=[name2row[phy.leaf_names[k]] for k in 1:p]
y1o=Vector{Float64}(df.y1)[perm];y2o=Vector{Float64}(df.y2)[perm];x1=Vector{Float64}(df.x1)[perm]
X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
Σ_phy=sigma_phy_dense(phy;σ²_phy=1.0)

coldβ(y1,y2)=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
const COLDΛ=Matrix(Symmetric(0.3*I(4)+0.03*(ones(4,4)-I(4))))

# original fit -> the MLE we warm-start from
prob0,Q0=make_problem(phy,y1o,y2o,X1,X2,Xs1,Xs2,Xr)
r0=fit_q4_sparse_tmb(prob0,Q0;β0=coldβ(y1o,y2o),Λ0=COLDΛ,g_tol=1e-3,iterations=400,n_newton=40)
βhat=r0.β; Λhat=r0.Λ
println("original MLE: LL=$(round(r0.loglik;digits=3)), sd_phy=$(round.(sqrt.(diag(Λhat));digits=3))")

function simulate(β,Λ,seed)
    Random.seed!(seed)
    U=cholesky(Symmetric(Λ)).L*randn(4,p)*cholesky(Symmetric(Σ_phy)).U
    y1=zeros(n);y2=zeros(n)
    for i in 1:n
        m1=dot(X1[i,:],β.mu1)+U[1,i]; m2=dot(X2[i,:],β.mu2)+U[2,i]
        s1=exp(dot(Xs1[i,:],β.s1)+U[3,i]); s2=exp(dot(Xs2[i,:],β.s2)+U[4,i])
        ρ=RHO_GUARD*tanh(dot(Xr[i,:],β.rho))
        e=cholesky([s1^2 ρ*s1*s2; ρ*s1*s2 s2^2]).L*randn(2)
        y1[i]=m1+e[1]; y2[i]=m2+e[2]
    end
    y1,y2
end

function run(B)
    tc=Float64[];tw=Float64[];ic=Int[];iw=Int[];dll=Float64[]
    for b in 1:B
        y1,y2=simulate(βhat,Λhat,1000+b); prob,Q=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
        # COLD: generic init
        t1=@elapsed rc=fit_q4_sparse_tmb(prob,Q;β0=coldβ(y1,y2),Λ0=COLDΛ,g_tol=1e-3,iterations=400,n_newton=40)
        # WARM: start from the original MLE (continuation)
        t2=@elapsed rw=fit_q4_sparse_tmb(prob,Q;β0=βhat,Λ0=Λhat,g_tol=1e-3,iterations=400,n_newton=40)
        push!(tc,t1);push!(tw,t2);push!(ic,rc.iterations);push!(iw,rw.iterations);push!(dll,abs(rc.loglik-rw.loglik))
    end
    tc,tw,ic,iw,dll
end

run(1)                                       # warmup/compile
B=12; tc,tw,ic,iw,dll=run(B)
println("\n=== continuation warm-start, B=$B bootstrap refits (p=$p) ===")
@printf "COLD: %.3fs/fit (mean), %d iters (median)\n" mean(tc) round(Int,median(ic))
@printf "WARM: %.3fs/fit (mean), %d iters (median)\n" mean(tw) round(Int,median(iw))
@printf "per-refit speedup from warm-start = %.1fx\n" (mean(tc)/mean(tw))
@printf "max |LL_cold - LL_warm| = %.4f  (warm reaches same optimum: %s)\n" maximum(dll) (maximum(dll)<0.1 ? "YES" : "NO")
@printf "\nThroughput projection (B=199 bootstrap): cold %.0fs vs warm %.0fs serial; warm + 10-core threading ~%.0fs\n" (199*mean(tc)) (199*mean(tw)) (199*mean(tw)/10)
println("=== done ===")
