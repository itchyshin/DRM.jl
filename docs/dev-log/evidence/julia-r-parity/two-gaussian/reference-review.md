# Independent native reference review

Rose, explicitly dispatched gpt-5.6-sol/high, read-only review. Final APPROVE
for the bounded reference after three concrete repairs; no native/Julia fit or
whole-programme correctness approval is implied.

- Original checker reproduced likelihood7.50e-12, gradient1.23e-8, mean2.22e-16,
  SE5.11e-13 agreement. It failed to validate provenance/default controls and
  ignored full conditional cross-covariance. Required fixes applied: retained
  external source/runner/DLL/version anchor, default empty controls and integer
  convergence0; full covariance precision identity, symmetry, observed-row
  zeros and positive definiteness; opposite-slope and damaged-offdiagonal tests.
- Rose then constructed finite inputs y=1e200,x1=x2=1e197 whose computed
  likelihood becameNaN; max(error,NaN) hid it. Computed likelihood, posterior
  means, gradients, SEs, predictions and final errors now require finiteness.
  This is a rejection guarantee, not numerical support for arbitrary extremes.
- All25 deliberate damages pass normally and under Python-O; no assert-based
  acceptance guards. Rose independently reproduced both runs.

Native160row default fit elapsed0.618seconds, all8masks, convergence0relative
convergence(4). All48 recorded source hashes and DLL hash independently matched
at generation. Frozen JSON SHA2f560fd5298458a3ab9aa335eb5235eb28c86dc39ed11f8ef74ccc93def24a44.
Reviewed checker SHA5a5f92feeae788aa583104be22df08b18ca5b013f41e15d43e24e201d8dd82ae.

The native fixed-parameter covariance is INPUT to the imputation SE oracle;
this reference does not independently prove it is inverse observed information.
The subsequent fitted-kernel checker has a separate independent Hessian check.
No original native failure, optimizer default or4e-6 tolerance was changed.
