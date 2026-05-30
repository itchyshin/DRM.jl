# profile_step1.jl — Phase-1 root-cause profiling of the q4_p100 fit slowness.
# Times each piece so we fix the REAL bottleneck, not a guess.
using LinearAlgebra, SparseArrays, ForwardDiff, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "fit_ml_q4.jl"))   # EM infra: estep_mode, mstep_Lambda, mstep_beta, lc_to_Λ, Λ_to_lc, make_problem

FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
df = CSV.read(joinpath(FIX,"q4_p100.csv"),DataFrame); p=nrow(df); n=p
phy = augmented_phy(read(joinpath(FIX,"q4_p100_tree.nwk"),String))
name2row=Dict(String(s)=>i for (i,s) in enumerate(df.species)); perm=[name2row[phy.leaf_names[k]] for k in 1:p]
y1=Vector{Float64}(df.y1)[perm];y2=Vector{Float64}(df.y2)[perm];x1=Vector{Float64}(df.x1)[perm]
X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
prob,Q_cond = make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
β=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
Λ=Matrix(0.3*I(4)); P=prior_precision(Q_cond,inv(Λ))
N=prob.n_total
@printf "p=%d, augmented latent dim 4*(2p-1)=%d, nnz(P)=%d\n" p (4*N) nnz(P)

med(f,k=5)= (f(); minimum(@elapsed(f()) for _ in 1:k))

# 1. one E-step (sparse Newton mode) — is it O(p) fast?
t_estep = med(()->estep_mode(prob,P,β;n_newton=60))
u,ch,_ = estep_mode(prob,P,β;n_newton=60)
@printf "1. E-step (sparse Newton):        %.4f s\n" t_estep
# 1b. warm-started E-step (1-2 Newton from a good start)
t_estep_warm = med(()->estep_mode(prob,P,β;u0=u,n_newton=5))
@printf "1b. E-step warm (n_newton=5):     %.4f s\n" t_estep_warm

# 2. takahashi selected inverse
t_tak = med(()->takahashi_selinv(ch))
@printf "2. takahashi_selinv:              %.4f s\n" t_tak

# 3. closed-form Λ M-step (uses current û + takahashi — NO extra E-step)
t_lam_closed = med(()->mstep_Lambda(prob,Q_cond,u,ch))
@printf "3. mstep_Lambda (closed-form):    %.4f s   <- the FAST path\n" t_lam_closed

# 4. mstep_beta (conditional Newton)
t_beta = med(()->mstep_beta(prob,u,β))
@printf "4. mstep_beta (cond. Newton):     %.4f s\n" t_beta

# 5. ONE finite-diff Λ gradient (10 params x 2 evals, each a fresh E-step) — the SUSPECT
function fd_lambda_grad()
    v=Λ_to_lc(Λ); h=1e-5
    for k in 1:10
        vp=copy(v);vp[k]+=h; vm=copy(v);vm[k]-=h
        L_given_Λ(prob,Q_cond,β,lc_to_Λ(vp);nit=60); L_given_Λ(prob,Q_cond,β,lc_to_Λ(vm);nit=60)
    end
end
t_fd = @elapsed fd_lambda_grad()
@printf "5. finite-diff Λ gradient (20 E-steps): %.4f s   <- the SUSPECTED bottleneck\n" t_fd

@printf "\nRatio: finite-diff Λ grad / closed-form Λ = %.0fx\n" (t_fd/max(t_lam_closed,1e-9))
@printf "If a fit is ~40 EM iters: finite-diff Λ alone ≈ %.1f s vs closed-form ≈ %.2f s\n" (40*t_fd) (40*t_lam_closed)
println("=== profile done ===")
