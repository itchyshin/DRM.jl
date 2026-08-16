# Parity ledger remeasure — 2026-08-16 (catch-up @ref docs)

Read-only. Command:

```bash
python3 tools/parity_ledger.py --drmtmb "/Users/z3437171/Dropbox/Github Local/drmTMB" --ref origin/main
```

```
drmTMB 0.7.0 @ origin/main (9e42d2c94)
  exports: 59   DRM.jl exports: 154

COUNTDOWN: 0 export gaps (18 raw, 18 accounted for) · 11 unsupported capability rows · 14 closed gates

CLOSURE: PASS — every one of 11 capability rows is supported or carries a written claim_boundary; all 14 closed gates carry evidence + review_due
```

`origin/main` at measure: `394b62d9` (merge of #424).

0 export gaps ≠ parity complete. The 11 unsupported capability rows remain
the next frontier; this slice does not open that campaign.
