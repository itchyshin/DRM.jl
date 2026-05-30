# grad_check_diag.jl — test the "diagonal-Λ degeneracy" hypothesis for the lc3/lc7
# gradient bug. Same p=100 data, two Λ0: (A) diagonal 0.3·I (where lc3,lc7 blew
# up), (B) non-diagonal (like check_sparse_tmb, which PASSED). Reports all lc.
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

function check(label, Λ0)
    θ=pack_theta(β0,Matrix(Λ0))
    nll,ga,_,_=marginal_and_exact_grad(prob,Q_cond,θ;n_newton=80)
    mnll(t)=marginal_nll(prob,Q_cond,Vector{Float64}(t);n_newton=120)[1]
    h=1e-5; gfd=similar(θ)
    for k in 8:17  # only lc components
        tp=copy(θ);tp[k]+=h; tm=copy(θ);tm[k]-=h; gfd[k]=(mnll(tp)-mnll(tm))/(2h)
    end
    println("\n=== $label  (Λ diag=$(round.(diag(Λ0);digits=3)), maxoff=$(round(maximum(abs.(Λ0-Diagonal(Λ0)));digits=3))) ===")
    lcl=["lc1=C11","lc2=C21","lc3=C31","lc4=C41","lc5=C22","lc6=C32","lc7=C42","lc8=C33","lc9=C43","lc10=C44"]
    worst=0.0
    for k in 8:17
        re=abs(ga[k]-gfd[k])/(abs(gfd[k])+1e-8)
        flag = re>1e-2 ? "  <== BAD" : ""
        @printf "  %-9s analytic=% 12.4f  fd=% 10.4f  relerr=%.2e%s\n" lcl[k-7] ga[k] gfd[k] re flag
        worst=max(worst,re)
    end
    @printf "  worst lc relerr = %.2e -> %s\n" worst (worst<1e-2 ? "OK" : "FAIL")
end

check("A: DIAGONAL Λ=0.3I", Matrix(0.3*I(4)))
Λnd=[0.30 0.06 0.02 0.0; 0.06 0.28 0.0 0.03; 0.02 0.0 0.14 0.01; 0.0 0.03 0.01 0.16]; Λnd=Matrix(Symmetric((Λnd+Λnd')/2))
check("B: NON-DIAGONAL Λ", Λnd)
# C: diagonal but with TINY off-diagonals on the bad axes (3,1),(4,2) only
Λc=Matrix(0.3*I(4)); Λc[3,1]=Λc[1,3]=0.02; Λc[4,2]=Λc[2,4]=0.02
check("C: 0.3I + tiny (3,1),(4,2)", Λc)
println("\n=== done ===")
