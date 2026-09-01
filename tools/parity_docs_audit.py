#!/usr/bin/env python3
"""Freeze a static inventory of Documenter source files and navigation.

This checker deliberately inspects source text only. It makes no rendered-site,
Documenter-build, link-rendering, or live-deployment claim.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DOCS_ROOT = REPO_ROOT / "docs"
DEFAULT_MAKE = DEFAULT_DOCS_ROOT / "make.jl"
LINK_RE = re.compile(r"(?<!!)(?<!\!)\[[^\]]*\]\(([^)]+)\)")
IMAGE_RE = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")
NAV_RE = re.compile(r'(?:("[^"]+")\s*=>\s*)?"([^"]+\.md)"')
HIDDEN_NAV_RE = re.compile(r'hide\(\s*(?:("[^"]+")\s*=>\s*)?"([^"]+\.md)"\s*\)')


class AuditError(RuntimeError):
    pass


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def title(text: str, fallback: str) -> str:
    match = re.search(r"^#\s+(.+?)\s*$", text, flags=re.MULTILINE)
    return match.group(1) if match else fallback


def fence_summary(text: str) -> tuple[list[str], int, int]:
    """Count fenced Markdown blocks structurally; this is not execution evidence."""
    opening_info: list[str] = []
    closing_markers = 0
    open_fence = False
    for line in text.splitlines():
        stripped = line.lstrip()
        if not stripped.startswith("```"):
            continue
        if open_fence:
            closing_markers += 1
            open_fence = False
        else:
            opening_info.append(stripped[3:].strip())
            open_fence = True
    return opening_info, closing_markers, int(open_fence)


def local_targets(page: Path, source_root: Path, text: str) -> list[dict[str, Any]]:
    targets: list[dict[str, Any]] = []
    for kind, pattern in (("link", LINK_RE), ("asset", IMAGE_RE)):
        for line, raw in ((text[:match.start()].count("\n") + 1, match.group(1)) for match in pattern.finditer(text)):
            target = raw.strip().strip("<>")
            bare = target.split("#", 1)[0].split("?", 1)[0]
            if not bare or bare.startswith(("http://", "https://", "mailto:", "tel:")):
                continue
            if bare.startswith("@ref"):
                targets.append({
                    "kind": kind,
                    "line": line,
                    "target": target,
                    "target_type": "documenter_reference",
                    "resolved": None,
                    "within_docs_source": None,
                    "exists": None,
                })
                continue
            target_type = "site_route" if bare.startswith("/") else "local_file"
            candidate = source_root / bare.lstrip("/") if target_type == "site_route" else page.parent / bare
            if not candidate.suffix and candidate.with_suffix(".md").is_file():
                candidate = candidate.with_suffix(".md")
            target_path = candidate.resolve()
            try:
                resolved = relative(target_path, source_root.resolve())
                within_source = True
            except ValueError:
                resolved = str(target_path)
                within_source = False
            targets.append({
                "kind": kind,
                "line": line,
                "target": target,
                "target_type": target_type,
                "resolved": resolved,
                "within_docs_source": within_source,
                "exists": target_path.is_file(),
            })
    return targets


def page_record(path: Path, source_root: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    opening_info, closing_markers, unclosed = fence_summary(text)
    return {
        "path": relative(path, source_root),
        "sha256": sha256(path),
        "title": title(text, path.stem),
        "opening_fence_blocks": len(opening_info),
        "closing_fence_markers": closing_markers,
        "unclosed_fence_blocks": unclosed,
        "julia_examples_heuristic": sum(
            info.startswith("julia") or info.startswith("@example") for info in opening_info
        ),
        "r_examples_heuristic": sum(info == "r" for info in opening_info),
        "local_targets": local_targets(path, source_root, text),
    }


def navigation_entries(make_path: Path) -> list[dict[str, Any]]:
    if not make_path.is_file():
        raise AuditError(f"Documenter make file is absent: {make_path}")
    text = make_path.read_text(encoding="utf-8")
    hidden_paths = {path for _title, path in HIDDEN_NAV_RE.findall(text)}
    entries = []
    for raw_title, path in NAV_RE.findall(text):
        entries.append({
            "title": raw_title.strip('"') if raw_title else path,
            "path": path,
            "visible": path not in hidden_paths,
        })
    if not entries:
        raise AuditError("no Markdown navigation entries found in docs/make.jl")
    return entries


def findings_for(pages: list[dict[str, Any]], navigation: list[dict[str, Any]]) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    page_paths = {page["path"] for page in pages}
    nav_paths = [entry["path"] for entry in navigation]
    visible_nav_paths = [entry["path"] for entry in navigation if entry["visible"]]
    for page in pages:
        for target in page["local_targets"]:
            if target["target_type"] != "documenter_reference" and not target["exists"]:
                findings.append({
                    "kind": "missing_local_target",
                    "path": page["path"],
                    "line": target["line"],
                    "target": target["target"],
                })
    legacy_transition = {"get-started.md"}
    for path in sorted(page_paths - set(nav_paths) - legacy_transition):
        findings.append({"kind": "unnavigated_page", "path": path})
    for path in sorted((page_paths - set(nav_paths)) & legacy_transition):
        findings.append({
            "kind": "legacy_transition_page_unlisted",
            "path": path,
            "detail": "Preserved transition URL; Documenter's default pagesonly=false build still emits this source page.",
        })
    for path in sorted(set(nav_paths) - page_paths):
        findings.append({"kind": "navigation_target_without_source_page", "path": path})
    for path in sorted({path for path in nav_paths if nav_paths.count(path) > 1}):
        findings.append({"kind": "duplicate_navigation_path", "path": path})
    if {"getting-started.md", "get-started.md"}.issubset(set(visible_nav_paths)):
        findings.append({
            "kind": "duplicate_first_reader_entry",
            "paths": ["getting-started.md", "get-started.md"],
            "detail": "Both getting-started.md and get-started.md are in the primary navigation.",
        })
    return findings


def build_inventory(docs_root: Path, make_path: Path) -> dict[str, Any]:
    docs_root = docs_root.resolve()
    source_root = docs_root / "src"
    if not source_root.is_dir():
        raise AuditError(f"Documenter source directory is absent: {source_root}")
    pages = [page_record(path, source_root) for path in sorted(source_root.rglob("*.md"))]
    if not pages:
        raise AuditError("Documenter source has no Markdown pages")
    entries = navigation_entries(make_path)
    navigation = {
        "make_path": "docs/make.jl",
        "make_sha256": sha256(make_path),
        "entries": entries,
        "nav_paths": [entry["path"] for entry in entries],
        "visible_paths": [entry["path"] for entry in entries if entry["visible"]],
        "hidden_paths": [entry["path"] for entry in entries if not entry["visible"]],
        "legacy_unlisted_paths": sorted(({"get-started.md"} & {page["path"] for page in pages}) - {entry["path"] for entry in entries}),
        "unnavigated_pages": sorted({page["path"] for page in pages} - {entry["path"] for entry in entries}),
    }
    return {
        "schema_version": 2,
        "scope": "static Documenter source inventory only; no rendered, build, deployment, or live-site claim",
        "source_root": "docs/src",
        "pages": pages,
        "navigation": navigation,
        "findings": findings_for(pages, entries),
    }


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise AuditError(f"cannot read inventory manifest: {error}") from error
    if not isinstance(payload, dict):
        raise AuditError("inventory manifest root must be an object")
    return payload


def verify_inventory(manifest: dict[str, Any], docs_root: Path, make_path: Path) -> None:
    if manifest.get("schema_version") != 2:
        raise AuditError("unsupported or missing inventory schema_version")
    if not isinstance(manifest.get("pages"), list) or not manifest["pages"]:
        raise AuditError("inventory has no source pages")
    navigation = manifest.get("navigation")
    if not isinstance(navigation, dict) or not isinstance(navigation.get("entries"), list) or not navigation["entries"]:
        raise AuditError("inventory has no navigation entries")
    current = build_inventory(docs_root, make_path)
    for field in ("scope", "pages", "navigation", "findings"):
        if manifest.get(field) != current.get(field):
            raise AuditError(f"static inventory drift in {field}")


def write_markdown(inventory: dict[str, Any], output: Path) -> None:
    pages = inventory["pages"]
    navigation = inventory["navigation"]
    lines = [
        "# Documenter source inventory",
        "",
        "This is a **static source** audit. It makes no rendered-site, Documenter-build, deployment, or live-page claim.",
        "",
        f"- Source pages: {len(pages)}",
        f"- Navigation entries: {len(navigation['entries'])}",
        f"- Unnavigated pages: {len(navigation['unnavigated_pages'])}",
        f"- Visible navigation entries: {len(navigation['visible_paths'])}",
        f"- Hidden navigation entries: {len(navigation['hidden_paths'])}",
        f"- Opening fenced code blocks (heuristic): {sum(page['opening_fence_blocks'] for page in pages)}",
        f"- Closing fence markers: {sum(page['closing_fence_markers'] for page in pages)}",
        f"- Unclosed fenced blocks: {sum(page['unclosed_fence_blocks'] for page in pages)}",
        f"- Julia examples (opening-fence heuristic): {sum(page['julia_examples_heuristic'] for page in pages)}",
        f"- R examples (opening-fence heuristic): {sum(page['r_examples_heuristic'] for page in pages)}",
        "",
        "## Source findings",
        "",
    ]
    if inventory["findings"]:
        for finding in inventory["findings"]:
            detail = finding.get("detail") or finding.get("target") or finding.get("path")
            lines.append(f"- `{finding['kind']}`: {detail}")
    else:
        lines.append("- No static-source findings.")
    lines.extend([
        "",
        "Link and code-block fields are source heuristics, not rendered-link or execution evidence. Findings are repair targets, not inventory-check failures. The executable check fails only when the frozen source inventory is inaccurate.",
    ])
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--build", action="store_true")
    action.add_argument("--check", action="store_true")
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--docs-root", type=Path, default=DEFAULT_DOCS_ROOT)
    parser.add_argument("--make", type=Path, default=DEFAULT_MAKE)
    args = parser.parse_args(argv)
    try:
        if args.build:
            if args.output is None:
                raise AuditError("--build requires --output")
            inventory = build_inventory(args.docs_root, args.make)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(inventory, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            write_markdown(inventory, args.output.with_suffix(".md"))
            print(f"DOCS_INVENTORY_BUILT pages={len(inventory['pages'])} output={args.output}")
        else:
            if args.manifest is None:
                raise AuditError("--check requires --manifest")
            verify_inventory(load_manifest(args.manifest), args.docs_root, args.make)
            print("DOCS_INVENTORY_PASS")
    except AuditError as error:
        print(f"DOCS_INVENTORY_FAIL: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
