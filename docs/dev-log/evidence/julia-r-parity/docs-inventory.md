# Documenter source inventory

This is a **static source** audit. It makes no rendered-site, Documenter-build, deployment, or live-page claim.

- Source pages: 52
- Navigation entries: 51
- Unnavigated pages: 1
- Visible navigation entries: 51
- Hidden navigation entries: 0
- Opening fenced code blocks (heuristic): 244
- Closing fence markers: 244
- Unclosed fenced blocks: 0
- Julia examples (opening-fence heuristic): 161
- R examples (opening-fence heuristic): 4

## Source findings

- `missing_local_target`: @id _group_index
- `missing_local_target`: @id _fit_phylo_mean_laplace_nuisance
- `missing_local_target`: @id _fit_crossed_mean_laplace_nuisance
- `missing_local_target`: @id AugProblem
- `missing_local_target`: @id make_problem
- `missing_local_target`: @id fit_q4_sparse_tmb
- `legacy_transition_page_unlisted`: Preserved transition URL; Documenter's default pagesonly=false build still emits this source page.

Link and code-block fields are source heuristics, not rendered-link or execution evidence. Findings are repair targets, not inventory-check failures. The executable check fails only when the frozen source inventory is inaccurate.
