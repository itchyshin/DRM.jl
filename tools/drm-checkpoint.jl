#!/usr/bin/env julia
#
# drm-checkpoint.jl — recovery helper for evidence-first rehydration.
#
# Prints the repo state an agent needs to resume work without trusting chat
# memory (see CLAUDE.md → "evidence-first rehydration"). Run from the repo root:
#
#     julia tools/drm-checkpoint.jl
#
# It shells out to git and points at the dev-log artifacts. Read-only.

function section(title)
    println("\n", "="^72)
    println("  ", title)
    println("="^72)
end

tryrun(cmd) = try
    run(cmd)
catch err
    println("  (could not run `", cmd, "`: ", err, ")")
end

section("git — branch & working tree")
tryrun(`git status --short --branch`)

section("git — recent commits")
tryrun(`git log --oneline -n 12`)

section("git — diff stat vs HEAD")
tryrun(`git diff --stat`)

section("dev-log artifacts (read these next)")
for f in [
    "docs/dev-log/check-log.md",
    "docs/dev-log/check-log.d",
    "docs/dev-log/coordination-board.md",
    "ROADMAP.md",
    "HANDOVER.md",
    "AGENTS.md",
]
    println(isfile(f) ? "  ✓ $f" : "  · $f (missing)")
end
println("\n  Latest after-task reports:")
atdir = "docs/dev-log/after-task"
if isdir(atdir)
    reports = sort(filter(f -> endswith(f, ".md"), readdir(atdir)))
    isempty(reports) ? println("    (none yet)") :
        foreach(r -> println("    - $atdir/$r"), last(reports, 5))
end

section("next: GitHub work ledger")
println("  gh issue list --milestone \"Phase 0 — Team & workflows\"")
println("  gh issue list --label roadmap")
println("\nRehydration: reconstruct from the above, not from chat. See CLAUDE.md.")
