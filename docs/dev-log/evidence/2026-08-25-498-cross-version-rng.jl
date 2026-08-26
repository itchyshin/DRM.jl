using DRM, StableRNGs, LinearAlgebra, Printf
import Distributions
const D = DRM
function draw(seed; ntip=12, per=4, σphy=0.45)
    rng = StableRNG(seed)
    tree = D.random_balanced_tree(ntip; branch_length=0.25)
    species = repeat(1:ntip, inner=per)
    n = length(species)
    x = randn(rng, n)
    C = D.sigma_phy_dense(tree; σ²_phy=σphy^2)
    u = cholesky(Symmetric(C)).L * randn(rng, ntip)
    y = Float64.([rand(rng, Distributions.Poisson(exp(0.25 + 0.2*x[i] + u[species[i]]))) for i in 1:n])
    (; data=(; y, x, species), tree)
end
println("julia = ", VERSION)
for s in (450, 4501, 4502)
    d = draw(s)
    @printf("seed %-5d  sum(y)=%.0f  sum(x)=%.12f  hash=%s\n",
            s, sum(d.data.y), sum(d.data.x), string(hash((d.data.y, d.data.x)), base=16))
end

# same data, same src, only Julia differs — does the FIT agree?
for s in (450, 4501, 4502)
    d = draw(s)
    f = drm(bf(@formula(y ~ x + phylo(1 | species))), Poisson();
            data=d.data, tree=d.tree, se=false)
    @printf("FIT seed %-5d  sigma=%.10e  conv=%s\n", s, exp(D.coef(f)[end]), f.converged)
end
