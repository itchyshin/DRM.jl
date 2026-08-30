# First-reader Documenter pilot evidence

This record is a source-render pilot, not a full documentation build, Vitepress
theme build, deployment, link check, or live-site check.

## Current source anchor

The static inventory generated on 2026-08-30 anchors the pilot inputs:

| source | SHA-256 |
| --- | --- |
| `docs/make.jl` | `9d48880dd4c8d613e273a23485acb1c8b94ac414b79af1b9bcb89f8fa308f73e` |
| `docs/src/getting-started.md` | `18aeef43b7f930e3bb86f6bdfdd25fead6256aed4b3ce584edb9bb9f414e6fa4` |
| `docs/src/get-started.md` | `f9f378e01c8899322e3c364afe0094cf5e37476bfba5b2df49854a9ac42db3b5` |
| `docs/src/r-julia-bridge.md` | `915a7ff7a84ee471a88ba4f486a4830cbeb6c5d9bd69f07a7c38ce2a5004e049` |

The current navigation has 50 visible entries. `get-started.md` is the one
explicitly classified, unlisted legacy transition URL; a normal full build with
Documenter's default `pagesonly = false` still emits it.

## Passing writer smoke

The final cached DocumenterVitepress writer run used `pagesonly = true` and the
two compatible visible pages, `getting-started.md` and `r-julia-bridge.md`. It
ran in 21.693 seconds with one Julia and BLAS thread, loaded DRM.jl from this
isolated worktree, executed the nine canonical `@example` blocks under strict
`:example_block` handling, and emitted exactly two Markdown pages. The full
113-line log is ignored build evidence at
`docs/build/parity-pilot-vitepress-pagesonly-markdown-v4/pilot.log`.

The canonical page also states the current summary limitation: its scale-block
`z` and `p` values are unavailable (`NaN`), while estimate, standard error, and
interval remain finite. Supplying R-facing scale-block z/p results is an open
post-fit parity obligation; the pilot does not change that boundary.

The run retained ten warnings for local links that intentionally point outside
the two-page denominator, plus local/no-deploy and absent optional
Vitepress-asset warnings. It used `build_vitepress = false` and `install_npm =
false`; it therefore proves the cached DocumenterVitepress writer for this
visible navigation subset, not the Vitepress theme, the legacy transition page,
the full 51-page source tree, or a served site.

## Separate HTML compute pilot

The earlier `docs/build/parity-pilot-pagesonly-html-v2/pilot.log` is a distinct
22.837-second Documenter.HTML computation. It rendered three pages, including
the then-hidden transition page, and executed the same nine canonical examples.
It is execution evidence only; it is not Vitepress writer, theme, navigation,
or live-site proof.

## Retained failed runs

| run | retained log | outcome |
| --- | --- | --- |
| initial Vitepress | `docs/build/parity-pilot/pilot.log` (4,112 lines) | Invalid denominator: `pagesonly` was omitted, so 51 pages were emitted and 96 nested-page examples failed because their build working directories were absent. The installed writer then failed on Documenter's `hide(...)` tuple (`pagelist2str` has no tuple method). |
| pagesonly precheck | `docs/build/pilot-pagesonly-html-precheck-failed.log` (13 lines) | No build began: a pilot source-count expression was incorrect. |
| pagesonly configuration | `docs/build/parity-pilot-pagesonly-html/pilot.log` (119 lines) | No render: the first `warnonly` setting made intentionally out-of-scope cross-references fatal. |

Every pilot run uses a distinct ignored output path. `tools/parity_docs_pilot.jl`
accepts `--build-dir docs/build/<fresh-name>` and refuses an existing path; the
gate must provide a fresh name rather than deleting or reusing prior evidence.

## Executed acceptance and durable logs

The coordinator replaced the draft's placeholder commands with the exact
`leaf-S13-reader-final.md` commands and ran unlazy against current source.
Both executable gates passed (exit0 and matched EXPECT): eight inventory tests
plus source verification, and the two-page writer at the fresh
`docs/build/parity-pilot-unlazy-v5` path. The earlier draft ledger is marked
unmet as written; its historical HTML command no longer matches the current
pilot script. This is not a four-gate or full-documentation pass.

Six byte-preserving compressed logs (including failed attempts and the final
unlazy execution) are retained in `docs-pilot-logs/`; `manifest.json` records
their original paths, uncompressed byte sizes and SHA-256 checksums. The v4
writer log is the complete raw writer output for the final prose. v5 repeats
that same source through the bound acceptance checker.
