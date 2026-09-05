# Pat visual review — build 006 limitation record

## Intended scope

One newly rendered page only:
`/reference/engine-internals.html#location-scale-inner-mode-acceptance` from
`docs/build/integration-inner-006/1`, at desktop light and phone 390 x 844 in
light and dark appearance. This is not an all-site, accessibility, deployment,
or G6 verdict.

## Provenance checked

`../receipt.json` records the strict production-navigation source build at
`c4e44a3e5c2d972be020a632b9c2b4f254c2a03b`, exit 0, 52 pages, 134 example
blocks, in 147.180726 seconds. The retained HTML page contains the new
"Location-scale inner-mode acceptance" text, the explicit sentence
"This helper is internal and has no stability guarantee", and the rendered
`DRM._ls_inner_estimated_change` docstring.

Static inspection confirms that the emitted page still references `/versions.js`
and `/siteinfo.js`, while neither exists in the raw build root. This is the
known raw-metadata boundary; it was not masked or treated as a visual pass.

## Visual result

**NOT RUN — browser unavailable.** The normal in-app browser route returned
"No browser is available" before a tab could be created. Consequently there
are no fresh screenshots, no DOM width readings, and no desktop/phone or
light/dark visual verdict in this record. I did not reuse prior-build images or
fabricate browser results.

## Required resumption

With a fresh browser binding: set 390 x 844 **before** direct navigation for
each phone check, wait for the layout to settle, inspect the changed section
and helper entry in light and dark appearance, record main/content widths and
overflow, then reset the viewport and close the audit tab. Retain metadata 404s
as a separate raw-build limitation.
