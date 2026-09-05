# Julia–R parity worktree census

Collected 2026-08-30 by `tools/parity_worktree_census.py` from the two original
repository metadata stores. The collector records registered Git worktrees and
stashes, path state, porcelain status records, observed checkout HEAD and frozen main
SHAs, command errors, and collection time. It does not inspect file contents or
perform checkout, cleanup, fetch, stash application, or network operations.

| repository metadata | registered entries | usable | missing | broken links | dirty worktrees | stashes | errors |
|---|---:|---:|---:|---:|---:|---:|---:|
| DRM.jl + drmTMB | 153 worktrees + 18 stashes | 136 | 6 | 11 | 33 | 18 | 17 |

The JSON receipt is the load-bearing artifact. Missing paths and all command
errors remain explicit; an empty result is never treated as successful
collection. The verifier also rejects duplicate paths, inconsistent totals,
unknown entry kinds or path states, and damaged JSON. A damaged-input check is
available with `python3 tools/parity_worktree_census.py self-test`.

Version2 checks actual temporary Git repositories: clean and dirty worktrees, renamed
and untracked files, newline-containing paths, missing directories, and foreign repository
linkage. Five damaged-receipt controls exercise counts, stash errors, unknown status,
wrong linkage and malformed source identity. The full fresh collection retained the
counts above. The 17 errors classify unavailable paths; they are not unknown statuses
on usable trees.

This is a registered-worktree census only. It does NOT cover unregistered clones,
Claude/Cursor history obligations, content preservation, stash recovery or permission
to retire anything. The broader S1/S3 and G1 obligations remain open.

Verification: `python3 tools/parity_worktree_census.py verify --input .unlazy/julia-r-parity/worktree-census.json` → `WORKTREE_CENSUS_VALID`.
