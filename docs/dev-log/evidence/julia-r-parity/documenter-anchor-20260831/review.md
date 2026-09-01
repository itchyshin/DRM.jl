# General section-anchor clearance

Three authored theme files preserve DocumenterVitepress0.3.4's default entry
with only provenance and one local override import. The default style.css and
docstrings.css are absent from the source override directory and their emitted
copies match the resolved upstream bytes. Full MIT notice is retained.

The first proposed one-rule style.css would have replaced8439bytes of default
styles. Root questioned it before any edit; it was rejected. The final small
index override keeps both default styles, all components and imports.

Fresh52-page/134-example build passes157.07s; HTML passes9.57s. Source and emitted
inputs remained unchanged. Root inspected actual desktoplight, phonelight/dark,
and unrelated reference h2 screenshots. Previous broken heading top0.06px is
now72.06px onphone (390x844, pagewidth390) and134.06px ondesktop (1280wide).
Unrelated Inference h2 begins72.21px onphone; no pagewidehorizontaloverflow.
This fixes the measured P2 across the generalheadingselectors. It is not a
whole-site accessibility, all-pagevisual or deployment verdict.

The raw audit still reports106missingassets: siteinfo.js and versions.js on
53rawpages, exactly the prior deployment-metadata boundary. No new localpath,
fragment,alttext or sourcecoverage failure. No metadata shim or suppression.
Viewport reset, ownedbrowser tabclosed, temporaryserverPID37053stopped.
