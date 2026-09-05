# General documentation section-anchor repair

## 1. Goal

Keep section headings visible below fixed navigation when readers follow links,
on desktop and phone layouts. This is one G6 obligation within programme #563.

## 2. Implemented

A small Vitepress theme entry adds a stylesheet targeting document headings h1
through h6. Each receives a navigation-height-aware scroll margin. Existing
upstream styles, components, fonts, and navigation remain intact.

## 3a. Decisions and Rejected Alternatives

Rejected replacing the default style.css with a one-rule stylesheet: that would
remove existing theme styles. Instead, preserve the resolved default theme entry
and add one import. No dependency update, page-specific fix, or generated HTML
patch was needed. The upstream entry now has a small maintained local fork.

## 4. Files Touched

Only three authored theme files: index.ts, overrides.css, and the full upstream
MIT license. Root also retains build, render, browser and review evidence in
`docs/dev-log/evidence/julia-r-parity/documenter-anchor-20260831/`.
Protected tutorial and Gaussian source files were not changed.

## 5. Checks Run

Fresh build: 52 pages and 134 executable examples, 157.07 seconds. Fresh HTML
render: 9.57 seconds. All source and emitted-input hashes remain unchanged.
Generated style.css and docstrings.css exactly match resolved upstream files.
Root inspected four screenshots: desktop light, phone light/dark, and another
page's h2 anchor. Phone width is 390 pixels with no horizontal page overflow.
The formerly hidden heading now begins at 72.06 pixels on phones and 134.06 on
desktop; the unrelated h2 begins at 72.21 pixels on the phone.

## 6. Tests of the Tests

Retained pre-change screenshots and geometry show the original heading at y=0.06,
under the navigation bar. Fresh post-change captures show clearance. The raw
static audit retains exactly the same 106 deployment metadata failures as before;
no shim or suppression was used to obtain a green result.

## 7a. Issue Ledger

Programme #563 and global G6 remain open. This resolves the measured anchor P2
locally; it does not finish the site or authorize deployment.

## 8. Consistency Audit

The general selector covers all heading levels without changing page content.
The source override omits style.css and docstrings.css deliberately so the
resolved dependency continues supplying them. The full MIT notice is retained.

## 9. What Did Not Go Smoothly

Review caught an unsafe initial proposal that would replace bundled styles.
A second review found a smaller theme-entry override that preserves them.
The raw site still lacks deployment-generated siteinfo.js and versions.js.

## 10. Known Residuals

All-page visual/accessibility validation, external links, live deployment and
other programme documentation obligations remain open. This is not a global G6
pass. The theme entry must be reconciled when DocumenterVitepress is upgraded.

## 11. Team Learning

The child used explicit Terra/medium routing for source preparation; root
independently checked emitted defaults and actual browser output. Actual active
agent-hours are not instrumented. No Codex memory edit, package installation,
remote compute, or publication occurred.

Golden Set: the retained failing fragment screenshot and geometry, fresh cross-page responsive captures, and byte-identical upstream styles.

Memory receipt: no Codex memory files changed; durable receipts are retained in the repository.

## 12. Cross-Product Coverage

The repair covers the Julia documentation theme. It does NOT cover changes to drmTMB's
site, inference, parity, performance, or worktree recoverability. Browser viewport
was reset, the owned tab closed, and temporary preview server 37053 stopped.
