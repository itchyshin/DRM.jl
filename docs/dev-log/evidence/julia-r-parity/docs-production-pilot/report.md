# S13 production documentation checkpoint

Bounded local result, 2026-08-30. Programme issue: https://github.com/itchyshin/DRM.jl/issues/563.
Parent revision: c6ff8bd5. Frozen Julia engine remains f47789646f27221ba4fad29a8ba1b3b8a790b521; no source edits in this slice.

## Changes and evidence

- Preserve all original 51 source pages and 50 visible routes; add one developer reference appendix. Final navigation: five menus, 51 visible routes, 52 emitted source pages. Legacy get-started URL remains emitted.
- Fix homepage frontmatter for the actually loaded DocumenterVitepress 0.3.4 backend; replace unsupported future-bridge and universal performance claims with current scoped capability wording.
- Cover 109 previously unregistered docstrings (22 public/reference entries and 87 advanced entries). Resolve seven source cross-references without editing engine files. Clarify fixed-effect predictions versus integration over random effects; source docstring still has legacy wording.
- Production005: modules=[DRM], warnonly=false, real production navigation; 52 pages and 122 executed examples, 111.082 seconds. Julia1.10.0, Julia threads1, explicitly set and measured BLAS threads1. Markdown-only backend step; theme is independently checked below.
- Preview004: copied exact production005 emitted Markdown; two declared preview-only version metadata files, cached Vitepress1.6.4. Node theme build6.94s, no ignoreDeadLinks. Local preview metadata is not a deployment receipt.
- Hardened HTML checker: 53 files including404; 6378 local navigation links, 476 href/src asset references, 827 HTML fragments, zero failures. External URLs, JavaScript behavior and non-HTML fragment conventions are excluded. srcset is explicitly rejected, not silently ignored.
- Independent Rose review approved the bounded patch and eight HTML negative/control tests; navigation16/16 passes. Screenshot inspection: home and Getting started at1280x720, light/dark; all five menu labels and right icons fit. Clicking homepage Get started navigated successfully.

## Retained failures and limits

Production001 omitted module coverage and exposed literal YAML/overflow in the browser. Production002 failed109 missing docstrings. Production003 failed seven unresolved refs. Production004 passed but six menus still clipped article icons; final005 uses five menus. Negative auditor controls caught same-page fragments, symlink fallback escape, empty builds, root fallback, exact asset targets and srcset. Earlier false passes are not accepted evidence.

Final hashes bind current input files and both zip archives. Source inputs were re-hashed after the final build; production004 pre-run hashes retain the preceding navigation version. No intervening source edits were made between production005 and this receipt; final comparison checks all bound inputs. The HTML archive contains local preview metadata; the emitted Markdown archive does not add those files.

This does NOT cover mobile layouts, every page's visual quality, external URLs, served GitHub Pages, R article deployment, full capability parity, inference correctness across all model cells, or any performance campaign. G0–G8 remain open. Protected S5 source edits still require the human approval already requested; no workaround applied. Active agent-hours were not instrumented; do not report elapsed build time as agent-hours. No Totoro/DRAC compute launched.

## Reproduce

Read the two retained leaf gate files for exact source/theme/check commands and expectations; use new build directories because the source runner refuses stale output. Run Python unittest modules tools.tests.test_parity_docs_audit and tools.tests.test_parity_html_audit; run julia --startup-file=no tools/tests/test_docs_navigation.jl. The input manifest and archived output SHA256 maps support independent content verification.
