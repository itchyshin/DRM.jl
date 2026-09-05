# Reader theme preview repairs

## 1. Goal

Inspect the actual two-page Vitepress output and repair visible defects without
claiming whole-site completion (DRM.jl#563, S13).

## 2. Implemented

Removed the duplicated URL scheme from the writer's repository setting. Rendered
the getting-started summary as text/plain so vertical bars in its column labels
cannot corrupt the generated Markdown table.

## 3a. Decisions and Rejected Alternatives

Used cached Vitepress 1.6.4 and Node 20.17.0 without installing dependencies.
The two-page preview alone ignores links to omitted pages. The production site's
link settings remain unchanged. Kept unavailable sigma z/p values visible.

## 4. Files Touched

docs/make.jl, tools/parity_docs_pilot.jl, docs/src/getting-started.md,
documentation inventory and preview receipts, this report and checkpoint.
No Julia src file changed; the separate red allocation tests are excluded.

## 5. Checks Run

Unlazy v6 actually reran both bound reader gates: eight inventory tests and the
two-page writer executing nine examples. The cached theme build passed in under
five seconds. Desktop light and dark viewports and the generated edit URL were
inspected in the browser. Exact source and HTML hashes are in
docs/dev-log/evidence/julia-r-parity/docs-theme-preview.json.

## 6. Tests of the Tests

The subset initially failed on ten links to omitted pages; that failure is
retained separately from the preview-only override. A ledger syntax error is
retained alongside the corrected, actually executed v6 result. Static inventory
tests deliberately damage fixtures. Full-page screenshot stitching was rejected
as layout evidence; a stable dark viewport is retained instead.

## 7a. Issue Ledger

Issue563 and G0–G8 remain open. This is a bounded reader repair, not whole G6.

## 8. Consistency Audit

The prior reader report describes its earlier Markdown-only checkpoint. This
report extends that evidence to two desktop theme pages. Other branch navigation
diffs were inspected; they do not contain this URL repair and are left untouched.

Rose independently approved the bounded patch, verified source/HTML/log hashes,
and inspected the dark viewport. Her two evidence wording/provenance nits are
corrected here. Long code output remains horizontally scrollable.

## 9. What Did Not Go Smoothly

A successful Markdown writer did not reveal the broken summary table. Browser
inspection did. An attempted Vitepress help command ran against the repository
root and failed on development Markdown; it is not a valid site-build result.

## 10. Known Residuals

Mobile, all remaining pages, full-site links, fresh setup and deployed content
remain unverified. No remote compute or publication occurred. Protected S5
source changes remain blocked pending the explicit approval already requested.

## 11. Team Learning

Memory receipt: operating guidance and the current repository informed scope;
no Codex memory was written. Golden Set: not run for this bounded docs repair.
Inspect actual theme output, not only intermediate Markdown.

## 12. Cross-Product Coverage

This does NOT cover numerical parity, inference validity, performance, whole-site
acceptance, or the unfinished R zero_one_beta adapter. Those retain separate gates.
