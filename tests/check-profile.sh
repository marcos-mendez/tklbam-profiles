#!/bin/bash
# Lint a tklbam profile against the appliance that it backs up.
#
#   tests/check-profile.sh PROFILE CONF
#
# PROFILE is a profile of this repository (one path per line, "-" excludes,
# "#" comments). CONF is a file with the appliance's path variables in the
# form of its conf.d/main (WEBROOT=..., DATAROOT=...); tests/fixtures holds
# a copy per appliance. Every path in the profile must be absolute, listed
# once and lie under DATAROOT or WEBROOT, and at least one path must be
# under DATAROOT: a profile that points somewhere else backs up nothing.
#
# Prints one TAP line per profile line; the exit status is the number of
# failed lines (2 on a usage error).

set -uo pipefail

usage() {
    echo "usage: $0 PROFILE CONF" >&2
    exit 2
}

[[ $# -eq 2 ]] || usage
profile="$1"
conf="$2"
[[ -f "$profile" ]] || { echo "profile not found: $profile" >&2; exit 2; }
[[ -f "$conf" ]] || { echo "conf not found: $conf" >&2; exit 2; }

# conf_var NAME: the value of NAME=... in CONF, quotes stripped
conf_var() {
    sed -n "s/^$1=//p" "$conf" | head -1 | tr -d '"'"'"
}

dataroot="$(conf_var DATAROOT)"
webroot="$(conf_var WEBROOT)"
[[ -n "$dataroot" ]] || { echo "no DATAROOT in $conf" >&2; exit 2; }
[[ -n "$webroot" ]] || { echo "no WEBROOT in $conf" >&2; exit 2; }

# under PATH ROOT: PATH is ROOT or below it
under() {
    [[ "$1" == "$2" || "$1" == "$2"/* ]]
}

count=0
failed=0
dataroot_lines=0
declare -A seen=()

while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    count=$((count + 1))
    path="${line#-}"
    if [[ "$path" != /* ]]; then
        verdict="not ok $count - $line: not an absolute path"
    elif [[ -n "${seen[$path]:-}" ]]; then
        verdict="not ok $count - $line: listed twice"
    elif under "$path" "$dataroot"; then
        verdict="ok $count - $line: under DATAROOT $dataroot"
        dataroot_lines=$((dataroot_lines + 1))
    elif under "$path" "$webroot"; then
        verdict="ok $count - $line: under WEBROOT $webroot"
    else
        verdict="not ok $count - $line: outside WEBROOT $webroot and DATAROOT $dataroot"
    fi
    seen[$path]=1
    [[ "$verdict" == ok* ]] || failed=$((failed + 1))
    echo "$verdict"
done < "$profile"

if [[ $dataroot_lines -eq 0 ]]; then
    count=$((count + 1))
    failed=$((failed + 1))
    echo "not ok $count - no path under DATAROOT $dataroot"
fi

echo "1..$count"
echo "# $((count - failed)) of $count lines match $conf"
exit "$failed"
