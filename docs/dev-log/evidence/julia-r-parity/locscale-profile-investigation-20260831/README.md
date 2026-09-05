# Location-scale profiling: two confirmed defects, repair in progress

The compact Gamma fixture reproduced ignored threads=true: its original run
reported12pass/4fail in62seconds. Two failures target thread admission; two
finite-only endpoint expectations were too strong and need status-aware tests.
SignedInf outcomes have not been independently certified as truly unbounded.
Exact stage2bytes are retained; stage1 NB2 timeout log is retained but its
replaced fixture bytes were not snapshotted. No stage1hash is invented.

Independent Rose and root pure controls prove a second defect: exhausted or
failed root refinement can return a finite uncertified endpoint, while the
location-scale adapter hardcodes failed=0. Raw output, frozen-source reproducer
and reviewed repair contract are retained. No user dataset was needed, and this
is not an Ayumi-specific reproduction. Failure reporting takes priority over
threading; neither repair is claimed complete in this evidence checkpoint.
