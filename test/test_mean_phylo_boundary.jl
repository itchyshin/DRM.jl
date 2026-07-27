# Regression: the mean-phylo Gaussian ML fit must not return an impossible
# positive log-likelihood / H=1 boundary blow-up.
#
# On this fixture (40 species, ONE observation per species, weakly identified
# phylo-vs-residual variance) the sparse Woodbury solve used to catastrophically
# cancel as the residual σ²→0: the data quadratic eᵀV⁻¹e went NEGATIVE, so
# logLik = −0.5(n·log2π + logdetV + quad) flipped to +1.24e6 with H=1.0 and
# converged=true — a silent wrong-model result. phylolm fits this exact dataset
# at H≈0.534, logLik≈−40.41 (DRM.jl matches phylolm on 19/20 sibling seeds).
#
# Fixture: validate/01_generate_and_R.R seed 4 (ape::rcoal(40), height-1, BM
# trait with phylo var 0.6 + residual var 0.4), exported to Newick + the 40 tip
# values below.
using DRM
using Test

@testset "mean-phylo ML: no boundary logLik blow-up (seed-4 fixture)" begin
    nwk = "(((t1:0.1147081583,t2:0.1147081583):0.1320412801,(((t3:0.07498500778,(t4:0.02967730724,(t5:0.01701760716,t6:0.01701760716):0.01265970008):0.04530770054):0.01024723651,t7:0.08523224429):0.02778956561,((t8:0.03737138687,t9:0.03737138687):0.03685137143,((t10:0.001045732931,t11:0.001045732931):0.02746584436,t12:0.02851157729):0.045711181):0.03879905161):0.1337276285):0.7532505616,(t13:0.4796698521,(((t14:0.00326536466,t15:0.00326536466):0.0809851763,(t16:0.04490150152,((t17:0.02551429117,t18:0.02551429117):0.0122735354,((t19:0.02136282301,(t20:0.003709891751,t21:0.003709891751):0.01765293126):0.01538441079,(t22:0.01177146156,t23:0.01177146156):0.02497577224):0.001040592764):0.007113674951):0.03934903944):0.3877534158,(((((t24:0.005303870848,t25:0.005303870848):0.005162704052,t26:0.0104665749):0.009105916515,t27:0.01957249142):0.004300136683,t28:0.0238726281):0.4311731956,(((t29:0.00550898558,t30:0.00550898558):0.05891397583,(t31:0.04690247956,t32:0.04690247956):0.01752048185):0.1030365996,(t33:0.1041672333,((((t34:0.02581880575,t35:0.02581880575):0.0004867748501,t36:0.0263055806):0.0114638488,(t37:0.02742148639,t38:0.02742148639):0.01034794301):0.0117890006,(t39:0.009843615504,t40:0.009843615504):0.03971481449):0.05460880334):0.06329232766):0.2875862627):0.01695813301):0.007665895398):0.5203301479);"
    species = ["t$i" for i in 1:40]
    y = [0.224879897068412, -0.236807164123477, 0.997912319194238, 1.16543183321086,
         -0.383547741194692, 0.474874428958168, 1.04883203522525, 0.444461739076704,
         -0.563848164948473, 0.151178897308193, 0.323822579429749, 0.176281718418152,
         1.39503381130981, 1.04199055519763, 2.20285976463229, 0.976630355982372,
         2.2887097092328, 1.96755729966057, 2.32879531181019, 1.97127155160789,
         1.94167836936452, 1.04151748563691, 1.86183344931414, 2.0143231326374,
         1.75020996928443, 2.38475858131317, 1.6581911013036, 3.05175368360549,
         1.91915846638364, 2.53807020155283, 0.50064333788783, 2.35052187174623,
         2.74767312773271, 2.16765955639917, 1.38527003202804, 0.950231114747105,
         1.21286834907815, 1.6803454775979, 1.19480984548367, 1.75873825314882]

    phy = augmented_phy(nwk)
    fit = drm(bf(@formula(y ~ phylo(1 | species)), @formula(sigma ~ 1)), Gaussian();
              data = (; y, species), tree = phy, method = :ML)

    ll = loglik(fit)
    phyloSD = exp(coef(fit, :resd)[1])
    residSD = fit.scales[:sigma][1]
    H = phyloSD^2 / (phyloSD^2 + residSD^2)

    @test isfinite(ll)
    @test ll < 0                          # a Gaussian log-likelihood cannot be positive here
    @test residSD > 1e-4                  # residual SD must not collapse to ~0
    @test H < 0.99                        # must not pin at the variance boundary
    @test isapprox(H, 0.534; atol = 0.1)  # match phylolm's Pagel-λ ML
end
