from pathlib import Path
import hashlib
import json
import subprocess

root = Path(__file__).resolve().parent
manifest = json.loads((root / "manifest.json").read_text())
actual = {
    str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
    for path in root.rglob("*")
    if path.is_file() and path.name != "manifest.json"
}
assert actual == manifest, "artifact manifest mismatch"

animal1 = (root / "actual-r-animal-spatial-threads1-final.log").read_text()
animal4 = (root / "actual-r-animal-spatial-threads4-final.log").read_text()
poisson1 = (root / "poisson-relmat-j1-escalated.log").read_text()
poisson4 = (root / "poisson-relmat-j4.log").read_text()
damage = (root / "provider-damage-control.log").read_text()
environment_red = (root / "poisson-relmat-j1.log").read_text()

for log, threads, threaded, workers in (
    (animal1, 1, "FALSE", 1),
    (animal4, 4, "TRUE", 2),
):
    assert "ACTUAL_R_ANIMAL_SPATIAL_BOOTSTRAP_PROFILE_PASS" in log
    assert log.count("$bootstrap_n") == 2
    assert log.count("$bootstrap_failed") == 2
    assert log.count("[1] 2") >= 2
    assert log.count("[1] 0") >= 4
    assert log.count('"bootstrap"') >= 2
    assert log.count('"profile"') >= 2
    assert log.count(f"$julia_threads\n[1] {threads}") == 2
    assert log.count(f"$bootstrap_julia_threads\n[1] {threads}") == 2
    assert log.count(f"$profile_julia_threads\n[1] {threads}") == 2
    assert log.count(f"$bootstrap_threaded\n[1] {threaded}") == 2
    assert log.count(f"$profile_threaded\n[1] {threaded}") == 2
    assert log.count(f"$bootstrap_workers\n[1] {workers}") == 2
    assert log.count(f"$profile_workers\n[1] {workers}") == 2
    assert log.count("$blas_threads\n[1] 1") == 2
    assert "using a pseudo-inverse" in log

for log, threads in ((poisson1, 1), (poisson4, 4)):
    assert "ACTUAL_R_POISSON_RELMAT_BOOTSTRAP_PROFILE_PASS" in log
    assert "$difference\n[1] 0 0 0" in log
    assert "$profile_difference\n[1] 0 0" in log
    assert f"$julia_threads\n[1] {threads}" in log
    assert "$blas_threads\n[1] 1" in log
    assert "2/2 successful refits" in log
    assert "using a pseudo-inverse" in log

assert "PROVIDER_DAMAGE_CONTROL_PASS" in damage
for name in ('"animal"', '"spatial-converted-K"', '"poisson-relmat"'):
    assert name in damage
assert "$max_abs_delta\n[1] 0.004840839" in damage
assert "$max_abs_delta\n[1] 0.04247073" in damage
assert "$max_abs_delta\n[1] 0.009829918" in damage
assert "operation not permitted (EPERM)" in environment_red
assert "Execution halted" in environment_red
thread_comparison = (root / "poisson-thread-comparison.log").read_text()
assert "point_bootstrap" in thread_comparison
assert "profile" in thread_comparison
assert thread_comparison.count("TRUE") >= 5
assert "POISSON_THREAD_EXACT_EQUALITY_PASS" in thread_comparison

source = json.loads((root / "final-source.json").read_text())
julia_root = root.parents[4]
r_root = Path("/private/tmp/drm-parity-20260830/integration/drmTMB")
for repository, base in ((source["Julia"], julia_root), (source["R"], r_root)):
    source_base = repository["source_base"]
    resolved = subprocess.run(
        ["git", "rev-parse", f"{source_base}^{{commit}}"],
        cwd=base,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    assert resolved == source_base
    subprocess.run(
        ["git", "merge-base", "--is-ancestor", source_base, "HEAD"],
        cwd=base,
        check=True,
        capture_output=True,
        text=True,
    )
    for relative, expected in repository.items():
        if relative == "source_base":
            continue
        observed = hashlib.sha256((base / relative).read_bytes()).hexdigest()
        assert observed == expected, f"source mismatch: {relative}"

print(f"PROVIDER_CROSSPRODUCT_INTEGRITY_PASS {len(actual)} files")
