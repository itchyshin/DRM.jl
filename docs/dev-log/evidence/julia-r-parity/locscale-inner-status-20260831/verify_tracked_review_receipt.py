# Mechanical freshness check only; mathematical review is retained separately.
from pathlib import Path
import hashlib,sys
root=Path(__file__).resolve().parents[5]
expected={'src/locscale_inner.jl': '7f9571e775cef5cced81ab124a77f284225b85f57a4a054e565b36ddfe04fae0', 'test/test_locscale_inner_status.jl': '59fb2c4581f3097a99aa47ef757e5ccc8a81de241b7bbeb97cf461740ccf8625', 'docs/dev-log/evidence/julia-r-parity/locscale-inner-status-20260831/rose-tracked-arithmetic-review.md': '0729a0b510cee9690adde65bb109753cdb2d6738c4bd420865f3131b25f990cd'}
if "--negative-control" in sys.argv:
    expected["src/locscale_inner.jl"]="0"*64
for relative,want in expected.items():
    got=hashlib.sha256((root/relative).read_bytes()).hexdigest()
    if got!=want:
        raise SystemExit("REVIEW_STALE: "+relative)
print("TRACKED_REVIEW_RECEIPT_CURRENT")
