# grad_check_p100.jl — find the wrong gradient component. Compares the analytic
# sparse exact gradient to central finite-diff of the TRUE marginal (marginal_nll,
# validated to match dense Laplace 1e-10) at p=100, θ0. Flags the bad component.
# θ = [β(7); lc(10)], indices 1..7 β, 8..17 lc.
using LinearAlgebra, SparseArrays, ForwardDiff, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))
FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
df=CSV.read(joinpath(FIX,"q4_p100.csv"),DataFrame); p=nrow(df); n=p
phy=augmented_phy(read(joinpath(FIX,"q4_p100_tree.nwk"),String))
name2row=Dict(String(s)=>i for (i,s) in enumerate(df.species)); perm=[name2row[phy.leaf_names[k]] for k in 1:p]
y1=Vector{Float64}(df.y1)[perm];y2=Vector{Float64}(df.y2)[perm];x1=Vector{Float64}(df.x1)[perm]
X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
prob,Q_cond=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
θ=pack_theta(β0,Matrix(0.3*I(4)))

# analytic gradient
nll,ga,_,_=marginal_and_exact_grad(prob,Q_cond,θ;n_newton=60)

# central finite-diff of the TRUE marginal (cold mode each eval for a clean profile)
mnll(t)= marginal_nll(prob,Q_cond,Vector{Float64}(t);n_newton=80)[1]
h=1e-5; gfd=similar(θ)
for k in eachindex(θ)
    tp=copy(θ);tp[k]+=h; tm=copy(θ);tm[k]-=h
    gfd[k]=(mnll(tp)-mnll(tm))/(2h)
end

function report(θ,ga,gfd,nll)
    println("=== gradient check at p=100, θ0 (nll=$(round(nll;digits=4))) ===")
    @printf "%-4s %-10s %14s %14s %12s\n" "idx" "param" "analytic" "finite-diff" "rel.err"
    labels=vcat(["mu1_0","mu1_x","mu2_0","mu2_x","s1_0","s2_0","rho_0"],["lc$k" for k in 1:10])
    worst=0.0; worstk=0
    for k in eachindex(θ)
        re=abs(ga[k]-gfd[k])/(abs(gfd[k])+1e-8)
        flag = re>1e-3 ? (re>1e-1 ? "  <== BAD" : "  <- off") : ""
        @printf "%-4d %-10s %14.5f %14.5f %12.2e%s\n" k labels[k] ga[k] gfd[k] re flag
        if re>worst && abs(gfd[k])>1e-4; worst=re; worstk=k; end
    end
    @printf "\nworst rel.err = %.3e at idx %d (%s)\n" worst worstk labels[worstk]
    @printf "||g_analytic||=%.3e   ||g_fd||=%.3e\n" norm(ga) norm(gfd)
    println("=== done ===")
end
report(θ,ga,gfd,nll)
