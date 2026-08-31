# Completed location-scale suffix

Three original files completed on frozen source 479f1e06: structured location-scale,
sigma-axis random effects, and nonconstant sigma with random effects. Totoro
Julia 1.10.10, one Julia and one BLAS thread: 55 assertions across four testsets,
126 seconds, exit 0. All 327 hashes agree with the immutable Git source, and
before/after manifests are identical. Runners match their hashes in the raw log.

This completes the unfinished suffix of the earlier capped group without
rerunning completed files. It does not run the two slow profile testsets, which
remain unmet. No full-suite, cross-engine parity, coverage or speed claim.
