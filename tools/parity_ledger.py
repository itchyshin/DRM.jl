#!/usr/bin/env python3
"""Reconcile the DRM.jl public surface against drmTMB's, at a named git ref.

The catch-up campaign's countdown. Reads three drmTMB artifacts -- `NAMESPACE`,
`inst/extdata/julia-capabilities.tsv`, `inst/extdata/julia-gates.tsv` -- plus
DRM.jl's own export block, and reports what the R bridge admits versus what the
Julia engine can actually fit.

Always reads drmTMB through `git show <ref>:<path>` rather than the working
tree. A working checkout can sit hundreds of commits behind `origin/main`
(2026-08-14: it was 987 behind, and reading it produced a gap list that was
wrong in both directions).

    python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

# drmTMB R name -> DRM.jl symbol, where the twin exists under a different name.
ALIASES = {
    "nbinom2": "NegBinomial2",
    "truncated_nbinom2": "TruncatedNegBinomial2",
    "biv_gaussian": "cbind",           # bivariate is cbind()/mvbind() in DRM.jl
    "drmTMB": "drm",                   # the fitting verb
    "phylo_interaction": "fit_phylo_interaction",
}

# Exports with no meaningful Julia counterpart -- R-idiom helpers, not capability.
NOT_CAPABILITY = {"gr", "drm_control", "meta_known_V"}

# A4e. The raw "exports with no twin" count MIXES three different things, and
# reporting their sum as one countdown overstates the work: it counts a
# capability DRM.jl already has under another spelling, and work that correctly
# lives in R, as though both were missing engine features.
#
# Each name below therefore carries a WRITTEN REASON, and the countdown reports
# the classes separately. Adding a name here is a claim -- it must be true, and
# it must say why.
DELIBERATELY_NOT_PORTED = {
    # --- delivered, but spelled differently: a family plus a bivariate formula
    "biv_lognormal": "delivered as LogNormal() with a bivariate formula (A3a, parity-verified)",
    "biv_student": "delivered as Student() with a bivariate formula (A3b, parity-verified)",
    "biv_associate": "delivered as associate_pairs() -- the staged frozen-margin route (A3c)",
    # --- delivered through the BRIDGE PAYLOAD; the R function correctly stays in R.
    #     A2a established that these five collapse to ONE contract: per-dpar
    #     response-scale columns. They are R post-fit functions that CONSUME the
    #     Julia payload, not engine features DRM.jl is missing.
    "fitted_distribution": "R post-fit function fed by the drm_bridge dpars payload (A2a)",
    "qq_plot": "R post-fit function fed by the drm_bridge dpars payload (A2a)",
    "worm_plot": "R post-fit function fed by the drm_bridge dpars payload (A2a)",
    "centile_chart": "R post-fit function fed by the drm_bridge dpars payload (A2a)",
    "exceedance": "R post-fit function fed by the drm_bridge dpars payload (A2a)",
    # --- delivered as a field/accessor rather than an export
    "rho_latent": "delivered as fit.rho_latent, surfaced through mf_summary()",
    # --- R-side preparation that never reaches the engine (owner-confirmed 2026-08-15)
    "make_mesh": "R-side geospatial prep (sf, CRS validation) before any fit -- owner-confirmed",
    "spatial_coords": "R-side geospatial prep before any fit -- owner-confirmed",
    # --- parked behind an owner fence (#49 missing data)
    "categorical": "an imputation family (drm_impute_family), not a response family -- #49 PARKED",
    "mi": "missing-data surface -- #49 PARKED",
    "impute_model": "missing-data surface -- #49 PARKED",
    "imputed": "missing-data surface -- #49 PARKED",
    "miss_control": "missing-data surface -- #49 PARKED",
    # --- genuinely absent, and blocked for a stated structural reason (A4d)
    "corpair": "BLOCKED: StatsModels' @formula cannot express keyword args or string "
               "literals, so drmTMB's syntax is not representable; and the fitted route "
               "needs the labelled covariance-block grammar (1|p|id), absent in DRM.jl",
    "meta_vcov_bivariate": "BLOCKED: meta_V is diagonal-only and the bivariate route "
                           "ignores metav, so the output would have no consumer",
}


def git_show(repo: Path, ref: str, path: str) -> str:
    out = subprocess.run(
        ["git", "-C", str(repo), "show", f"{ref}:{path}"],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        sys.exit(f"cannot read {path} at {ref} in {repo}: {out.stderr.strip()}")
    return out.stdout


def norm(s: str) -> str:
    return re.sub(r"[_.]", "", s).lower()


def drmtmb_exports(repo: Path, ref: str) -> list[str]:
    ns = git_show(repo, ref, "NAMESPACE")
    return sorted(re.findall(r"^export\((.+?)\)", ns, re.M))


def drmjl_exports(root: Path) -> list[str]:
    src = (root / "src" / "DRM.jl").read_text()
    names: list[str] = []
    for block in re.findall(r"^export\s+(.+?)(?=\n\s*\n|\nexport|\Z)", src, re.M | re.S):
        block = re.sub(r"#.*", "", block)
        names += [n.strip() for n in block.split(",") if n.strip()]
    return sorted(set(names))


def tsv_rows(repo: Path, ref: str, path: str) -> list[dict]:
    text = git_show(repo, ref, path)
    lines = [l for l in text.splitlines() if l.strip()]
    header = lines[0].split("\t")
    return [dict(zip(header, l.split("\t"))) for l in lines[1:]]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--drmtmb", required=True, type=Path, help="path to the drmTMB repo")
    ap.add_argument("--ref", default="origin/main", help="git ref to read (default origin/main)")
    ap.add_argument("--root", default=Path(__file__).resolve().parents[1], type=Path)
    args = ap.parse_args()

    sha = subprocess.run(
        ["git", "-C", str(args.drmtmb), "rev-parse", args.ref],
        capture_output=True, text=True,
    ).stdout.strip()
    version = re.search(
        r"^Version:\s*(\S+)", git_show(args.drmtmb, args.ref, "DESCRIPTION"), re.M
    ).group(1)

    r_exports = drmtmb_exports(args.drmtmb, args.ref)
    j_exports = drmjl_exports(args.root)
    j_norm = {norm(x) for x in j_exports}

    def has_twin(name: str) -> bool:
        if norm(name) in j_norm:
            return True
        alias = ALIASES.get(name)
        return bool(alias and norm(alias) in j_norm)

    unmatched = [x for x in r_exports if not has_twin(x) and x not in NOT_CAPABILITY]
    # A4e: split the raw count into "actually owed" vs "accounted for in writing".
    missing = [x for x in unmatched if x not in DELIBERATELY_NOT_PORTED]
    accounted = [x for x in unmatched if x in DELIBERATELY_NOT_PORTED]

    caps = tsv_rows(args.drmtmb, args.ref, "inst/extdata/julia-capabilities.tsv")
    gates = tsv_rows(args.drmtmb, args.ref, "inst/extdata/julia-gates.tsv")

    print(f"drmTMB {version} @ {args.ref} ({sha[:9]})")
    print(f"  exports: {len(r_exports)}   DRM.jl exports: {len(j_exports)}")
    print()

    print(f"BRIDGE CAPABILITY ROWS ({len(caps)}) -- the campaign's countdown")
    by_claim: dict[str, list[str]] = {}
    for row in caps:
        by_claim.setdefault(row.get("claim_status", "?"), []).append(row["capability_id"])
    for claim, ids in sorted(by_claim.items()):
        print(f"  {claim:<14} {len(ids):>2}  {', '.join(ids)}")
    print()

    blocked = [g for g in gates if g.get("r_bridge_status") == "intentional_error"]
    print(f"GATES CLOSED BY INTENTIONAL ERROR ({len(blocked)})")
    for g in blocked:
        print(f"  {g['gate_id']:<34} {g.get('syntax','')[:70]}")
    print()

    print(f"ACCOUNTED FOR IN WRITING ({len(accounted)}) -- not owed, and why")
    for name in accounted:
        print(f"  {name:<22} {DELIBERATELY_NOT_PORTED[name]}")
    print()

    print(f"drmTMB EXPORTS WITH NO DRM.jl TWIN ({len(missing)}) -- genuinely owed")
    for name in missing:
        print(f"  {name}")
    print()
    print(f"COUNTDOWN: {len(missing)} export gaps ({len(unmatched)} raw, "
          f"{len(accounted)} accounted for) · "
          f"{sum(1 for c in caps if c.get('claim_status') != 'supported')} unsupported capability rows · "
          f"{len(blocked)} closed gates")

    # Closure invariant: every row is either `supported` (which requires a parity
    # fixture) or says IN WRITING why it is not. Asserting this by hand rots the
    # moment someone adds a row, so check it and fail loudly.
    print()
    unclosed: list[str] = []
    for row in caps:
        if row.get("claim_status") == "supported":
            continue                      # fixture evidence is audited separately
        if not row.get("claim_boundary", "").strip():
            unclosed.append(f"capability {row['capability_id']}: no claim_boundary")
    for g in blocked:
        if not g.get("evidence", "").strip():
            unclosed.append(f"gate {g['gate_id']}: no evidence")
        if not g.get("review_due", "").strip():
            unclosed.append(f"gate {g['gate_id']}: no review_due")

    if unclosed:
        print(f"CLOSURE: FAIL — {len(unclosed)} row(s) neither supported nor bounded")
        for u in unclosed:
            print(f"  {u}")
        return 1

    print(f"CLOSURE: PASS — every one of {len(caps)} capability rows is supported "
          f"or carries a written claim_boundary; all {len(blocked)} closed gates "
          f"carry evidence + review_due")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
