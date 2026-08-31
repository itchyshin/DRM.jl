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

println("SOURCE_SHA ", bytes2hex(sha256(read(joinpath(dirname(pathof(DRM)), "locscale_inner.jl")))))
println("PROBE_SHA ", bytes2hex(sha256(read(@__FILE__))))
const DAMAGED_ESTIMATE = get(ENV, "DRM_ESTIMATED_CHANGE_NEGATIVE_CONTROL", "0") == "1"
println("NEGATIVE_CONTROL ", DAMAGED_ESTIMATE)
@testset "independent varied estimated-change oracles" begin
    for kind in (Val(:gamma), Val(:nb2)), n in (5, 17, 64)
        @testset "family=$kind n=$n" begin
            G = 3
            groups = [mod1(i, G) for i in 1:n]
            eta = [0.3sin(i) for i in 1:n]
            psi = [0.2cos(i) for i in 1:n]
            Ze = hcat(ones(n), [0.25sin(0.7i) for i in 1:n])
            Zp = hcat([0.3cos(0.8i) for i in 1:n], ones(n))
            Pdense = Matrix(SymTridiagonal(fill(2.0, 2G), fill(0.15, 2G-1)))
            P = n == 5 ? Pdense : sparse(Pdense)
            a = [0.15sin(i) for i in 1:2G]
            y = kind == Val(:gamma) ? [0.5 + 0.2mod(i, 9) for i in 1:n] :
                                      [Float64(mod(i, 7)) for i in 1:n]
            grad = DRM._ls_joint_grad(kind, y, eta, psi, groups, a, P, Ze, Zp)
            @test all(isfinite, grad) && norm(grad) > 0
            step = -1e-8 .* grad ./ norm(grad)
            for direction in (-1, 1), reversed in (false, true), shift in (0, 10^12)
                @testset "direction=$direction reversed=$reversed shift=$shift" begin
                    order = reversed ? (n:-1:1) : (1:n)
                    yy, ee, pp, gg = y[order], eta[order], psi[order], groups[order]
                    ze, zp = Ze[order, :], Zp[order, :]
                    trial = a .+ direction .* step
                    estimate = DRM._ls_inner_estimated_change(kind, yy, ee, pp, gg, G,
                                                              P, ze, zp, a, trial)
                    @test estimate !== nothing
                    if estimate !== nothing
                        # Explicit test-of-test: corrupt the returned estimate,
                        # never production source or the independent reference.
                        if DAMAGED_ESTIMATE
                            estimate = merge(estimate, (estimate = 1.01 * estimate.estimate,))
                        end
                        refs = [reference_joint(kind, yy, ee, pp, gg, P, ze, zp, trial, bits, shift) -
                                reference_joint(kind, yy, ee, pp, gg, P, ze, zp, a, bits, shift)
                                for bits in (128, 256)]
                        error = abs(BigFloat(estimate.estimate) - refs[2])
                        relative = error / abs(refs[2])
                        println("CASE ", kind, " n=", n, " direction=", direction,
                                " reversed=", reversed, " shift=", shift,
                                " Q8=", estimate.estimate, " E=", estimate.error,
                                " reference=", refs[2], " relative=", relative)
                        @test abs(refs[1]-refs[2]) <= max(abs(refs[2])*big"1e-16", big"1e-30")
                        @test sign(estimate.estimate) == sign(refs[2])
                        @test relative <= big"1e-4"
                        @test error <= BigFloat(estimate.error)
                        @test direction == 1 ? estimate.margin < 0 : estimate.margin > 0
                    end
                end
            end
        end
    end
end
println("VARIED_ESTIMATED_CHANGE_OK")
