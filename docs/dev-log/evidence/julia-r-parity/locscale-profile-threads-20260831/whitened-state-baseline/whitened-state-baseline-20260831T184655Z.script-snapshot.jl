using DRM, TOML, SHA, LinearAlgebra, SparseArrays, Serialization, Test
const FIXTURE="/private/tmp/drm-parity-20260830/profile-threads-s11/whitened-boundary-reference/reference-fixture.toml"
@assert bytes2hex(sha256(read(FIXTURE)))=="90469e7c304453c0e400d4c19897e263b61beb0912c0a1c5bc677b4f39fee6ad"
const SOURCE=["src/locscale_inner.jl","src/locscale_grad.jl","src/locscale_fit.jl"]
hashes()=Dict(p=>bytes2hex(sha256(read(p))) for p in SOURCE)
matrix(rows)=permutedims(hcat(rows...))
function main()
    before=hashes();f=TOML.parsefile(FIXTURE)
    y=f["y"];Xm=matrix(f["Xmu"]);Xp=matrix(f["Xpsi"]);gi=f["gidx"];G=f["G"];Q=sparse(matrix(f["Q"]))
    rows=NamedTuple[]
    for c in f["cases"]
        t=c["theta"]
        value=DRM._ls_fit_nll(Val(:gamma),y,Xm,Xp,gi,G,Q,t)
        grad=DRM._ls_marginal_grad(Val(:gamma),y,Xm,Xp,gi,G,Q,t)
        push!(rows,(idx=c["idx"],side=c["side"],theta=t,value,grad,
            value_error=abs(value-c["nll"]),gradient_error=maximum(abs,grad-c["gradient"])))
    end
    after=hashes();serialize(only(ARGS),(;rows,before,after,unchanged=before==after))
    for r in rows;println((;r.idx,r.side,r.value_error,r.gradient_error));end
    @testset "legacy boundary numerical baseline" begin
        @test before==after
        for r in rows
            @test r.value_error<=1e-8
            @test all(isfinite,r.grad) && r.gradient_error<=1e-7
        end
    end
    println("WHITENED_BOUNDARY_BASELINE_PASS")
end
main()
