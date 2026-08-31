# Polytomous tree admission

Shinichi relayed Ayumi-san’s report on 2026-08-30. The three-tip ultrametric
star `(a:1,b:1,c:1);` reproduces the restriction without fitting: native R’s
validator accepts it, the R-to-Julia serializer refuses it as non-binary, and
direct Julia rejects its four nodes because it expects five. The two raw logs
and `admission-001.json` retain the results and source hashes.

This is a required parity gap, not a permitted exclusion. The fix must preserve
branch lengths, root conditioning and implied covariance, with tests for star
and mixed multifurcating/binary trees. Arbitrary positive-length binary
resolution changes the model and is not an acceptable workaround. Downstream
node-count assumptions must be audited before removing the admission checks.

Ayumi-san’s separate profile/bootstrap report concerns `engine = "julia"`;
this no-fit tree probe does not diagnose those inference workflows. Her issue
is forthcoming. No collaborator message or source change was made here.
