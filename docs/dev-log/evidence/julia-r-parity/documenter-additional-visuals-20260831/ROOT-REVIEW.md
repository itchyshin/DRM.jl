# Root review — mobile verdict not accepted

The initial Pat receipt's "no new blocking layout finding" is **not accepted**
for the mobile captures pending reinspection. Preserve it as the original report.

Direct inspection of `07-location-scale-mobile-light.png` shows the article
squeezed into roughly70pixels at the right edge of a390pixel viewport, with
severe title wrapping and a large empty left area. The full-page capture `08`
also has repeated content and large blank regions. A document scroll-width
check alone did not detect this visible failure.

Pat is checking whether this reflects the site's CSS or browser capture/viewport
handling, using fresh filenames. No source fix or accepted mobile verdict yet.
The separate tutorial edit lease was rejected by auto-review because another
lane has work on that path. It was not retried; the tutorial remains untouched.

## Fresh recheck

Root reconnected the browser and tested the same retained build. Setting the
phone viewport before direct navigation produced a normal342pixel article at
x=24 in a390pixel viewport (`root-11`). Repeating desktop → dark → light → phone
produced a transient sidebar overlay in the immediate capture (`root-12`),
although DOM geometry already reported the normal342pixel width. A subsequent
settled capture was normal (`root-13`). One h1 was present.

The original captures remain invalid as passing evidence. A persistent article
width defect was not reproduced in this recheck; immediate resize capture is
unreliable. This does not certify all mobile pages or the current source build.
See `root-responsive-recheck.json` for exact measurements, hashes and cleanup.
