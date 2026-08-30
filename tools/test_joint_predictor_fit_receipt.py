#!/usr/bin/env python3
"""Damaged controls for the fit-receipt checker; works with python -O."""
import copy,sys,tomllib
from pathlib import Path
from check_joint_predictor_fit_receipt import check
def main():
    if len(sys.argv)!=4: raise SystemExit("usage: test_joint_predictor_fit_receipt.py REFERENCE RECEIPT JULIA_ROOT")
    rp,cp,root=map(Path,sys.argv[1:]); ref=tomllib.loads(rp.read_text()); ref["__path__"]=rp; good=tomllib.loads(cp.read_text()); check(ref,good,root); caught=0
    expected={"gradient":"nll/gradient", "gradient_length":"theta/gradient length", "snapshot":"snapshot", "status":"status differs", "nll":"independently recomputed LL", "hessian":"Hessian nonsymmetric", "row_loglik":"receipt row likelihood", "missing_row_loglik":"row_loglik", "mask":"observed masks", "native_theta":"receipt native theta", "fitted_theta":"independently recomputed LL", "hash":"source manifest", "case":"case denominator"}
    for item in expected:
        bad=copy.deepcopy(good); g=bad["cases"]["gaussian"]
        if item=="gradient": g["gradient"][0]=1e-3
        elif item=="gradient_length": g["gradient"].pop()
        elif item=="snapshot": g["snapshot_isolated"]=False
        elif item=="status": g["covariance_status"]="hessian_unavailable"
        elif item=="nll": g["nll"]+=1e-3
        elif item=="hessian": g["hessian"][0][1]+=1e-3
        elif item=="row_loglik": g["row_loglik"][0]+=1e-3
        elif item=="missing_row_loglik": del g["row_loglik"]
        elif item=="mask": g["x_observed"][0]=not g["x_observed"][0]
        elif item=="native_theta": g["native_theta"][0]+=1e-3
        elif item=="fitted_theta": g["theta"][0]+=1e-3
        elif item=="hash": bad["source_sha256"][next(iter(bad["source_sha256"]))]="0"*64
        else: del bad["cases"]["bernoulli"]
        try: check(ref,bad,root)
        except ValueError as err:
            if expected[item] not in str(err): raise RuntimeError("wrong failure for "+item+": "+str(err))
            caught+=1
        else: raise RuntimeError("accepted damaged "+item)
    print("JOINT_FIT_RECEIPT_NEGATIVES_PASS="+str(caught))
if __name__=="__main__": main()
