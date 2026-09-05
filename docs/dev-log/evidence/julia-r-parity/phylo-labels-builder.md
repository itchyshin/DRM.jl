# Quoted Newick tip labels — builder gate

## Scope

This leaf preserves **tip-label** identity through the R Julia bridge and the
Julia `augmented_phy()` parser.  It admits quoted labels containing spaces,
punctuation, Unicode, tabs, newlines, and apostrophes without replacing or
normalising any character.  Internal node labels remain parsed and discarded,
as in the existing sparse-tree contract; this leaf does not establish their
round-trip identity.

The R native validator accepts any non-missing, nonempty, unique character tip
label.  Therefore the bridge must not add a newline/tab refusal merely because
the conventional Newick grammar is narrower.  Its serializer will quote the
label and the Julia parser will retain the literal characters.

Out of scope: Newick comments/Nexus metadata, zero-length or unary branches,
single-tip trees, non-ultrametric correlation-scale bridging, fitting,
profiling, and performance claims.

## TDD acceptance

Before the parser/serializer change, the following focused checks must fail for
the missing quoted-label admission; their complete stdout/stderr is retained as
`phylo-labels/julia-red-001.log` and `phylo-labels/r-red-001.log`.  Do not
substitute an unrelated argument error for either red result.

```sh
cd /private/tmp/drm-parity-20260830/DRM.jl
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. \
  -e 'include("test/test_phylo_labels.jl"); println("PHYLO_LABELS_PASS")'

cd /private/tmp/drm-parity-20260830/drmTMB
Rscript --vanilla -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-phylo-labels.R", stop_on_failure = TRUE); cat("JULIA_PHYLO_LABELS_PASS\\n")'
```

After the implementation, rerun the exact commands and retain complete green
logs beside the red logs.  The Julia test must prove parsed names, leaf order,
and an unchanged dense covariance for a mixed quoted-label tree.  The R test
must prove raw `tip_order`, lossless Newick escaping, and preservation of the
native named covariance/row identity after serialization and edge reordering.
The Julia parser is the decoder oracle: `ape::read.tree()` is not a gate because
ape documents quoted-label handling as evolving. Both test suites must also
keep old simple/underscore labels byte-for-byte compatible and reject malformed
quotes or trailing Newick input clearly.

## Encoding contract

The serializer emits an old-compatible unquoted label only for
`[A-Za-z0-9_.-]+`.  Every other valid R tip label is emitted as a single-quoted
Newick label; a literal apostrophe becomes two apostrophes.  The Julia parser
accepts both forms.  It skips whitespace only between grammar tokens, never
inside a quoted label, and rejects whitespace embedded in an unquoted label.

Reference for conventional quoted-label escaping: Gary Olsen, *Newick's 8:45
Tree Format Standard*, <https://phylipweb.github.io/phylip/newick_doc.html>.
