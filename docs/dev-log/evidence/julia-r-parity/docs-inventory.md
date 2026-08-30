# Documenter source inventory

This is a **static source** audit. It makes no rendered-site, Documenter-build, deployment, or live-page claim.

- Source pages: 51
- Navigation entries: 50
- Unnavigated pages: 1
- Visible navigation entries: 50
- Hidden navigation entries: 0
- Opening fenced code blocks (heuristic): 229
- Closing fence markers: 229
- Unclosed fenced blocks: 0
- Julia examples (opening-fence heuristic): 160
- R examples (opening-fence heuristic): 4

## Source findings

- `legacy_transition_page_unlisted`: Preserved transition URL; Documenter's default pagesonly=false build still emits this source page.

Link and code-block fields are source heuristics, not rendered-link or execution evidence. Findings are repair targets, not inventory-check failures. The executable check fails only when the frozen source inventory is inaccurate.
