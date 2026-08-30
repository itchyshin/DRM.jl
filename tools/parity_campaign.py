#!/usr/bin/env python3
"""Freeze and verify the native drmTMB capability denominator.

This tool deliberately separates a complete structural inventory from numerical
parity evidence.  ``verify-manifest`` says only that the pinned R surface was
copied exactly; ``verify-parity`` is fail-closed until every required direct and
bridge observation has a receipt.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable


LEDGER_PATH = Path("docs/dev-log/dashboard/capability-ledger/cells.tsv")
NAMESPACE_PATH = Path("NAMESPACE")
SOURCE_FILES = (NAMESPACE_PATH, LEDGER_PATH, Path("R/family.R"), Path("R/drmTMB.R"))
EVIDENCE_STATUSES = frozenset({"MISSING", "PENDING", "PASS", "STALE", "SKIPPED"})
RECEIPT_KIND = "parity-observation-v1"
MODEL_OUTPUTS = (
    "fit", "log_likelihood", "coefficients", "vcov", "fitted", "predict",
    "residuals", "summary",
)
OPERATION_OUTPUTS = ("call_return", "error_contract", "result_shape")
REFUSAL_OUTPUTS = ("error_refusal",)
DRM_REPO = Path(__file__).resolve().parents[1]
SUPPLEMENTAL_DEFINITIONS = (
    (
        "supplemental:lss-family-dispatch",
        "Univariate location-scale-shape family dispatch",
        Path("R/drmTMB.R"),
        'student = drm_build_student_ls_spec',
        "Source admission only; parameterisation, normalization, and estimand parity remain unresolved.",
    ),
    (
        "supplemental:biv_student-fixed-only",
        "Bivariate Student-t fixed-effect route",
        Path("R/drmTMB.R"),
        'biv_student = drm_build_biv_student_spec',
        "Fixed-effect-only R route; the R source explicitly defers the Julia route.",
    ),
    (
        "supplemental:biv_lognormal-fixed-only",
        "Bivariate lognormal fixed-effect route",
        Path("R/drmTMB.R"),
        'biv_lognormal = drm_build_biv_lognormal_spec',
        "Fixed-effect-only R route; no Julia parity evidence is implied.",
    ),
)


class ManifestError(RuntimeError):
    """A frozen structural or evidence contract is malformed or has drifted."""


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git_rev_parse(repo: Path, rev: str) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(repo), "rev-parse", rev], text=True, stderr=subprocess.PIPE
        ).strip()
    except subprocess.CalledProcessError as error:
        raise ManifestError(f"cannot resolve git revision {rev!r} in {repo}") from error


def git_blob_bytes(repo: Path, revision: str, relative: Path) -> bytes:
    try:
        return subprocess.check_output(
            ["git", "-C", str(repo), "show", f"{revision}:{relative}"], stderr=subprocess.PIPE
        )
    except subprocess.CalledProcessError as error:
        raise ManifestError(f"pinned git source lacks {relative}") from error


def source_file_hash(repo: Path, revision: str, relative: Path) -> str:
    path = require_file(repo, relative)
    frozen = git_blob_bytes(repo, revision, relative)
    if path.read_bytes() != frozen:
        raise ManifestError(f"working source differs from pinned git blob for {relative}")
    return hashlib.sha256(frozen).hexdigest()


def require_file(repo: Path, relative: Path) -> Path:
    path = repo / relative
    if not path.is_file():
        raise ManifestError(f"required pinned source file is absent: {relative}")
    return path


def read_ledger(repo: Path) -> tuple[list[str], list[dict[str, str]]]:
    path = require_file(repo, LEDGER_PATH)
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if not reader.fieldnames:
            raise ManifestError("capability ledger has no header")
        required = {"cell_id", "capability_status", "claim_boundary"}
        missing = required - set(reader.fieldnames)
        if missing:
            raise ManifestError(f"capability ledger misses required columns: {sorted(missing)}")
        rows = list(reader)
    ids = [row["cell_id"] for row in rows]
    if any(not cell_id for cell_id in ids) or len(ids) != len(set(ids)):
        raise ManifestError("capability ledger must have one nonempty row per cell_id")
    return list(reader.fieldnames), rows


def parse_namespace(repo: Path) -> tuple[list[str], list[dict[str, str]]]:
    path = require_file(repo, NAMESPACE_PATH)
    exports: list[str] = []
    s3_operations: list[dict[str, str]] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("export(") and line.endswith(")"):
            exports.append(line[7:-1])
        elif line.startswith("S3method(") and line.endswith(")"):
            parts = [part.strip() for part in line[9:-1].split(",")]
            if len(parts) == 2 and all(parts):
                s3_operations.append({"generic": parts[0], "class": parts[1]})
    if len(exports) != len(set(exports)):
        raise ManifestError("NAMESPACE has duplicate export entries")
    operation_keys = [(item["generic"], item["class"]) for item in s3_operations]
    if len(operation_keys) != len(set(operation_keys)):
        raise ManifestError("NAMESPACE has duplicate S3method entries")
    return exports, s3_operations


def pending_contract(outputs: Iterable[str]) -> dict[str, Any]:
    return {
        "direct_reference_fixture": {
            "status": "MISSING",
            "reason": "No retained Julia direct-reference observation has been admitted.",
        },
        "bridge_reference_fixture": {
            "status": "MISSING",
            "reason": "No retained engine = julia bridge observation has been admitted.",
        },
        "required_outputs": [
            {
                "name": output,
                "direct_status": "MISSING",
                "bridge_status": "MISSING",
            }
            for output in outputs
        ],
    }


def expected_native_outputs(row: dict[str, str]) -> tuple[str, ...]:
    return MODEL_OUTPUTS if row["capability_status"] == "implemented" else REFUSAL_OUTPUTS


def line_provenance(repo: Path, relative: Path, needle: str) -> dict[str, str] | None:
    path = repo / relative
    if not path.is_file():
        return None
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if needle in line:
            return {"path": str(relative), "line": str(number), "sha256": sha256(path)}
    return None


def supplemental_admissions(repo: Path) -> list[dict[str, Any]]:
    """Add only individually auditable native routes outside the cell ledger."""
    admissions = []
    for admission_id, title, relative, needle, boundary in SUPPLEMENTAL_DEFINITIONS:
        provenance = line_provenance(repo, relative, needle)
        if provenance is not None:
            admissions.append({
                "id": admission_id,
                "title": title,
                "admission_basis": "pinned native R code admission audit",
                "source_provenance": [provenance],
                "claim_boundary": boundary,
                "parity_contract": pending_contract(MODEL_OUTPUTS),
            })
    return admissions


def build_manifest(repo: Path, ref: str) -> dict[str, Any]:
    repo = repo.resolve()
    expected_sha = git_rev_parse(repo, ref)
    head_sha = git_rev_parse(repo, "HEAD")
    if expected_sha != head_sha:
        raise ManifestError(
            f"pinned checkout drift: --ref resolves to {expected_sha}, but HEAD is {head_sha}"
        )
    drm_git_sha = git_rev_parse(DRM_REPO, "HEAD")
    fieldnames, rows = read_ledger(repo)
    exports, s3_operations = parse_namespace(repo)
    files = {}
    for relative in SOURCE_FILES:
        path = repo / relative
        if path.is_file():
            files[str(relative)] = {
                "path": str(relative),
                "sha256": source_file_hash(repo, expected_sha, relative),
            }
    native_rows = [
        {
            "id": row["cell_id"],
            "source": row,
            "parity_contract": pending_contract(expected_native_outputs(row)),
        }
        for row in rows
    ]
    implemented_axis_counts = Counter(
        row["axis"] for row in rows if row["capability_status"] == "implemented"
    )
    return {
        "schema_version": 1,
        "manifest_kind": "native-r-capability-structural-denominator",
        "source": {
            "drmtmb_ref": ref,
            "git_sha": head_sha,
            "drm_git_sha": drm_git_sha,
            "files": files,
        },
        "native_ledger": {
            "path": str(LEDGER_PATH), "fieldnames": fieldnames, "row_count": len(rows),
            "status_counts": dict(sorted(Counter(row["capability_status"] for row in rows).items())),
            "axis_counts": dict(sorted(Counter(row["axis"] for row in rows).items())),
            "implemented_axis_counts": dict(sorted(implemented_axis_counts.items())),
        },
        "native_rows": native_rows,
        "public_interface": {
            "exports": [{"name": name, "parity_contract": pending_contract(OPERATION_OUTPUTS)} for name in exports],
            "s3_operations": [
                {**operation, "parity_contract": pending_contract(OPERATION_OUTPUTS)}
                for operation in s3_operations
            ],
        },
        "supplemental_admissions": supplemental_admissions(repo),
        "unresolved_contracts": [
            {
                "id": "normalization",
                "status": "UNRESOLVED",
                "boundary": "Match normalizations route by route; this is not a blanket Gaussian-REML equivalence claim.",
            },
            {
                "id": "estimand",
                "status": "UNRESOLVED",
                "boundary": "Freeze each direct and bridge estimand before interpreting a numerical comparison.",
            },
        ],
        "structural_coverage_note": (
            "Structural coverage is an R-side denominator only. MISSING evidence is intentional and never a numerical parity pass."
        ),
    }


def write_markdown(manifest: dict[str, Any], output: Path) -> None:
    source = manifest["source"]
    ledger = manifest["native_ledger"]
    status_counts = ledger["status_counts"]
    lines = [
        "# Native R capability manifest",
        "",
        "This is a structural denominator, not functional Julia parity evidence.",
        "",
        f"- Pinned drmTMB Git SHA: `{source['git_sha']}`",
        f"- Native ledger rows: {ledger['row_count']}",
        f"- Exported functions: {len(manifest['public_interface']['exports'])}",
        f"- S3 operations: {len(manifest['public_interface']['s3_operations'])}",
        f"- Supplemental source-audited admissions: {len(manifest['supplemental_admissions'])}",
        "",
        "| Native capability status | Rows |",
        "| --- | ---: |",
    ]
    lines.extend(f"| {status} | {count} |" for status, count in status_counts.items())
    lines.extend(["", "| Implemented axis | Rows |", "| --- | ---: |"])
    lines.extend(
        f"| {axis} | {count} |"
        for axis, count in ledger["implemented_axis_counts"].items()
    )
    lines.extend([
        "",
        "All direct-reference fixtures, bridge fixtures, and required outputs are initialized as `MISSING`.",
        "`MANIFEST_STRUCTURE_PASS` validates source pins, exact rows, namespace coverage, contract shape, and any declared receipt bytes.",
        "A `PASS` receipt must bind actual JSON bytes to source IDs, cell, route, output and declared passed assertions. The checker does not recompute numerical comparisons or prove loaded binary identity; no overall parity PASS is possible in this scaffold.",
        "`verify-parity` remains fail-closed while observations are missing, skipped, stale, or pending; its present scaffold also requires an evidence review before reporting parity.",
        "",
        "The LSS, bivariate Student-t, and bivariate lognormal supplemental entries are source admissions only; normalization and estimand contracts remain unresolved.",
    ])
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ManifestError(f"cannot read manifest {path}: {error}") from error
    if not isinstance(payload, dict):
        raise ManifestError("manifest root must be an object")
    return payload


def validate_status(value: Any, context: str) -> None:
    if value not in EVIDENCE_STATUSES:
        raise ManifestError(f"{context} has invalid evidence status {value!r}")


def validate_receipt(receipt: Any, context: str, source: dict[str, Any],
                     manifest_dir: Path, cell_id: str, route: str, output: str) -> None:
    if not isinstance(receipt, dict):
        raise ManifestError(f"{context} PASS lacks a structured receipt")
    required = {"kind", "path", "sha256", "source_git_sha", "drm_git_sha"}
    if required - set(receipt):
        raise ManifestError(f"{context} PASS receipt misses {sorted(required - set(receipt))}")
    if receipt["kind"] != RECEIPT_KIND:
        raise ManifestError(f"{context} PASS receipt is not a {RECEIPT_KIND} observation")
    if not isinstance(receipt["path"], str) or not receipt["path"]:
        raise ManifestError(f"{context} PASS receipt has no artifact path")
    if not isinstance(receipt["sha256"], str) or not re.fullmatch(r"[0-9a-f]{64}", receipt["sha256"]):
        raise ManifestError(f"{context} PASS receipt has no artifact SHA-256")
    if receipt["source_git_sha"] != source["git_sha"] or receipt["drm_git_sha"] != source["drm_git_sha"]:
        raise ManifestError(f"{context} PASS receipt does not match the pinned build")
    receipt_path = (manifest_dir / receipt["path"]).resolve()
    if manifest_dir.resolve() not in receipt_path.parents or not receipt_path.is_file():
        raise ManifestError(f"{context} PASS receipt artifact is absent or outside the manifest directory")
    if sha256(receipt_path) != receipt["sha256"]:
        raise ManifestError(f"{context} PASS receipt artifact hash does not match")
    try:
        payload = json.loads(receipt_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ManifestError(f"{context} PASS receipt artifact is not valid JSON") from error
    if not isinstance(payload, dict):
        raise ManifestError(f"{context} PASS receipt artifact must be an object")
    required_payload = {
        "kind": RECEIPT_KIND,
        "drmtmb_git_sha": source["git_sha"],
        "drm_git_sha": source["drm_git_sha"],
        "cell_id": cell_id,
        "route": route,
        "output": output,
    }
    if any(payload.get(key) != value for key, value in required_payload.items()):
        raise ManifestError(f"{context} PASS receipt artifact does not match build, route, or output")
    assertions = payload.get("numeric_assertions")
    if not isinstance(assertions, list) or not assertions:
        raise ManifestError(f"{context} PASS receipt has no numeric assertions")
    for assertion in assertions:
        if (not isinstance(assertion, dict) or not assertion.get("name") or
                assertion.get("status") != "PASS" or "actual" not in assertion or
                "expected" not in assertion or "tolerance" not in assertion):
            raise ManifestError(f"{context} PASS receipt has an unpassed numeric assertion")


def validate_contract(contract: Any, context: str, expected_outputs: tuple[str, ...],
                      source: dict[str, Any], manifest_dir: Path, cell_id: str) -> list[str]:
    if not isinstance(contract, dict):
        raise ManifestError(f"{context} is missing parity_contract")
    errors: list[str] = []
    for fixture in ("direct_reference_fixture", "bridge_reference_fixture"):
        item = contract.get(fixture)
        if not isinstance(item, dict):
            raise ManifestError(f"{context} omits {fixture}")
        validate_status(item.get("status"), f"{context} {fixture}")
        if item["status"] == "PASS":
            validate_receipt(item.get("receipt"), f"{context} {fixture}", source,
                             manifest_dir, cell_id, fixture.split("_")[0], fixture)
        if item["status"] != "PASS":
            errors.append(f"{context} {fixture}={item['status']}")
    outputs = contract.get("required_outputs")
    if not isinstance(outputs, list) or not outputs:
        raise ManifestError(f"{context} omits nonempty required_outputs")
    names = []
    for output in outputs:
        if not isinstance(output, dict) or not output.get("name"):
            raise ManifestError(f"{context} has malformed required output")
        names.append(output["name"])
        for route in ("direct_status", "bridge_status"):
            validate_status(output.get(route), f"{context} output {output['name']} {route}")
            if output[route] == "PASS":
                validate_receipt(output.get(route.replace("_status", "_receipt")),
                                 f"{context} output {output['name']} {route}", source,
                                 manifest_dir, cell_id, route.removesuffix("_status"), output["name"])
            if output[route] != "PASS":
                errors.append(f"{context} output {output['name']} {route}={output[route]}")
    if len(names) != len(set(names)):
        raise ManifestError(f"{context} has duplicate required output names")
    if tuple(names) != expected_outputs:
        raise ManifestError(f"{context} required_outputs differs from its native contract")
    return errors


def verify_manifest(manifest: dict[str, Any], repo: Path, manifest_path: Path) -> None:
    if manifest.get("schema_version") != 1:
        raise ManifestError("unsupported or missing schema_version")
    source = manifest.get("source")
    if not isinstance(source, dict):
        raise ManifestError("manifest omits source pin")
    git_sha = source.get("git_sha")
    ref = source.get("drmtmb_ref")
    drm_git_sha = source.get("drm_git_sha")
    if not isinstance(git_sha, str) or not isinstance(ref, str) or not isinstance(drm_git_sha, str):
        raise ManifestError("manifest source pin lacks git_sha, drm_git_sha, or drmtmb_ref")
    if git_rev_parse(repo, "HEAD") != git_sha or git_rev_parse(repo, ref) != git_sha:
        raise ManifestError("drmTMB git pin no longer matches the manifest")
    files = source.get("files")
    if not isinstance(files, dict):
        raise ManifestError("manifest source pin omits file hashes")
    if set(files) != {str(p) for p in SOURCE_FILES}:
        raise ManifestError("manifest source-file set differs from the frozen source contract")
    for relative in (str(p) for p in SOURCE_FILES):
        item = files.get(relative)
        if not isinstance(item, dict) or item.get("path") != relative or not item.get("sha256"):
            raise ManifestError(f"manifest omits required hash for {relative}")
    for relative, item in files.items():
        if not isinstance(item, dict) or item.get("path") != relative:
            raise ManifestError(f"malformed source file entry {relative}")
        if source_file_hash(repo, git_sha, Path(relative)) != item.get("sha256"):
            raise ManifestError(f"source file hash drift for {relative}")

    fieldnames, source_rows = read_ledger(repo)
    ledger = manifest.get("native_ledger")
    if not isinstance(ledger, dict):
        raise ManifestError("manifest omits native_ledger")
    if ledger.get("fieldnames") != fieldnames or ledger.get("row_count") != len(source_rows):
        raise ManifestError("native ledger schema or row count drift")
    expected_counts = dict(sorted(Counter(row["capability_status"] for row in source_rows).items()))
    if ledger.get("status_counts") != expected_counts:
        raise ManifestError("native ledger status counts drift")
    expected_axis_counts = dict(sorted(Counter(row["axis"] for row in source_rows).items()))
    expected_implemented_axis_counts = dict(sorted(Counter(
        row["axis"] for row in source_rows if row["capability_status"] == "implemented"
    ).items()))
    if ledger.get("axis_counts") != expected_axis_counts:
        raise ManifestError("native ledger axis counts drift")
    if ledger.get("implemented_axis_counts") != expected_implemented_axis_counts:
        raise ManifestError("implemented native ledger axis counts drift")
    native_rows = manifest.get("native_rows")
    if not isinstance(native_rows, list) or len(native_rows) != len(source_rows):
        raise ManifestError("manifest native rows do not exactly cover the ledger")
    native_ids = [entry.get("id") if isinstance(entry, dict) else None for entry in native_rows]
    if len(native_ids) != len(set(native_ids)):
        raise ManifestError("manifest has duplicate native cell IDs")
    for manifest_row, source_row in zip(native_rows, source_rows):
        if not isinstance(manifest_row, dict) or manifest_row.get("id") != source_row["cell_id"]:
            raise ManifestError("manifest native row order or cell ID differs from source ledger")
        if manifest_row.get("source") != source_row:
            raise ManifestError(f"native source fields drift for {source_row['cell_id']}")
        validate_contract(manifest_row.get("parity_contract"), f"native row {source_row['cell_id']}",
                          expected_native_outputs(source_row), source, manifest_path.parent,
                          source_row["cell_id"])

    exports, s3_operations = parse_namespace(repo)
    public = manifest.get("public_interface")
    if not isinstance(public, dict):
        raise ManifestError("manifest omits public interface")
    actual_exports = public.get("exports")
    if not isinstance(actual_exports, list) or [item.get("name") for item in actual_exports if isinstance(item, dict)] != exports:
        raise ManifestError("manifest export coverage differs from NAMESPACE")
    for item in actual_exports:
        validate_contract(item.get("parity_contract"), f"export {item['name']}", OPERATION_OUTPUTS,
                          source, manifest_path.parent, f"export:{item['name']}")
    actual_s3 = public.get("s3_operations")
    expected_s3_keys = [(item["generic"], item["class"]) for item in s3_operations]
    actual_s3_keys = [
        (item.get("generic"), item.get("class")) for item in actual_s3
    ] if isinstance(actual_s3, list) else []
    if actual_s3_keys != expected_s3_keys:
        raise ManifestError("manifest S3 operation coverage differs from NAMESPACE")
    for item in actual_s3:
        validate_contract(item.get("parity_contract"), f"S3 {item['generic']}.{item['class']}",
                          OPERATION_OUTPUTS, source, manifest_path.parent,
                          f"s3:{item['generic']}.{item['class']}")

    supplemental = manifest.get("supplemental_admissions")
    if not isinstance(supplemental, list):
        raise ManifestError("manifest omits supplemental_admissions")
    supplement_ids = [item.get("id") if isinstance(item, dict) else None for item in supplemental]
    if len(supplement_ids) != len(set(supplement_ids)):
        raise ManifestError("manifest has duplicate supplemental admission IDs")
    expected_supplements = supplemental_admissions(repo)
    if supplement_ids != [item["id"] for item in expected_supplements]:
        raise ManifestError("manifest supplemental admissions differ from the pinned source audit")
    for item, expected in zip(supplemental, expected_supplements):
        if not isinstance(item, dict) or not item.get("claim_boundary") or not item.get("source_provenance"):
            raise ManifestError("supplemental admission lacks boundary or source provenance")
        for field in ("title", "admission_basis", "source_provenance", "claim_boundary"):
            if item.get(field) != expected[field]:
                raise ManifestError(f"supplemental admission {item.get('id')} differs from the pinned source audit")
        validate_contract(item.get("parity_contract"), f"supplemental {item['id']}", MODEL_OUTPUTS,
                          source, manifest_path.parent, item["id"])

    unresolved = manifest.get("unresolved_contracts")
    if not isinstance(unresolved, list) or {item.get("id") for item in unresolved if isinstance(item, dict)} != {"normalization", "estimand"}:
        raise ManifestError("normalization and estimand contracts must be explicit")
    if any(item.get("status") not in {"UNRESOLVED", "PASS"} or not item.get("boundary") for item in unresolved):
        raise ManifestError("normalization and estimand contracts must be explicit")


def parity_gaps(manifest: dict[str, Any]) -> list[str]:
    gaps: list[str] = []
    def collect(contract: dict[str, Any], context: str) -> None:
        for fixture in ("direct_reference_fixture", "bridge_reference_fixture"):
            if contract[fixture]["status"] != "PASS":
                gaps.append(f"{context} {fixture}={contract[fixture]['status']}")
        for output in contract["required_outputs"]:
            for route in ("direct_status", "bridge_status"):
                if output[route] != "PASS":
                    gaps.append(f"{context} output {output['name']} {route}={output[route]}")

    for row in manifest["native_rows"]:
        collect(row["parity_contract"], f"native row {row['id']}")
    public = manifest.get("public_interface", {})
    for item in public["exports"] + public["s3_operations"]:
        collect(item["parity_contract"], "public operation")
    for item in manifest["supplemental_admissions"]:
        collect(item["parity_contract"], f"supplemental {item['id']}")
    for item in manifest["unresolved_contracts"]:
        if item["status"] != "PASS":
            gaps.append(f"unresolved contract {item.get('id')}={item.get('status')}")
    return gaps


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subcommands = parser.add_subparsers(dest="command", required=True)
    build = subcommands.add_parser("build-manifest")
    build.add_argument("--drmtmb", type=Path, required=True)
    build.add_argument("--ref", required=True)
    build.add_argument("--output", type=Path, required=True)
    verify = subcommands.add_parser("verify-manifest")
    verify.add_argument("--manifest", type=Path, required=True)
    verify.add_argument("--drmtmb", type=Path, required=True)
    parity = subcommands.add_parser("verify-parity")
    parity.add_argument("--manifest", type=Path, required=True)
    parity.add_argument("--drmtmb", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        if args.command == "build-manifest":
            manifest = build_manifest(args.drmtmb, args.ref)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            write_markdown(manifest, args.output.with_suffix(".md"))
            print(f"MANIFEST_BUILT rows={manifest['native_ledger']['row_count']} output={args.output}")
        elif args.command == "verify-manifest":
            verify_manifest(load_manifest(args.manifest), args.drmtmb.resolve(), args.manifest.resolve())
            print("MANIFEST_STRUCTURE_PASS")
        else:
            manifest = load_manifest(args.manifest)
            verify_manifest(manifest, args.drmtmb.resolve(), args.manifest.resolve())
            gaps = parity_gaps(manifest)
            if gaps:
                print(f"PARITY_EVIDENCE_INCOMPLETE gaps={len(gaps)}")
                for gap in gaps[:20]:
                    print(f"- {gap}")
                return 1
            print("PARITY_EVIDENCE_REVIEW_REQUIRED")
            return 1
    except ManifestError as error:
        print(f"MANIFEST_STRUCTURE_FAIL: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
