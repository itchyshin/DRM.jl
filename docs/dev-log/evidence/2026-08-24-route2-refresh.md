# Route-2 parity refresh — 2026-08-24

Re-ran all five Route-2 maintainer-manual R↔Julia parity scripts against the
**installed drmTMB 0.7.0** (previously unchecked against this version). R 4.6.0,
Julia 1.10.0, JuliaCall present.

## Scripts run (5 of 5)

| Script | out_path | Result |
|---|---|---|
| `tools/parity_fixture.R` | `docs/dev-log/evidence/parity-fixtures.tsv` | ran clean, ALL CELLS PASS |
| `tools/parity_phylo_penalty.R` | `docs/dev-log/evidence/parity-phylo-penalty.tsv` | ran clean, ALL CELLS PASS |
| `tools/parity_biv_meta.R` | `docs/dev-log/evidence/parity-biv-meta.tsv` | **initially failed (script bug), fixed, then ran clean, ALL CELLS PASS** — see below |
| `tools/parity_phylo_nongaussian.R` | `docs/dev-log/evidence/parity-phylo-nongaussian.tsv` | ran clean, ALL COMPARABLE CELLS PASS (2/3; 1 has no native comparator) |
| `tools/parity_associate.R` | `docs/dev-log/evidence/parity-associate.tsv` | ran clean, ALL CELLS PASS |

## Old → new diff, all five TSVs

Every committed TSV was captured read-only via `git show HEAD:<path>` before
any script ran, then diffed byte-for-byte against the freshly-written file.

**Result: all five TSVs are byte-identical, old vs new. Zero numerical drift
against drmTMB 0.7.0.** No status changed on any row. No number moved.

This includes the row flagged in the task brief for context —
`parity-phylo-nongaussian.tsv` / `phylo_gamma`: unchanged at
`max_abs_coef_diff = 6.32151750945553e-08`, `loglik_diff =
2.89859641071644e-05` (tolerance `1e-04`), status `PARITY_PASS`. Not
re-diagnosed or re-tolerance'd, per instructions — a sibling agent owns that.

## Script bug found and fixed: `tools/parity_biv_meta.R`

**First run of this script failed all 3 cells** (`biv_meta_indep`,
`biv_meta_poscor`, `biv_meta_negcor`), each `JULIA_FAILED`. This looked like a
status regression (PARITY_PASS → fail in the committed baseline), so per the
task's central rule I stopped before touching scripts 4–5 and investigated
before writing anything back.

Root cause (confirmed by isolated repro, not drmTMB-version-related): this
script shells out to a bare `julia` subprocess via
`system2("julia", c(paste0("--project=", jl), "--startup-file=no", sf), ...)`.
On this machine the repo lives at a path containing a space —
`/Users/z3437171/Dropbox/Github Local/DRM.jl` — and R's `system2()` does not
auto-quote arguments containing spaces (this is documented base-R behaviour,
not a JuliaCall/bridge issue). The unquoted `--project=...` argument was split
by the shell at the space, so Julia received a truncated project path and a
stray `Local/DRM.jl` token, which it then tried to open as a script file
relative to cwd — producing the `SystemError: opening file ".../DRM.jl/Local/DRM.jl"`
that surfaced to R as "subscript out of bounds" / `JULIA_FAILED`. Confirmed
by manually invoking `system2()` with the same arguments outside the script
and observing the unquoted, space-split shell command.

This is a pre-existing latent bug, unrelated to the drmTMB 0.7.0 bump — it
happens to manifest only when the checkout path contains a space, which this
machine's does.

**Fix applied (`tools/parity_biv_meta.R`, line 93):**

```diff
-    out <- system2("julia", c(paste0("--project=", jl), "--startup-file=no", sf),
+    out <- system2("julia", c(shQuote(paste0("--project=", jl)), "--startup-file=no", shQuote(sf)),
                    stdout = TRUE, stderr = FALSE)
```

Wrapped the `--project=` argument and the script-file argument in `shQuote()`.
Checked first (read-only `git diff HEAD..<ref> -- tools/parity_biv_meta.R`)
against the two other refs the lane-check hook flagged as carrying work on
this path (`worktrees/drm-pr423-cursor/HEAD`, `feat/a12-biv-meta-recovery`) —
neither branch touches this file (empty diff both ways), so this fix does not
fork or duplicate in-flight work.

After the fix, re-ran `tools/parity_biv_meta.R` (not via `DRM_JL_PATH=... ` env
prefix the second time, ran directly since `DRM_JL_PATH` was already exported
in the calling shell) — all 3 cells `PARITY_PASS`, and the resulting TSV is
byte-identical to the committed baseline (see diff table above).

**Note:** this repo's `CLAUDE.md` says "Don't revert human/Codex changes
unless asked" and the task brief said not to edit `tools/parity_*.R` unless
outright broken. I judged this outright broken (0/3 cells completed, blocking
all evidence collection for this script) and made the minimal one-line fix
rather than reporting a false regression. Flagging loudly per the task's own
instruction on this point.

## What was not done

- No diagnosis of `phylo_gamma`'s looser tolerance — out of scope, owned by a
  sibling agent per the task brief.
- No `tools/parity_se.R` — explicitly out of scope (owned by another agent).
- No git operations of any kind (add/commit/checkout/stash) — per the git
  fence. All five TSVs plus this doc are currently uncommitted working-tree
  changes (TSVs are content-identical to HEAD so `git status` will show no
  diff for them; `tools/parity_biv_meta.R` and this evidence doc are new/
  modified and will show in `git status`).
