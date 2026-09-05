# S13 documentation source execution

Final run003 passed the actual unlazy CHECK/EXPECT gate: **51 source pages,
122 example blocks, 111.795 seconds**, Julia1.10.0, one Julia thread and measured
BLAS1. `full-source-003-inputs.json` binds every source page and the docs runner;
`full-source-003-outputs.json` binds all emitted files and retained logs. The
emitted Markdown/config/components are retained in `full-source-003-emitted.zip`.
No source changed between the captured input hashes and archive verification.

## Earlier attempts and controls

- The nested synthetic positive emits its marker; the deliberately failing
  nested example throws. The three real pages execute four examples in14.283s.
- Full-source001 failed on duplicate mf_coef, three undocumented symbols in
  @docs, and a missing Random import in the separate phybb example module.
- Full-source002 emitted51 pages without fatal errors in110.775s, but its gate
  stayed red:119 had omitted three indented @example blocks in
  tutorials/bivariate-nongaussian.md. All122 remain included in003.
- logs-manifest.json binds the eleven historical logs, including failed
  synthetic setup probes. One environment-bearing line is redacted; its
  original hash and the sanitized copy hash are distinct and retained.
- Source inventory check and eight inventory tests pass. Source reviews by
  Rose required and received precise quadrature, Gaussian integration,
  raw-tree scale, replication and low-level initial-value wording corrections.

## Visual scope and remaining work

The screenshots show the location-scale page in light/dark desktop view from
three-page output nested-three-pages-001. That preview uses flat navigation and
ignores links to omitted pages; it is not production navigation/link evidence.
Node20/Vitepress1.6.4 rendered the preview in3.61s. Full-source003 uses flat51-page
navigation, while production docs/make.jl has50 visible pages and the legacy
get-started URL remains emitted but unlisted.

Four index links generated Documenter warnings; example/docstring errors are
fatal, but cross-reference/link/footnote warnings remain nonfatal in the runner.
The repeated fam example-module warning and missing-logo/favicon warnings are
also retained. No mobile, full production theme, live deployment, external-link,
statistical accuracy, or performance claim follows from this receipt. A tutorial
sentence combining formal testing with aicc also needs a follow-up wording audit.
Full G6 and all programme G0–G8 remain open. No engine edits or remote compute.

Navigation scout correction: the backend helper pagelist2str cannot accept a
dummy document for the42 unnamed production pages; it reads their AST headings.
Do not use the initial proposed config-only recipe. A measured ~112s source
rerun with actual production navigation is safer than an unverified rewrite.

Final Rose verdict: APPROVE local S13 checkpoint. Rose independently checked
all51 source hashes,122 example blocks,64 archived files and the actual gate
receipt. Raw retained logs preserve tool-emitted trailing spaces; source/tool
diff whitespace checks exclude only those logs rather than changing evidence.
