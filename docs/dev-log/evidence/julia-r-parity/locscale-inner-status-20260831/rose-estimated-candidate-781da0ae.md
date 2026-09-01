# Rose review — estimated-comparison candidate 781da0ae

Date: 2026-08-31. Reviewer: `/root/rose_plan_gate`, Sol/high.
Read-only source review; no fits or edits. Candidate was still moving.

**Verdict: NOT READY for acceptance.**

1. The scale `S` misses cancellation inside loading sums, NB2/Gamma gradient
   expressions and base predictor construction. Use absolute loading products,
   unreduced kernel-gradient constituents and the effect of predictor arithmetic
   on the directional gradient. Keep signed estimates separate and retain the
   frozen `8` and `64eps(Float64)` factors.
2. The preliminary Gamma estimate misses the frozen `1e-4` relative oracle
   threshold. A negative estimated margin does not override failed validation.
3. Compare the synthetic quadratic against its independent closed-form change,
   not only signs and self-consistency. Add cancellation-scale controls and the
   remaining clamp-axis controls.
4. Explicitly reject a nonfinite `Q8 + E`. Existing `< 0` rejects positive
   infinity, so this is contract clarity, not a demonstrated false acceptance.
5. Replace "bounded-error estimate" with "estimate with an estimated error
   margin"; no rigorous error bound was established.

Sparse `findnz` traversal is O(nnz), with three O(nnz) temporary arrays. No dense
scan was found. Immutable quadrature nodes, private accumulators and restrictions
that disable only the fallback are appropriate. No formal global proof gate is
added. Required implementation changes were sent directly to the builder.
