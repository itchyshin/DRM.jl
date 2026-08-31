# Paired integration CI repair

## 1. Goal

Repair the two blockers exposed by DRM.jl PR #565 without widening its model or
inference claims.

## 2. Implemented

The internal reference now includes the five private paired-whitening docstrings
reported missing by Documenter. The phylogenetic LSS boundary helper now keeps
the unresolved dedicated comparison broken, asserts the scalar multi-component
comparison on Linux, and skips that comparison on platforms where the fixture
has not met the same numerical boundary.

## 3a. Decisions and Rejected Alternatives

The test was not changed globally from `@test_broken` to `@test`: both Linux CI
versions pass, but the same optimizer fixture still differs on macOS. A platform
boundary records the measured result without claiming cross-platform parity.

## 4. Files Touched

One internal reference page, one focused test file, this report, and one
collision-free check-log entry. No package implementation or public API changed.

## 5. Checks Run

The focused file completed with 401 passes, two explicit non-passes on macOS
(one known broken, one platform skip), and no failures. A full local Documenter
build completed through VitePress rendering with no missing-doc error.

## 6. Tests of the Tests

Both Linux CI jobs first failed because the scalar comparison produced an
unexpected pass under `@test_broken`. Before the platform boundary, promoting it
unconditionally produced a real macOS failure with a maximum parameter
difference of 0.861, proving that an unconditional assertion was incorrect.

## 7a. Issue Ledger

This repairs the current checks for PR #565. The paired drmTMB PR #1104 and the
global parity programme remain open; DRM.jl must merge first.

## 8. Consistency Audit

Every newly documented symbol is the exact private symbol named by Documenter.
The test distinction matches observed platforms and retains strict mode through
`DRM_LSS_STRICT_BOUNDARY=1`.

## 9. What Did Not Go Smoothly

The first local Documenter run reached rendering but the sandbox blocked Julia's
standard manifest-usage log. The identical build completed with normal Julia
filesystem permission.

## 10. Known Residuals

The scalar multi-component optimizer fixture still misses the 4e-6 coefficient
boundary on macOS. The dedicated small fixture remains known broken on all
measured platforms unless strict mode is requested.

## 11. Team Learning

An unexpected pass can reveal a platform-specific numerical result rather than
universal closure. CI repair must preserve that distinction explicitly.

## 12. Cross-Product Coverage

This slice covers Documenter completeness and the named Linux LSS boundary test.
It does NOT cover macOS coefficient invariance, Windows behavior, global parity,
profile or bootstrap coverage, performance, release, or deployment.

## 13. Next Action and Routing

Push the repair, require fresh green checks on PR #565, merge it, then require
fresh green checks and merge PR #1104 second.
