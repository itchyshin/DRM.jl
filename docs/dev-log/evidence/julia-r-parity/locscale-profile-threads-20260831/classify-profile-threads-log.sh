#!/bin/sh
set -eu

log=${1:?usage: classify-profile-threads-log.sh LOG SUBPROCESS_STATUS}
status=${2:?usage: classify-profile-threads-log.sh LOG SUBPROCESS_STATUS}
failures=$(grep -Fc 'Test Failed at' "$log" || true)
if [ "$status" -eq 1 ] && [ "$failures" -eq 1 ] && grep -Fq '0 errored' "$log" && grep -Fq 'threaded.threaded' "$log"; then
  echo "S11_EXPECTED_RED"
  exit 0
fi
echo "S11_EXPECTED_RED_REJECTED status=$status failures=$failures"
