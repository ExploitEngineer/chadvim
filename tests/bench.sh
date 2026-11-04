#!/usr/bin/env bash
# Median startup time in ms over 5 headless runs, read from --startuptime.
set -u
cd "$(dirname "$0")/.." || exit 1

times=()
for _ in 1 2 3 4 5; do
  log=$(mktemp)
  nvim --headless --startuptime "$log" +qa >/dev/null 2>&1
  # "<elapsed ms>  <self ms>: --- NVIM STARTED ---" (the log ends with a blank line)
  times+=("$(awk '/NVIM STARTED/ { t = $1 } END { print t }' "$log")")
  rm -f "$log"
done

printf '%s\n' "${times[@]}" | sort -n | sed -n 3p
