"""Contract tests for the fail-closed native-R parity manifest."""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import contextlib
import io
import json
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "parity_campaign.py"


class ManifestFixture(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.r_repo = self.root / "drmTMB"
        ledger = self.r_repo / "docs/dev-log/dashboard/capability-ledger/cells.tsv"
        ledger.parent.mkdir(parents=True)
        (self.r_repo / "NAMESPACE").write_text(
            "export(drmTMB)\nexport(biv_student)\n"
            "S3method(coef,drmTMB)\nS3method(predict,drmTMB)\n",
            encoding="utf-8",
        )
        r_source = self.r_repo / "R"
        r_source.mkdir()
        (r_source / "family.R").write_text("# Synthetic family fixture\n", encoding="utf-8")
        (r_source / "drmTMB.R").write_text(
            "student = drm_build_student_ls_spec\n"
            "biv_lognormal = drm_build_biv_lognormal_spec\n"
            "biv_student = drm_build_biv_student_spec\n",
            encoding="utf-8",
        )
        headers = [
            "cell_id", "source_order", "axis", "family_route",
            "capability_status", "work_status", "claim_boundary",
        ]
        with ledger.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=headers, delimiter="\t")
            writer.writeheader()
            writer.writerows([
                {
                    "cell_id": "mc-0001", "source_order": "1",
                    "axis": "model_surface", "family_route": "gaussian",
                    "capability_status": "implemented", "work_status": "verified",
                    "claim_boundary": "R implementation only",
                },
                {
                    "cell_id": "mc-0002", "source_order": "2",
                    "axis": "model_surface", "family_route": "student",
                    "capability_status": "rejected_by_design", "work_status": "deferred",
                    "claim_boundary": "Rejected R region",
                },
            ])
        subprocess.run(["git", "init", "-q", str(self.r_repo)], check=True)
        subprocess.run(["git", "-C", str(self.r_repo), "config", "user.email", "test@example.org"], check=True)
        subprocess.run(["git", "-C", str(self.r_repo), "config", "user.name", "Manifest test"], check=True)
        subprocess.run(["git", "-C", str(self.r_repo), "add", "."], check=True)
        subprocess.run(["git", "-C", str(self.r_repo), "commit", "-qm", "fixture"], check=True)
        self.ref = subprocess.check_output(
            ["git", "-C", str(self.r_repo), "rev-parse", "HEAD"], text=True
        ).strip()
        self.manifest = self.root / "capability-manifest.json"
        built = self.invoke("build-manifest", "--drmtmb", str(self.r_repo), "--ref", self.ref,
                            "--output", str(self.manifest))
        self.assertEqual(built.returncode, 0, built.stderr)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def invoke(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args], text=True, capture_output=True
        )

    def read_manifest(self) -> dict:
        return json.loads(self.manifest.read_text(encoding="utf-8"))

    def write_manifest(self, payload: dict) -> None:
        self.manifest.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    def verify(self) -> subprocess.CompletedProcess[str]:
        return self.invoke("verify-manifest", "--manifest", str(self.manifest),
                           "--drmtmb", str(self.r_repo))

    def test_complete_structural_manifest_passes_while_evidence_is_missing(self) -> None:
        result = self.verify()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("MANIFEST_STRUCTURE_PASS", result.stdout)
        parity = self.invoke("verify-parity", "--manifest", str(self.manifest),
                             "--drmtmb", str(self.r_repo))
        self.assertNotEqual(parity.returncode, 0)
        self.assertIn("PARITY_EVIDENCE_INCOMPLETE", parity.stdout)

    def test_empty_manifest_never_vacuously_passes_parity(self) -> None:
        empty = self.root / "empty.json"
        empty.write_text("{}\n", encoding="utf-8")
        result = self.invoke("verify-parity", "--manifest", str(empty),
                             "--drmtmb", str(self.r_repo))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("schema_version", result.stdout + result.stderr)

    def test_missing_native_row_is_rejected(self) -> None:
        payload = self.read_manifest()
        payload["native_rows"].pop()
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_required_supplement_source_hash_cannot_be_deleted(self) -> None:
        payload = self.read_manifest()
        del payload["source"]["files"]["R/drmTMB.R"]
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_zero_gap_scaffold_still_refuses_parity_success(self) -> None:
        spec = importlib.util.spec_from_file_location("parity_campaign_test", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        stdout = io.StringIO()
        with patch.object(module, "parity_gaps", return_value=[]), contextlib.redirect_stdout(stdout):
            result = module.main(["verify-parity", "--manifest", str(self.manifest),
                                  "--drmtmb", str(self.r_repo)])
        self.assertEqual(result, 1)
        self.assertIn("PARITY_EVIDENCE_REVIEW_REQUIRED", stdout.getvalue())

    def test_duplicate_native_row_is_rejected(self) -> None:
        payload = self.read_manifest()
        payload["native_rows"].append(payload["native_rows"][0])
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_wrong_source_hash_is_rejected(self) -> None:
        payload = self.read_manifest()
        payload["source"]["files"]["NAMESPACE"]["sha256"] = "0" * 64
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_altered_native_source_field_is_rejected(self) -> None:
        payload = self.read_manifest()
        payload["native_rows"][0]["source"]["family_route"] = "invented"
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_omitted_required_outputs_are_rejected(self) -> None:
        payload = self.read_manifest()
        del payload["native_rows"][0]["parity_contract"]["required_outputs"]
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_required_output_set_cannot_be_reduced(self) -> None:
        payload = self.read_manifest()
        payload["native_rows"][0]["parity_contract"]["required_outputs"] = [{
            "name": "fit", "direct_status": "MISSING", "bridge_status": "MISSING",
        }]
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_declared_supplemental_admissions_cannot_be_deleted_or_renamed(self) -> None:
        original = self.read_manifest()
        deleted = json.loads(json.dumps(original))
        deleted["supplemental_admissions"] = []
        self.write_manifest(deleted)
        self.assertNotEqual(self.verify().returncode, 0)
        renamed = json.loads(json.dumps(original))
        renamed["supplemental_admissions"][0]["id"] = "supplemental:invented"
        self.write_manifest(renamed)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_builder_rejects_dirty_pinned_source(self) -> None:
        with (self.r_repo / "NAMESPACE").open("a", encoding="utf-8") as handle:
            handle.write("export(invented)\n")
        result = self.invoke("build-manifest", "--drmtmb", str(self.r_repo), "--ref", self.ref,
                             "--output", str(self.root / "dirty.json"))
        self.assertNotEqual(result.returncode, 0)

    def test_pass_status_without_receipt_is_rejected(self) -> None:
        payload = self.read_manifest()
        payload["native_rows"][0]["parity_contract"]["direct_reference_fixture"]["status"] = "PASS"
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_legacy_closure_receipt_cannot_be_counted_as_a_pass(self) -> None:
        payload = self.read_manifest()
        fixture = payload["native_rows"][0]["parity_contract"]["direct_reference_fixture"]
        fixture["status"] = "PASS"
        fixture["receipt"] = {
            "kind": "legacy-CLOSUREPASS", "path": "old.tsv",
            "sha256": "0" * 64, "source_git_sha": self.ref,
        }
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_fabricated_pass_receipt_is_rejected_before_it_can_count(self) -> None:
        payload = self.read_manifest()
        fixture = payload["native_rows"][0]["parity_contract"]["direct_reference_fixture"]
        fixture["status"] = "PASS"
        fixture["receipt"] = {
            "kind": "parity-observation-v1", "path": "does-not-exist.json",
            "sha256": "0" * 64, "source_git_sha": self.ref,
            "drm_git_sha": payload["source"]["drm_git_sha"],
        }
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_actual_pass_receipt_requires_matching_artifact_and_metadata(self) -> None:
        payload = self.read_manifest()
        fixture = payload["native_rows"][0]["parity_contract"]["direct_reference_fixture"]
        receipt_path = self.root / "receipt.json"
        receipt = {
            "kind": "parity-observation-v1",
            "drmtmb_git_sha": self.ref,
            "drm_git_sha": payload["source"]["drm_git_sha"],
            "cell_id": "mc-0001", "route": "direct",
            "output": "direct_reference_fixture",
            "numeric_assertions": [{
                "name": "loglik", "status": "PASS", "actual": -10.0,
                "expected": -10.0, "tolerance": 1e-8,
            }],
        }
        receipt_path.write_text(json.dumps(receipt) + "\n", encoding="utf-8")
        fixture["status"] = "PASS"
        fixture["receipt"] = {
            "kind": "parity-observation-v1", "path": receipt_path.name,
            "sha256": hashlib.sha256(receipt_path.read_bytes()).hexdigest(),
            "source_git_sha": self.ref, "drm_git_sha": payload["source"]["drm_git_sha"],
        }
        self.write_manifest(payload)
        self.assertEqual(self.verify().returncode, 0)
        receipt["cell_id"] = "wrong-cell"
        receipt_path.write_text(json.dumps(receipt) + "\n", encoding="utf-8")
        fixture["receipt"]["sha256"] = hashlib.sha256(receipt_path.read_bytes()).hexdigest()
        self.write_manifest(payload)
        self.assertNotEqual(self.verify().returncode, 0)

    def test_resolved_normalization_and_estimand_states_are_structurally_valid(self) -> None:
        payload = self.read_manifest()
        for contract in payload["unresolved_contracts"]:
            contract["status"] = "PASS"
        self.write_manifest(payload)
        self.assertEqual(self.verify().returncode, 0)


if __name__ == "__main__":
    unittest.main()
