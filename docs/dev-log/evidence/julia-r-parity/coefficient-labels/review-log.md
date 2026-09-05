# Coefficient-label independent review receipts

## Rose — scalar-provenance review, source cb1039fe

Requested/actual dispatch: Sol/high native child; read-only, no fits or edits.
Verdict: NOT READY. The nested-I context repairs and cross-dpar outer-parenthesis
regression were sound, but source capture at bridge.jl:847 only covered enclosing
calls containing literal I(. An admitted `exp((1 + scale(x))/2)` therefore took
an arithmetic fallback that lost grouping and exported `exp(1 + scale(x)/2)`.
Numbers alone passing did not establish label identity or reliable selection.
Required: preserve source spelling for all admitted scalar FunctionTerms; scope
function-label provenance and materialization reuse by formula part and outer
spelling; test nested scale, mixed scale/I and cross-dpar spelling neighbours;
keep DSL/formula-level powers/subtraction and poly restrictions unchanged.

Root retained public007 and combined004 as bounded historical evidence and
reopened leafG2/G3; Terra/high owns the repair. A native twelve-expression scalar
fixture extends the independent ten-expression I fixture. The public denominator
increases12→15 without removing cases or loosening tolerances.

## Shannon — owned R patch boundary

Luna/low read-only scout verified four narrow owned bridge hunks at
`/private/tmp/drm-parity-20260830/coefficient-labels/owned-julia-bridge.patch`.
Reconstructed R source SHA2565284c3407124bd2051c38b6b46191495d2141fc25f1ce0b0882fa882ba952cbf;
patch SHA256b2e4bcef33708796927f4fce1b8894464b7a733b0935c16526af0d3bb982e42c.
This requires the new owned R/julia-coefficient-labels.R helpers. Foreign ZOB
hunks are not included; they remain untouched in the original worktree.
A clean owned-source runtime has not yet been exercised. No clean-build claim.

## Rose — per-parameter provenance architecture, source325e17af

Sol/high independent read-only review: architecture APPROVED, runtime pending.
Per-parameter source maps and scoped scale/factor atoms resolve scale and no-atom
exp(x)/exp((x)) cross-parameter collisions. Canonical positional/keyed/LSS routes
bind consistently; formula/DSL and poly boundaries preserved in the repair.
Required remaining repair: generalized arithmetic lexer wrongly rejects existing
ifelse comparison/comma syntax. Native conditional fixture and public case added;
no generic-function engine or numerical-semantics expansion authorized by this
review. Provenance docstring must describe functions without atoms too.

## Rose — final source and owned-only evidence APPROVED

Source269937e0fd5a88f4db973759a7f03c91e288da2e9a7a9f65f1ec74e61072cfaf;
test333903309f126a11840b296506f77c22421c6a3a88893cc80f0229d84df8dee6.
Sol/high read-only source review approved the unary! repair, preserved!= and
nondegenerate13-row conditional fixture. No blocker in bounded scope.
Independently reran R public008 checker:17cases+12operations, currenthashes,
13damages rejected. Verified combined0051061/1061,89.3627s,108unchangedinputs,
Julia1.10.0 with1Julia/1BLASthread. No fits performed by reviewer.

New Python receiptchecker initially used assert; Rose caught optimized-mode
bypass before closure. It now uses explicitValueError and finiteelapsedchecks.
Rose independently reran normal and -O self-tests:108currentinputs validated
and11damages rejected in each mode. Checkersourceprefixaa148751 approved.
Underlying fit/source evidence unchanged. No remaining bounded blocker.

## Melissa — obligation reconciliation

Responsibility performed by existing Terra/high child after its implementation
work; this is obligation reconciliation, not independent correctness review
(Rose performed that). Identified stale draftreport/checkpoint, missing copied
finalreceipts, finalRoseverdict and check-logentry; root updated those atclosure.
Actual parentSol/medium,builder/reconcilerTerra/high,RoseSol/high,scoutLuna/low.
Activeagent-hours uninstrumented. AllprogrammeG0–G8 and originalbroader
obligations remainopen. ForeignZOB/S5 excludedfromcandidateandpreserved; denied
Gaussianenginefilesuntouched. No performance/coverage/fullpackage certification.
