# Production documentation acceptance, programme G6 still open

1. Build every current source page using production navigation, `modules=[DRM]`, and `warnonly=false`. Run `tools/parity_docs_subset.jl --navigation production --pages-file <inventory> --build-dir <fresh-child-of-docs/build>`. EXPECT all52pages emitted and all executable examples succeed; no missing-docstring or cross-reference failure.
2. Render those emitted pages with the existing Node20 / Vitepress1.6.4 dependencies. EXPECT all-page HTML/assets without broken internal links; no deployment.
3. Inspect representative desktop/mobile and light/dark pages, and run source/output inventories. These checks do not replace remaining page-by-page visual review or live deployment verification.

Current RED001:152.3659s, source unchanged, nine missing reference docstrings. Preserve strict checking and all pages; add reference exposure and correct stale admission text. Original51-page/122example evidence predates the new engine-internals page and was flat-navigation source execution, not this production build.


GREEN002: strict production-navigation source build completed in142.177647s,
exit0,52sourcepages/134exampleblocks, unchanged source inputs. Nine reference
bindings added without changing engine code or weakening strict checks. Actual
Vitepress HTML, visual inspection and live deployment remain unverified.

Totoro default-package timing pilot: stopped by its predeclared300s timeout,
exit124,301s measured wall time. Source/test hashes unchanged. It is INCOMPLETE,
not a full-suite pass. No automatic restart or long campaign is authorized by
this pilot. Retained logs include the timeout and completed test summaries.


HTML render001: exit0 in8.803446s,53HTMLfiles (52source pages +404).
Rendered audit003 is RED:106missing assets, siteinfo.js and versions.js on every
HTML page. These files normally come from integrated writer/deployment steps;
raw split-render output is preserved, no exemption. Seven screenshots support
only sampled desktop/mobile light/dark review. Rose found three auditor false
successes (source symlink escape, SVG href, quoted CSS import); Terra repair and
negative-control re-review pending. Do not trust an all-page pass before that.
