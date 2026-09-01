#!/usr/bin/env python3
"""Deliberately damaged receipts must fail, including under python -O."""
import copy,sys,tomllib
from pathlib import Path
from check_joint_imputation_receipt import check

def main():
    data, reference, receipt, root = map(Path,sys.argv[1:])
    good=tomllib.loads(receipt.read_text()); check(data,reference,good,root)
    changes={
        "source": lambda r: r.update(source_unchanged=False),
        "thread": lambda r: r.update(blas_threads=8),
        "case": lambda r: r["cases"].pop("bernoulli"),
        "mean": lambda r: r["cases"]["gaussian"]["mean"].__setitem__(0,999),
        "standard error": lambda r: r["cases"]["gaussian"]["std_error"].__setitem__(0,1),
        "se_available": lambda r: r["cases"]["gaussian"]["se_available"].__setitem__(0,True),
        "original_row": lambda r: r["cases"]["gaussian"]["original_row"].reverse(),
        "selected rows": lambda r: r["cases"]["gaussian"]["selected_model_row"].pop(),
        "uncertainty_status": lambda r: r["cases"]["gaussian"]["uncertainty_status"].__setitem__(0,"failed"),
        "se=false": lambda r: r["cases"]["gaussian"].update(no_se_all_missing=False),
        "spurious parameter": lambda r: r["cases"]["bernoulli"]["parameter_variance"].__setitem__(0,0.01),
        "analytic parameter": lambda r: r["cases"]["gaussian"]["parameter_variance"].__setitem__(r["cases"]["gaussian"]["selected_model_row"][0]-1,0.0),
        "supplied parameters": lambda r: r["cases"]["gaussian"]["theta"].__setitem__(0,999),
        "conditional variance": lambda r: r["cases"]["gaussian"]["conditional_variance"].pop(),
    }
    for label, mutate in changes.items():
        bad=copy.deepcopy(good); mutate(bad)
        try: check(data,reference,bad,root)
        except ValueError as exc:
            if label not in str(exc): raise RuntimeError(f"wrong failure for {label}: {exc}")
        else: raise RuntimeError("accepted damaged "+label)
    print(f"JOINT_IMPUTATION_NEGATIVES_PASS={len(changes)}")

if __name__ == "__main__": main()
