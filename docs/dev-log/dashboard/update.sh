REPO="/Users/z3437171/Dropbox/Github Local/DRM.jl"
while true; do
  log="/tmp/integrate-skipverify5.log"
  if grep -q "Testing DRM tests passed" "$log" 2>/dev/null; then mg="PASSED"
  elif grep -qE "Some tests did not pass|errored during testing" "$log" 2>/dev/null && ! pgrep -f 'Pkg.test' >/dev/null; then mg="failed"
  else mg="running"; fi
  sets=$(grep -c "Test Summary" "$log" 2>/dev/null); sets=${sets:-0}
  [ -f /tmp/inner_solve_fix.patch ] && hp="ready" || hp="in flight"
  ar=$(ls "$REPO"/report/finish-audit/*.md 2>/dev/null | wc -l | tr -d ' ')
  fs=$(ls "$REPO"/report/finish-audit/specs/*.md 2>/dev/null | wc -l | tr -d ' ')
  jp=$(pgrep -x julia | wc -l | tr -d ' ')
  printf '{"updated":"%s","mustHave":42,"mergeGate":"%s","mergeSets":%s,"hardenPatch":"%s","auditReports":%s,"frontierSpecs":%s,"juliaProcs":%s}'     "$(date +%H:%M:%S)" "$mg" "$sets" "$hp" "$ar" "$fs" "$jp" > /tmp/drm-dashboard/status.json
  sleep 12
done
