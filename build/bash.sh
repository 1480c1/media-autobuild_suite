#!/bin/bash
logFile=$(cygpath -u "$1" 2> /dev/null)
shift
[[ -z $logFile || $# -eq 0 ]] && exit 1
script -eqf --command "/usr/bin/bash -o pipefail -lc '$*'" /dev/null | tee "$logFile"
exit "${PIPESTATUS[0]}"
