"""Temporary-fixture tests for the static Documenter source inventory."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "parity_docs_audit.py"


class DocsInventoryFixture(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.docs = root / "docs"
        self.src = self.docs / "src"
        self.src.mkdir(parents=True)
        (self.src / "index.md").write_text(
            "# Home\n\n[Guide](guide.md)\n\n```julia\n1 + 1\n```\n", encoding="utf-8"
        )
        (self.src / "guide.md").write_text(
            "# Guide\n\n[Missing](missing.md)\n\n```@example guide\n2 + 2\n```\n", encoding="utf-8"
        )
        (self.src / "orphan.md").write_text("# Orphan\n", encoding="utf-8")
        self.make = self.docs / "make.jl"
        self.make.write_text(
            'makedocs(pages = ["Home" => "index.md", "Guide" => "guide.md"])\n',
            encoding="utf-8",
        )
        self.manifest = root / "docs-inventory.json"
        result = self.invoke("--build", "--docs-root", str(self.docs), "--make", str(self.make),
                             "--output", str(self.manifest))
        self.assertEqual(result.returncode, 0, result.stderr)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def invoke(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, str(SCRIPT), *args], text=True, capture_output=True)

    def check(self) -> subprocess.CompletedProcess[str]:
        return self.invoke("--check", "--manifest", str(self.manifest),
                           "--docs-root", str(self.docs), "--make", str(self.make))

    def test_accurate_inventory_passes_even_with_source_findings(self) -> None:
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("DOCS_INVENTORY_PASS", result.stdout)
        manifest = json.loads(self.manifest.read_text(encoding="utf-8"))
        self.assertTrue(any(item["kind"] == "missing_local_target" for item in manifest["findings"]))
        self.assertIn("orphan.md", manifest["navigation"]["unnavigated_pages"])

    def test_documenter_reference_and_site_route_are_not_false_missing(self) -> None:
        (self.src / "index.md").write_text(
            "# Home\n\n[Guide](/guide)\n[Section](@ref)\n", encoding="utf-8"
        )
        result = self.invoke("--build", "--docs-root", str(self.docs), "--make", str(self.make),
                             "--output", str(self.manifest))
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = json.loads(self.manifest.read_text(encoding="utf-8"))
        targets = next(page for page in manifest["pages"] if page["path"] == "index.md")["local_targets"]
        self.assertEqual([target["target_type"] for target in targets], ["site_route", "documenter_reference"])
        self.assertFalse(any(
            item["kind"] == "missing_local_target" and item["path"] == "index.md"
            for item in manifest["findings"]
        ))

    def test_changed_page_is_rejected(self) -> None:
        (self.src / "guide.md").write_text("# Guide\nChanged\n", encoding="utf-8")
        self.assertNotEqual(self.check().returncode, 0)

    def test_added_or_removed_page_is_rejected(self) -> None:
        (self.src / "added.md").write_text("# Added\n", encoding="utf-8")
        self.assertNotEqual(self.check().returncode, 0)
        (self.src / "added.md").unlink()
        (self.src / "orphan.md").unlink()
        self.assertNotEqual(self.check().returncode, 0)

    def test_omitted_navigation_entry_is_rejected(self) -> None:
        manifest = json.loads(self.manifest.read_text(encoding="utf-8"))
        manifest["navigation"]["entries"].pop()
        self.manifest.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        self.assertNotEqual(self.check().returncode, 0)

    def test_hidden_navigation_entry_is_recorded_and_visibility_drift_is_rejected(self) -> None:
        self.make.write_text(
            'makedocs(pages = ["Home" => "index.md", hide("Transition" => "guide.md")])\n',
            encoding="utf-8",
        )
        result = self.invoke("--build", "--docs-root", str(self.docs), "--make", str(self.make),
                             "--output", str(self.manifest))
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = json.loads(self.manifest.read_text(encoding="utf-8"))
        entry = next(item for item in manifest["navigation"]["entries"] if item["path"] == "guide.md")
        self.assertFalse(entry["visible"])
        self.assertEqual(manifest["navigation"]["hidden_paths"], ["guide.md"])
        self.make.write_text(
            'makedocs(pages = ["Home" => "index.md", "Transition" => "guide.md"])\n',
            encoding="utf-8",
        )
        self.assertNotEqual(self.check().returncode, 0)

    def test_unlisted_legacy_transition_is_classified_not_generic_orphan(self) -> None:
        (self.src / "get-started.md").write_text("# Transition\n", encoding="utf-8")
        result = self.invoke("--build", "--docs-root", str(self.docs), "--make", str(self.make),
                             "--output", str(self.manifest))
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = json.loads(self.manifest.read_text(encoding="utf-8"))
        self.assertEqual(manifest["navigation"]["legacy_unlisted_paths"], ["get-started.md"])
        kinds = [item["kind"] for item in manifest["findings"] if item.get("path") == "get-started.md"]
        self.assertEqual(kinds, ["legacy_transition_page_unlisted"])

    def test_changed_make_file_is_rejected(self) -> None:
        self.make.write_text('makedocs(pages = ["Home" => "index.md"])\n', encoding="utf-8")
        self.assertNotEqual(self.check().returncode, 0)


if __name__ == "__main__":
    unittest.main()
