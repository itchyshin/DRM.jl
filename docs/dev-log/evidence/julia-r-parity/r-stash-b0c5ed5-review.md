# One R inference stash: preserved, superseded, not retired

The immutable stash b0c5ed5dc597f4ab8b0435b8ec441e2e93f2453d contains two
modified regular files: R/julia-bridge.R and tests/testthat/test-julia-inference.R.
Its index delta and third-parent untracked tree are empty. Private source
snapshots stay outside this MIT repository; the adjacent JSON contains hashes
and modes only, the final probe script hash and the private recovery location.

The final unlazy check actually ran with --reverify under Python optimization:
one known-Git-object corruption test and a fresh saved-base replay passed. It
reconstructed base → index → working tree, checked exact Git blob IDs and modes,
and rejected deliberately damaged restored bytes. This is a backup of the stash
delta and its required bases, not the full repository or commit history.

Rose independently checked all six saved file versions in the v3 snapshot
against immutable Git. Final v4 repeats the repaired check through unlazy;
the compressed log is retained beside this note. The early tool used Python
assertions, which -O disables; explicit exceptions now protect every oracle.
An --approve call on an already checked ledger printed a cached pass without
execution; that log is not final evidence. --reverify produced the retained RUN.

## Disposition against frozen main

The stash implementation landed in 414b0f95aa9b932eb8dd7824a9ada348d462d4a8,
an ancestor of R main b35642b4560072cadba7e595e66e00209ebdeb40. Rose found no
source hunks requiring recovery. In that frozen main:

- The fixed-effect inference caller and helper are present (julia-bridge.R:1147,
  1762); later code fixes formula translation and family-specific bootstrap
  keywords, and refuses unsupported non-Gaussian phylogenetic bootstrap.
- Wald interval transformation, targets and scale aliases are identical to the
  stash (2596, 2670, 2729); target validation and row marshalling are present
  (2794, 2945).
- The modified Wald test block is byte-identical (test-julia-inference.R:67).
- Whole-file restoration would remove the CRAN setup guard and later tests,
  along with newer inference fixes. Do not restore the old files over main.

Decision: **preserve as superseded WIP; recover no source hunks; retire nothing**.
This leaves 17 other stashes and worktree-specific recoverability/disposition
work open in the programme. The counts describe the earlier 18-stash census,
not an assertion that no new stash can appear after this snapshot.
