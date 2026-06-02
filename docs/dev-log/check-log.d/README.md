# `check-log.d/` — collision-free per-slice gate entries

**Why this directory exists.** The single Markdown table in
[`../check-log.md`](../check-log.md) grows by *appending a row to the same place*.
When two PRs are open at once (e.g. a docs PR and an engine PR), they both append
at the tail and **always** conflict on merge. With many parallel PRs that becomes
O(n²) hand-resolved conflicts.

**The fix.** New gate entries go here as **one file per slice** — exactly the
pattern `after-task/` already uses. Two PRs adding two different files never
collide, because they touch different paths.

## How to add an entry

Create a file named `YYYY-MM-DD-<slug>.md` containing **one Markdown table row**
(the same five columns as the historical table), e.g.:

```
| 2026-06-02 | **My slice** (#NN / Workflow X) | `Pkg.test()` + docs | ✅ green; what was gated and the result | Shannon |
```

- One row per file. Pick a unique `<slug>` (the slice name) so filenames don't clash.
- No table header in the file — just the row(s). The header lives in the renderer.
- This satisfies Definition-of-Done item 5 (the check-log entry).

## Viewing the combined log

`check-log.md` holds the **frozen history** (through 2026-06-02). To see the full
log — frozen history plus every entry in this directory, in date order — run:

```
julia tools/build_check_log.jl          # prints the combined table to stdout
```

The renderer never rewrites `check-log.md`, so it introduces no new committed
artifact to conflict on.
