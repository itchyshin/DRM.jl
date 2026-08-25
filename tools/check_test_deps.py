#!/usr/bin/env python3
"""Fail if a test file loaded by `runtests.jl` imports a package that
`test/Project.toml` does not declare.

WHY THIS EXISTS. A local `julia --project=test test/runtests.jl` resolves packages
from `test/Manifest.toml`, which lists the full transitive closure. CI runs
`Pkg.test()`, which builds a FRESH environment from `test/Project.toml` alone. So a
test file can `using SomePackage` that is present transitively, pass every local
run, and break CI — which is exactly what happened on 2026-08-24: a new test file
did `using StatsModels`, passed locally at 304 testsets, and failed both CI jobs
with "Package StatsModels not found in current path".

This repo's discipline is local-checks-over-CI, which only works if the local check
can actually see the same failures. This closes that particular blind spot.

    python3 tools/check_test_deps.py

Only files `runtests.jl` actually includes are checked. A few standalone
diagnostic scripts in `test/` (grad_check_*.jl) import CSV/DataFrames and are
deliberately NOT part of the suite; flagging them would be noise, and would
train people to ignore this tool. `test_lambda_p100.jl` (#465) is also
deliberately not part of the suite, but for a different reason: it's a genuine,
reproducible failure at fixture scale (the sparse-EM Λ M-step descends the true
marginal at p=100 real data), not a dependency issue — see the #465 after-task
note.
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEST = os.path.join(REPO, "test")

# Always available without being declared.
STDLIB = {
    "Base", "Core", "Main", "Test", "Random", "LinearAlgebra", "SparseArrays",
    "Statistics", "Printf", "DelimitedFiles", "TOML", "Dates", "Logging",
    "Serialization", "Pkg", "InteractiveUtils", "Markdown", "Libdl", "Profile",
    "Distributed", "SharedArrays", "Sockets", "UUIDs", "Unicode", "Mmap",
}


def declared_deps():
    path = os.path.join(TEST, "Project.toml")
    text = open(path).read()
    m = re.search(r"\[deps\](.*?)(\n\[|\Z)", text, re.S)
    if not m:
        return set()
    return set(re.findall(r"^([A-Za-z_]\w*)\s*=", m.group(1), re.M))


def included_files():
    """Files runtests.jl includes, one level deep — that is what CI loads."""
    rt = os.path.join(TEST, "runtests.jl")
    names = re.findall(r'include\(\s*"([^"]+)"\s*\)', open(rt).read())
    out = ["runtests.jl"]
    for n in names:
        if n.endswith(".jl"):
            out.append(n)
    return out


def imports_in(path):
    """(line_no, kind, package) for each top-level using/import."""
    found = []
    for i, line in enumerate(open(path, encoding="utf-8").read().splitlines(), 1):
        m = re.match(r"^\s*(using|import)\s+([A-Za-z0-9_,\s\.]+)", line)
        if not m:
            continue
        for pkg in m.group(2).split(","):
            pkg = pkg.strip().split(".")[0].split(":")[0].strip()
            if pkg:
                found.append((i, m.group(1), pkg))
    return found


def main():
    allowed = declared_deps() | STDLIB | {"DRM"}
    problems = []
    checked = 0
    for name in included_files():
        path = os.path.join(TEST, name)
        if not os.path.exists(path):
            continue
        checked += 1
        for lineno, kind, pkg in imports_in(path):
            if pkg not in allowed:
                problems.append((name, lineno, kind, pkg))

    print("checked %d file(s) reachable from runtests.jl" % checked)
    print("declared in test/Project.toml: %d" % len(declared_deps()))
    if not problems:
        print("OK — every import in the suite is declared.")
        return 0
    print("\nUNDECLARED IMPORTS (these pass locally and FAIL under Pkg.test):")
    for name, lineno, kind, pkg in problems:
        print("  test/%s:%d  %s %s" % (name, lineno, kind, pkg))
    print("\nFix by either removing the import (many packages are re-exported by "
          "`using DRM` — `@formula` comes from there) or adding the package to "
          "test/Project.toml [deps].")
    return 1


if __name__ == "__main__":
    sys.exit(main())
