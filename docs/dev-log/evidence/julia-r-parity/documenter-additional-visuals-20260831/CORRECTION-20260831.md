# Correction — mobile-light visual verdict

This supersedes the mobile-light portion of `RECEIPT.md`.

## Image inspection

Direct inspection of the retained PNGs shows two incompatible results for the
location-scale tutorial at nominal 390 x 844 phone width:

- `06-location-scale-mobile-dark.png` is readable and uses the expected
  full-width single-column layout.
- `07-location-scale-mobile-light.png` is unusable: the content is constrained
  to a narrow strip at the right edge, the title wraps into fragments, and most
  of the viewport is blank.
- `08-location-scale-mobile-light-full.png` repeats the lower document content.
  That repetition is a screenshot-capture artifact, not evidence that the
  rendered HTML duplicates sections.
- `09-model-specification-mobile-light.png` is readable at the same nominal
  phone width.

The failed sequence for `07` was: desktop location-scale page -> appearance
toggle to light -> viewport changed to 390 x 844 -> immediate screenshot.
The dark location-scale and light model-specification captures used direct page
navigation after the phone viewport was set. The discrepancy could be a
browser-capture/reflow artifact or a genuine failure to reflow after an
appearance-plus-resize transition. The screenshots alone cannot distinguish
them.

## Correct verdict

**RED / unresolved P1 for mobile-light location-scale evidence.** The previous
claim of no blocking visual finding is withdrawn. Do not use `07` or `08` as a
passing visual record, and do not claim G6, fresh-candidate acceptance, or
all-page visual acceptance from this sample.

A clean recheck must use a fresh browser binding, set 390 x 844 before direct
navigation to `/tutorials/location-scale.html`, wait for layout settling, inspect
the rendered DOM boxes and a fresh screenshot in light appearance, then repeat
the desktop -> light-toggle -> phone-resize sequence. If only the latter fails,
retain it as a transition/capture defect with a minimal reproduction. If both
fail, it is a true mobile-light CSS defect.

## Recheck limitation

After the contradiction was raised, the in-app browser disconnected and could
not be reacquired (`No browser is available`). No source, build, or artifact was
modified to work around that limitation. The original PNGs are preserved.
