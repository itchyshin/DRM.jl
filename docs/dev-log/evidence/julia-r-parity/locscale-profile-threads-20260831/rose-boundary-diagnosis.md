# Rose independent bounded review

Reviewed37cb919f and inner7f957; noedits/fits/tests. Corrected replay proves all
four constrainedLBFGS attempts stop with ls_failed=true. OptimNoXChange does
not prove unrepresentabletrialsteps: unchangedstate has priority over failed
line search in its termination-code selection. Finiteabove-tolerancegradient
and unsuccessfultermination are correctly rejected. No proofintervalsunbounded.

Leading hypotheses: cancellation in covariance inverse/derivative contractions
near thin Cholesky factor; marginalobjective precision versus Armijodecrease;
LBFGSdirection/history trouble. Lowerintercept has zero innerrefusals and is the
first discriminator. No mechanism is yet established.

Recommended bounded diagnostic fromsavedterminalpoint: repeatedcold/sharedmode
f/g, componentgradients; independent256bit determinant andtraceidentities
(detLambda=exp(2lambda1+2lambda3), tr(invLambda*dLambda)=(2,0,2)); compare direct
logCholeskyprecision derivative. Then shortdirectional stepladder ifneeded.
Eightlatent-coordinatewhitened oracle is a later diagnostic, not authorized
productionrewrite. Preservefourtargets/interiorandboundaryregressions beforefix.
Mainfitstationaritystillneedsresolution. Stale trust-regionprofiler comment at
locscale_fit.jl:42 found; nochangeauthorizedyet.
