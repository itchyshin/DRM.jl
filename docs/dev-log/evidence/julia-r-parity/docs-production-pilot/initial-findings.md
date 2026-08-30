# Production documentation findings

Production001 passed navigation/example execution with50 visible pages and51
emitted pages (122 example blocks,115.453s). It omitted modules=[DRM], so it is
not module-documentation coverage evidence. Its unchanged Vitepress config built
in7.18s with no ignoreDeadLinks override.

Actual browser inspection found YAML printed as homepage text and a13-item
navbar extending outside the viewport. The homepage now wraps its YAML in a
raw HTML node; a real one-page run against loaded DocumenterVitepress0.3.4
(2seKb) emits intact frontmatter starting on line1 (3.597s, zero examples).
This uses that version's literal RawNode passthrough, not newer frontmatter
hoisting. A scout initially inspected neighboring aVWpg and retracted that
version-specific explanation. Final rendered homepage proof is still pending.

The navigation is being grouped into six menus while retaining all50 original
page routes. A non-evaluating AST interpreter reads the actual docs/make.jl
pages tree;14 tests cover nested/order preservation and executable impostors.

Production002 included modules=[DRM] and failed on109 docstrings absent from
canonical manual blocks. These failures are retained; documentation coverage
is not being weakened or disabled. Additional reference material is in progress.

Pre-edit correction: homepage worker tried a nonexistent relative lane tool.
Root ran the canonical external preflight and inspected origin/docs-drmtmb-look:
its homepage blob is identical to HEAD, so no alternate homepage work is lost.
Root also inspected older docs/make.jl diffs before editing navigation; they do
not contain the overflow repair and remove newer routes we retain.
