# Overlapping inference BLAS scopes

Two simultaneous DRM inference calls could end their BLAS pinning scopes out of
order. The first caller restored the original thread count while the second was
still active, allowing nested BLAS/Julia oversubscription. This is a shared
configuration/performance defect; no coefficient or interval corruption has been
demonstrated by this reproducer.

The deterministic no-fit test failed on the original helper: BLAS was 2 where 1
was required while the second task remained active. The retained stage-1 test
bytes match the pre-run receipt hash. The repair adds a lock and scope count:
only the first entrant saves/pins BLAS, and only the last exit restores it. The
lock is never held during model computation. Inactive calls keep their behavior.
Uncoordinated external changes to process-global BLAS settings are outside the
helper's contract.

Local one/four-thread checks pass 17 assertions each, covering overlap, nested
scopes, initial BLAS1, inactive scopes and exception restoration. Rose approved
the source/test contract. Real profile/bootstrap checks completed on a separate
Totoro source copy: five files, 181 testset assertions plus a final BLAS-restoration
assertion, 58 seconds, exit 0. All 327 source/test hashes matched and remained
unchanged. Four Julia threads and initial/final BLAS4 were verified. Warnings
about boundary Hessians and untrustworthy standard errors remain in the raw log.

No estimator, API or likelihood changed. This is not a measured speedup or full
parallel-correctness proof. The location-only profiler's separate pinning gap and
the whole registered warm-workflow policy remain programme work.
