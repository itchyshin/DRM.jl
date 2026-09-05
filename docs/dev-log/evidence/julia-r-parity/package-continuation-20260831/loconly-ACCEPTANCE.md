# Bounded continuation of interrupted location-only REML file
Scope: entire test/test_location_only_reml_mme.jl on exact current src/test inputs.
CHECK: server-side timeout300s, Julia1.10.10 --project=test, run.jl.
EXPECT: exit0, LOCONLY_FILE_COMPLETE, source hashes unchanged, every test passes.
A timeout or failing test is not completion. Full default suite remains open.
Estimate2–5minutes; Totoro1Julia/1BLAS, no campaign or DRACjob.
