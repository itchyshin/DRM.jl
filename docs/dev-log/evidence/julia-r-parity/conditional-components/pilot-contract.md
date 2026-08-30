# Gaussian conditional components: independent oracle and frozen pilot

Four additional complete-data ML fixtures, seed202608303, n144,12groups g and
6crossed groups h. Random components: independent x slope; correlated intercept
and x slope; g intercept+h slope; g intercept+h intercept. The previous three
RI fixtures and their failures remain required and unchanged.

Mean model y=X beta+Z b+epsilon, b~N(0,C), epsilon~N(0,D).
D=diag(exp(2 S gamma)); K=Z C Z'; V=D+K.
Independent dense conditional oracle: mu_cond=X beta+K solve(V,y-X beta).
ML loglik=-[n log(2pi)+logdet(V)+(y-X beta)'solve(V,y-X beta)]/2.

Independent scalar component j uses C_j=s_j²I and loadings1orx.
The correlated component uses L=[exp(a) 0; c exp(b)] and C_group=L L'.
Raw Julia coefficient keys: resd_g/resd_h are logSD; recov_g:L11/L22 are a/b
and recov_g:L21 is c. Build K directly in observation space, independently of
Julia's grouped and whitened mode calculations.

For multiple components, existing Julia code clamps log residual SD and log
random-effect SD to±30. The engine oracle must use these same clamps, record
whether active, and compare native fits separately. A clamp-induced mismatch
remains a required compatibility gap, not a reason to discard a case.

Before execution:32prediction outputs, same adapter tolerance1e-10 and
independent-fit tolerance4e-6 as prior Gaussian pilots. Engine likelihood versus
dense oracle tolerance1e-8. Fixed startup/BLAS1/Julia1, source hashes before/after,
retained data, coefficient names, failures and convergence. No default-control
or estimator changes. Estimate≤2minutes locally including new-route compilation;
stop and report if exceeded. No benchmark or performance claim.

Required remaining gaps: repeated components sharing one group overwrite mode
dictionary entries in current Julia code; wider correlated slopes and mixed
correlated/scalar components need engine contracts. These are not removed from
the full programme denominator. No source edits to bypass the protected patch.
