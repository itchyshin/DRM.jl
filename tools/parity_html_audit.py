#!/usr/bin/env python3
"""Check generated local HTML links, HTML fragments and asset paths.

External URLs, JavaScript behavior, non-HTML fragment conventions and mobile
layout are outside this check. Responsive-image srcset requires a separate
checker: its presence fails explicitly. Never read a symlink target outside the root.
"""
import argparse
from html.parser import HTMLParser
import os
from pathlib import Path
import sys
from urllib.parse import unquote, urlsplit


class Parser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = set()
        self.unsupported = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get("id"):
            self.ids.add(attrs["id"])
        for kind in ("href", "src"):
            if attrs.get(kind):
                target_kind = "href" if kind == "href" and tag in ("a", "area") else "asset"
                self.links.append((target_kind, attrs[kind]))
        if attrs.get("srcset"):
            self.unsupported.append("srcset")


def local_target(root, page, value, kind="href"):
    parsed = urlsplit(value)
    if parsed.scheme or parsed.netloc or value.startswith("//"):
        return None
    raw = unquote(parsed.path)
    base = root if raw.startswith("/") else page.parent
    target = base / raw.lstrip("/") if raw else page
    candidates = [target]
    if kind == "href":
        if target.resolve() != root:
            candidates.append(Path(str(target) + ".html"))
        candidates.append(target / "index.html")
    for candidate in candidates:
        resolved = candidate.resolve()
        if not resolved.is_relative_to(root):
            return "outside", resolved, ""
        if resolved.is_file():
            fragment = unquote(parsed.fragment) if resolved.suffix.lower() == ".html" else ""
            return "file", resolved, fragment
    return "missing", target, ""


def audit(root):
    root = Path(root).resolve()
    failures, pages, parsed_pages = [], [], {}
    links = assets = fragments = 0
    if not root.is_dir():
        return pages, links, assets, fragments, [f"{root}: missing build directory"]
    for directory, dirs, files in os.walk(root, followlinks=False):
        dirs[:] = sorted(d for d in dirs if d != "node_modules" and not (Path(directory) / d).is_symlink())
        pages.extend(Path(directory) / f for f in sorted(files)
                     if f.endswith(".html") and not (Path(directory) / f).is_symlink())
    if not pages:
        failures.append(f"{root}: no HTML pages")

    def parse(page):
        if page not in parsed_pages:
            parser = Parser()
            parser.feed(page.read_text(encoding="utf-8"))
            parsed_pages[page] = parser
        return parsed_pages[page]

    for page in pages:
        try:
            parser = parse(page)
            failures.extend(f"{page}: unsupported {attribute}; responsive-image assets require separate verification"
                            for attribute in parser.unsupported)
            for kind, value in parser.links:
                target = local_target(root, page, value, kind)
                if target is None:
                    continue
                if kind == "asset":
                    assets += 1
                else:
                    links += 1
                status, path, fragment = target
                if status != "file":
                    failures.append(f"{page}: {status} target {value}")
                elif fragment:
                    fragments += 1
                    if fragment not in parse(path).ids:
                        failures.append(f"{page}: missing fragment target {value}")
        except (OSError, UnicodeError, ValueError) as error:
            failures.append(f"{page}: read/parse error: {error}")
    return pages, links, assets, fragments, failures


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root")
    args = parser.parse_args()
    pages, links, assets, fragments, failures = audit(args.root)
    print(f"HTML_AUDIT pages={len(pages)} local_links={links} local_assets={assets} fragments={fragments} failures={len(failures)}")
    for failure in failures:
        print("FAIL", failure)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
