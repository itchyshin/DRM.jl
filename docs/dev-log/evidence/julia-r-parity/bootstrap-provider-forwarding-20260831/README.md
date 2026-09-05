# Bootstrap provider-forwarding evidence

Retained red receipts cover the original missing structured payload/provider
and the review-found omission where the generated fit received K/A/coords but
both bootstrap calls dropped them. Final pure-R routing has 48 expectations.

The final actual R receipt is `actual-r-relmat-bootstrap-profile-final.log`.
It source-loads the paired integration checkouts, pins BLAS to one thread, and
compares public R profile/bootstrap with direct `DRM.drm_bridge_inference` on
the same retained K payload. Differences are zero; bootstrap uses B=2 with 2/2
successful refits. B=2 is integration evidence, not coverage or performance.
Animal and converted-spatial R paths have routing/mocked evidence only. Direct
Julia additionally exercises raw coords and animal A.

`acceptance-ledger.md` was copied after the final automated runs; the separate
review receipt is added after independent review. Run `python3 verify.py` for
artifact integrity. Drivers contain historical absolute paths by design.
