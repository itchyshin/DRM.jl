# profile_sparse_grad.jl — locate the O(p^2) leak in marginal_and_exact_grad.
# Times each SECTION of the exact sparse gradient at p=100 (real q4_p100), so we
# fix the real bottleneck (the prior note guessed "sparse getindex + kron-Dual").
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
N=prob.n_total
@printf "p=%d  N(aug nodes)=%d  nu=4N=%d  nnz(Q_cond)=%d\n" p N (4N) nnz(Q_cond)

med(f,k=3)=(f(); minimum(@elapsed(f()) for _ in 1:k))

# warm mode + the shared objects
k1,k2,ks1,ks2,kr=beta_widths(prob); o1=0;o2=k1;o3=o2+k2;o4=o3+ks1;o5=o4+ks2;o6=o5+kr
β,lc=unpack_theta(prob,θ); Λ=lc_to_Λ(lc); Λi=inv(Λ)
P=prior_precision(Q_cond,Λi)
u_hat,chH,H=estep_mode(prob,P,β;n_newton=40); u_hat=Vector{Float64}(u_hat)
η1,η2,ηs1,ηs2,ηr=leaf_etas(prob,β)

println("\n--- section timings (s) at p=$p ---")
@printf "estep_mode (mode, cold):          %.4f\n" med(()->estep_mode(prob,P,β;n_newton=40))
t_tak=med(()->takahashi_selinv(chH)); @printf "takahashi_selinv:                 %.4f\n" t_tak
Vsel=takahashi_selinv(chH)

# (2a) jn_of_θ gradient (kron-with-Dual built inside)
jn_of_θ=function(t::AbstractVector)
    βt,lct=unpack_theta(prob,t);Λt=lc_to_Λ(lct);Pt=prior_precision(Q_cond,inv(Λt))
    return joint_nll_T(prob,Pt,u_hat,βt)
end
@printf "(2a) FD grad jn_of_θ:             %.4f\n" med(()->ForwardDiff.gradient(jn_of_θ,θ))

# (2c-β) per-leaf logdetH β trace
function beta_leaf_block()
    g=zeros(length(θ))
    @inbounds for i in 1:prob.p
        t=prob.leaf_node[i];bt=4(t-1); Vblk=@view Vsel[bt+1:bt+4,bt+1:bt+4]
        Jη=ForwardDiff.jacobian(e->vec(leaf_hess([u_hat[bt+1],u_hat[bt+2],u_hat[bt+3],u_hat[bt+4]],
            prob.y1[i],prob.y2[i],e[1],e[2],e[3],e[4],e[5])),[η1[i],η2[i],ηs1[i],ηs2[i],ηr[i]])
        for m in 1:5; acc=0.0; col=@view Jη[:,m]; for b in 1:4,a in 1:4; acc+=Vblk[a,b]*col[(b-1)*4+a]; end; end
    end
    g
end
@printf "(2c-β) leaf logdetH β trace:      %.4f\n" med(beta_leaf_block)

# (2c-lc) Gst assembly (sparse getindex over nnz(Q)) — PRIME SUSPECT
function gst_block()
    Gst=zeros(4,4); rows=rowvals(Q_cond);vals=nonzeros(Q_cond)
    @inbounds for tcol in 1:N
        for idx in nzrange(Q_cond,tcol)
            s=rows[idx];q=vals[idx];bs=4(s-1);bt=4(tcol-1)
            for a in 1:4,b in 1:4; Gst[b,a]+=q*Vsel[bt+a,bs+b]; end
        end
    end
    Gst
end
@printf "(2c-lc) Gst sparse-getindex loop: %.4f   <- SUSPECT\n" med(gst_block)

# (3) v assembly (leaf_hess_du per leaf)
function v_block()
    v=zeros(4N)
    @inbounds for i in 1:prob.p
        t=prob.leaf_node[i];bt=4(t-1);Vblk=@view Vsel[bt+1:bt+4,bt+1:bt+4]
        T=leaf_hess_du([u_hat[bt+1],u_hat[bt+2],u_hat[bt+3],u_hat[bt+4]],prob.y1[i],prob.y2[i],η1[i],η2[i],ηs1[i],ηs2[i],ηr[i])
        for c in 1:4; acc=0.0; for b in 1:4,a in 1:4; acc+=Vblk[a,b]*T[a,b,c]; end; v[bt+c]=0.5*acc; end
    end
    v
end
@printf "(3) v assembly (leaf_hess_du):    %.4f\n" med(v_block)
v=v_block()
@printf "(4) w = chH \\ v (sparse solve):   %.4f\n" med(()->chH\v)
w=chH\v

# (5) scalar_of_θ gradient (kron-with-Dual again)
scalar_of_θ=function(t::AbstractVector)
    βt,lct=unpack_theta(prob,t);Λt=lc_to_Λ(lct);Pt=prior_precision(Q_cond,inv(Λt))
    gu=joint_grad_T(prob,Pt,u_hat,βt); return dot(gu,w)
end
@printf "(5) FD grad scalar_of_θ:          %.4f\n" med(()->ForwardDiff.gradient(scalar_of_θ,θ))

println("\n--- full gradient (for reference) ---")
@printf "marginal_and_exact_grad total:    %.4f\n" med(()->marginal_and_exact_grad(prob,Q_cond,θ;n_newton=40))
println("=== profile done ===")
