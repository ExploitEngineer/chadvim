#!/usr/bin/env bash
# Run every tests/*_test.lua headless against this config.
#
#   tests/run.sh            all tests
#   tests/run.sh theme      only files whose path contains "theme"
#
# Each file gets two fresh temp dirs: CHADVIM_BASE46_CACHE (a copy of the real
# compiled cache, so tests never compile into the one a normal start loads)
# and HYDE_CACHE_HOME (a copy of tests/fixtures/hyde, so tests can rewrite
# wall.dcol freely).
set -u
cd "$(dirname "$0")/.." || exit 1

filter=${1:-}
failed=0
ran=0

for file in tests/*_test.lua; do
  [[ -n $filter && $file != *"$filter"* ]] && continue
  ran=$((ran + 1))

  tmp=$(mktemp -d)
  mkdir -p "$tmp/base46" "$tmp/hyde"
  # a copy of the real compiled cache: isolated, but startable on day one
  real_cache=${XDG_DATA_HOME:-$HOME/.local/share}/nvim/base46
  [[ -d $real_cache ]] && cp -r "$real_cache/." "$tmp/base46/"
  [[ -d tests/fixtures/hyde ]] && cp -r tests/fixtures/hyde/. "$tmp/hyde/"

  out=$(CHADVIM_BASE46_CACHE="$tmp/base46/" HYDE_CACHE_HOME="$tmp/hyde" CHADVIM_TEST_FILE="$file" \
    timeout 120 nvim --headless -c "luafile tests/runner.lua" 2>&1)
  code=$?
  rm -rf "$tmp"

  if [[ $code -eq 0 ]]; then
    echo "PASS $file"
  else
    failed=$((failed + 1))
    [[ $code -eq 124 ]] && out+=$'\n'"TIMEOUT after 120s"
    echo "FAIL $file (exit $code)"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi
done

echo "$((ran - failed))/$ran passed"
[[ $ran -gt 0 && $failed -eq 0 ]]
