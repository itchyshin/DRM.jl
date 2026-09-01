using DRM, Test, LinearAlgebra, SparseArrays, SpecialFunctions, SHA

# Frozen finite validation: two families x three observation counts x two step
# signs x two row orders x two objective constants = 48 oracle comparisons.
# No fitting. Tolerances are fixed before execution and are not calibrated here.
function reference_joint(kind, y, eta0, psi0, groups, P, Ze, Zp, a, bits, shift)
    setprecision(BigFloat, bits) do
        total = BigFloat(shift)
        for i in eachindex(y)
            u = 2groups[i] - 1
            eta = BigFloat(eta0[i]) + BigFloat(Ze[i, 1])*BigFloat(a[u]) +
                  BigFloat(Ze[i, 2])*BigFloat(a[u+1])
            psi = BigFloat(psi0[i]) + BigFloat(Zp[i, 1])*BigFloat(a[u]) +
                  BigFloat(Zp[i, 2])*BigFloat(a[u+1])
            mu = exp(eta)
            yi = BigFloat(y[i])
            if kind == Val(:gamma)
                shape = exp(psi)
                rate = shape / mu
                total += loggamma(shape) - shape*log(rate) -
                         (shape-1)*log(yi) + rate*yi
            else
                size = exp(-2psi)
                prob = size / (size + mu)
                total -= loggamma(yi+size) - loggamma(size) - loggamma(yi+1) +
                         size*log(prob) + yi*log1p(-prob)
            end
        end
        for j in axes(P, 2), i in axes(P, 1)
            total += BigFloat(a[i])*BigFloat(P[i,j])*BigFloat(a[j])/2
        end
        total
    end
end

# Independent full NLL formulas above are copied unchanged from the frozen
# varied oracle. The helper script below supplies only immutable fixture states.
include("/private/tmp/locscale_tracked_prior_six_state.jl")
const DAMAGE_SAVED = get(ENV, "DRM_ESTIMATED_CHANGE_NEGATIVE_CONTROL", "0") == "1"
println("SAVED_ORACLE_NEGATIVE_CONTROL ", DAMAGE_SAVED)
@testset "immutable six-state independent NLL oracles" begin
 for name in sort!(collect(keys(states)))
  original = states[name]
  for dense in (false,true), reversed_rows in (false,true), reversed_groups in (false,true), opposite in (false,true)
   s = original
   order = reversed_rows ? reverse(eachindex(s.y)) : eachindex(s.y)
   idx = reversed_groups ? reduce(vcat, ([2g-1,2g] for g in reverse(1:s.G))) : collect(eachindex(s.a))
   P = dense ? Matrix(s.P[idx,idx]) : sparse(s.P[idx,idx])
   a = s.a[idx]; trial = s.trial[idx]
   opposite && (trial = 2 .* a .- trial)
   groups = reversed_groups ? s.G .+ 1 .- s.gidx[order] : s.gidx[order]
   yy,eta,psi = s.y[order],s.eta[order],s.psi[order]
   Ze,Zp = s.Zeta[order,:],s.Zpsi[order,:]
   result = DRM._ls_inner_estimated_change(s.kind,yy,eta,psi,groups,s.G,P,Ze,Zp,a,trial)
   @test result !== nothing
   result === nothing && continue
   DAMAGE_SAVED && (result=merge(result,(estimate=1.01result.estimate,)))
   refs = [reference_joint(s.kind,yy,eta,psi,groups,P,Ze,Zp,trial,bits,0)-
           reference_joint(s.kind,yy,eta,psi,groups,P,Ze,Zp,a,bits,0) for bits in (128,256)]
   error = abs(BigFloat(result.estimate)-refs[2]); relative = error/abs(refs[2])
   @test abs(refs[1]-refs[2])/abs(refs[2]) <= big"1e-15"
   @test relative <= big"1e-4"
   @test error <= BigFloat(result.error)
   @test opposite ? refs[2]>0 && result.margin>0 : refs[2]<0 && result.margin<0
   println("ORACLE_CASE ",name," dense=",dense," rows=",reversed_rows," groups=",reversed_groups,
           " opposite=",opposite," REF=",refs[2]," RELERR=",relative," E=",result.error)
  end
 end
end
println("SAVED_ORACLES_OK")
