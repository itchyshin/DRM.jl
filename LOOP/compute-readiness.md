# Compute readiness — 2026-08-30

User requested using Mac, Totoro and DRAC together intelligently. Existing SSH masters verified;
no fresh login or Duo triggered. Remote reads used existing ControlPath and ProxyCommand=false
so a dead master cannot fall back to a new authenticated connection.

- Mac: development, documentation previews and small correctness oracles. Julia 1.10.0 loaded
  `/private/tmp/drm-parity-20260830/DRM.jl/src/DRM.jl`. Installed R comparator is drmTMB 0.7.0,
  code hash `a5d3f5a974892d6d46a7d0a6095268cdeb956e9e40442f0c6df1623c7c8c7ab1`;
  that installed build is not yet verified against the frozen source pin.
- Totoro: 384 logical CPUs; load approximately 32; 556 GiB available RAM at check.
  Rscript `/usr/bin/Rscript`, R 4.5.3, installed drmTMB 0.7.0 (build identity still unverified).
  Julia `/home/snakagaw/.juliaup/bin/julia`, version 1.12.6, is absent from default noninteractive PATH.
  Programme cap 150 cores; initial pilots 1–8, `OPENBLAS_NUM_THREADS=1`.
  Check shared load before scaling up. Record Julia version differences explicitly; never pool
  Mac and Totoro results into one speed comparison.
- Fir: existing master alive; `squeue --me` showed no jobs; accounts `def-snakagaw_cpu`
  and `def-snakagaw_gpu`; sbatch available. Login-node reads only, no fits. Use CPU allocations
  for suitable validation arrays; no GPU benefit is established for this CPU engine.
- No remote compute submitted. R/Julia timings must share host and resource limits and retain
  exact source/build pins. Preserve evidence and dependency libraries on persistent storage.
- Machine-hour allowance is not authorization for campaigns over 30 minutes: first measure
  a pilot, then obtain the established campaign approval.

## Dispatch policy for the implementation pass

- Keep this Mac responsive: bounded single-process debugging and reader previews;
  stop an overrun and report it rather than silently starting a laptop campaign.
- Totoro is the first CPU destination once a local fixture passes. Prepare isolated
  R/Julia environments from recorded source revisions; the installed version string
  alone is insufficient. Measure transfer/setup separately from warm full workflows.
- Give either outer parallel jobs or each job's internal threads the core budget:
  concurrent jobs multiplied by threads per job must remain at or below the shared
  150-core cap. Start with 1/2/4/8-thread pilots and BLAS threads set to one; do not
  assume that more threads are faster. Recheck shared load before each expansion.
- Use DRAC allocations/arrays for replicated campaigns when pilot runtime, memory,
  and queue cost justify them. Preserve raw failures, seeds, source hashes and run
  metadata on persistent storage. Never count queue waits as active agent work.
- Compare native R, direct Julia and the bridge on the same host under equal resource
  limits. Keep Mac/Totoro/DRAC result sets separate. No GPU route is justified yet.

At this checkpoint all completed fits were bounded Mac checks. Totoro and DRAC
readiness is an earlier read-only observation, not a claim that a job has run or
that either host's present capacity is reserved.
