#!/bin/bash
# Coverage of the moodle profile: the share of its lines that
# tests/check-profile.sh can account for against the appliance's paths
# (tests/fixtures/moodle.conf). Exits 1 below the threshold (default 95).
# Also runs the lint on the profile as it was before the fix
# (tests/fixtures/moodle-stale.profile) and fails unless it is rejected.
#
#   tests/coverage.sh [THRESHOLD]
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/.." && pwd)"
threshold="${1:-95}"
conf="$here/fixtures/moodle.conf"

tap="$("$here/check-profile.sh" "$repo/moodle" "$conf" || true)"
printf '%s\n' "$tap"
total="$(grep -cE '^(not )?ok [0-9]+ ' <<<"$tap")"
passed="$(grep -cE '^ok [0-9]+ ' <<<"$tap")"
percent="$(awk -v p="$passed" -v t="$total" 'BEGIN { printf "%.2f", (t ? 100 * p / t : 0) }')"

echo "moodle: $percent percent ($passed of $total lines) covered, threshold $threshold"
if ! awk -v p="$percent" -v t="$threshold" 'BEGIN { exit !(p + 0 >= t + 0) }'; then
    echo "coverage below threshold" >&2
    exit 1
fi

echo "# the stale profile must be rejected"
if "$here/check-profile.sh" "$here/fixtures/moodle-stale.profile" "$conf"; then
    echo "check-profile.sh accepted the stale profile" >&2
    exit 1
fi
