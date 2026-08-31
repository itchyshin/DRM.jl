# Combined001 — passes, not accepted as final evidence

The five-file batch passed188 assertions in29.519 seconds, four Julia threads
and one BLAS thread. Recorded source/test/dependency manifests were unchanged.
This batch is historical, not final qualification.

Rose independently identified defects outside that test denominator:

- The refactor imposed stored-gradient optimizer options on unstored routes,
  altering historical iteration/termination defaults.
- A below-reference tolerance proportional to absolute NLL could hide a
  material negative likelihood-ratio value after adding a large constant.
- The profile_curve docstring was attached to a new helper instead of its
  public function.

The builder is repairing all three and adding constant-shift controls. PublicR
and executable-doc checks wait for a new source freeze. No previous passing
receipt is substituted for the corrected-source rerun.
