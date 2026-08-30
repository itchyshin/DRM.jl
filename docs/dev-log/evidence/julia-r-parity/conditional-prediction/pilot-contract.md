# Stored Gaussian random-intercept prediction pilot

Two ML cells: y ~ x + (1 | g), with sigma ~ 1 or sigma ~ x.
Seed202608302, 12groups × 12observations, shuffled rows; grouping factor includes
an unused level and reverse-sorted levels. No offsets, weights, structured terms,
missing values, slopes, scale random effects or REML. Newdata omits g because its
native contract sets random effects to zero.

Alignment: mu=X beta; log(sigma)=S gamma; b~N(0,s_b² I);
y|b~N(X beta+Z b,D), D=diag(exp(2 S gamma)). Julia's resd coefficient is log(s_b).
Independent dense Gaussian oracle at Julia's fitted coefficients:
V=D+s_b² Z Z'; E[b|y]=s_b² Z' solve(V,y-X beta);
stored conditional mu=X beta+Z E[b|y]. Stored sigma=exp(S gamma).
Newdata uses Xnew beta and exp(Snew gamma), with no group contribution.

Declare before execution:16prediction outputs (2cells × stored/newdata × mu/sigma
× link/response). Adapter tolerance1e-10 versus dense oracle. Separate independent
native-fit parity tolerance4e-6; retain every failure/status. Native and Julia
convergence must both pass for fit parity. No coefficient/estimator substitution.
First execute against the previously committed S10 candidate to demonstrate the
missing conditional-payload refusal, then execute against the isolated new R
candidate. Julia source remains unchanged. Threads1 and measuredBLAS1. Estimate
each cold bridge pilot≤30seconds based on prior~19-second four-cell runs; stop and
report if it overruns. No speed claim or remote compute.

Review expansion (before the next run): add a third case with numeric group
labels1:12, also using g as a numeric fixed predictor (y~x+g+(1|g),sigma~1).
Retain the same data values except the grouping representation. Newdata has
g=1,5,12. Denominator now24outputs; all previous cases and tolerances remain.
This tests typed label transport without silently converting a numeric fixed
predictor to a factor. Freeze Julia source-file hashes before/after execution.
