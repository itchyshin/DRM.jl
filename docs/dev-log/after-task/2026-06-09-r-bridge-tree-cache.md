# After-task: R bridge repeated-tree cache

Date: 2026-06-09

## Summary

Added a small DRM.jl bridge cache so repeated `drm_bridge()` calls that receive
the same Newick string reuse the parsed all-node `AugmentedPhy` object.

This is deliberately scoped to the R bridge boundary. It does not expose a new
user algorithm setting and does not change the native `drm()` model API.

## Evidence

Project instructions checked after the local patch:

- `HANDOVER.md` and `ROADMAP.md` still identify the R-side bridge as the
  Phase 1.5 direction.
- `docs/dev-log/coordination-board.md` puts Codex in the engine lane and
  confirms `test/test_bridge.jl` is wired through `test/runtests.jl`, but any
  `src/` change still needs normal maintainer review before merge.

Focused Julia bridge test:

```sh
/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia --project=. -e 'using Test; include("test/test_bridge.jl")'
```

Result: 32 expectations passed.

Paired drmTMB-side evidence:

```text
AVONET/Hackett 9,993-tip Gaussian phylo bridge
previous warm bridge row: 17.222 s
new warm bridge median:   3.784 s
new warm bridge minimum:  3.538 s
direct DRM.jl kernel:     2.623 s
```

The paired R bridge test also confirms unused data columns are trimmed and
same-tree/same-species payloads are reused before JuliaCall transfer.

## Interpretation

The main repeated-refit overhead is no longer Newick parsing or R-side row-order
preparation. The remaining gap between `drmTMB(..., engine = "julia")` and
direct DRM.jl is mostly JuliaCall transfer, returned post-fit payload, and R
object reconstruction.

## Next

Profile and bootstrap benchmarks should now separate cold setup, warm same-tree
payload reuse, direct Julia kernel time, and returned-object reconstruction.
