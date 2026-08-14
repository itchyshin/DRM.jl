| slice | date | change | check | result |
|---|---|---|---|---|
| A0b closure audit | 2026-08-14 | `tools/parity_ledger.py` now audits the closure invariant (every row `supported` or carrying a written boundary) and exits non-zero on failure | `python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main` | **CLOSURE: PASS** — 11/11 capability rows bounded; 14/14 closed gates carry evidence + review_due; exit 0 |
