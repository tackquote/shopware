#!/usr/bin/env bash
#
# README/release contract — fails CI if a merchant-facing README regresses on
# either of the two defects that shipped in the retired hub's issue #20 (archived)
# (the former monorepo this repository was split out of):
#
#   1. A version-pinned release asset URL (`releases/download/vX.Y.Z/...`).
#      A pinned link keeps returning 200 while serving an old build the moment
#      the next release ships — the monorepo's v1.1.0 links did exactly that,
#      four releases out of date. The only safe merchant-facing link is
#      `releases/latest/download/<exact-asset-name>`.
#
#   2. Fabricated API surface. `/v1/webhooks` and `/v1/widget/quotes` do not
#      exist anywhere in TackQuote's connector code — they were invented for a
#      "Tack triggers webhook events to create official orders/invoices" claim
#      that was false for every platform. If either string reappears in a
#      README, someone is re-describing an endpoint that was never real instead
#      of citing the platform-specific one.
#
# Usage: scripts/check-release-claims.sh [file ...]   (default: every README*.md)

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
count=0

check_one() {
  local f="$1"
  [ -f "$f" ] || return 0
  count=$((count + 1))

  # 1. Version-pinned release asset URLs.
  if grep -nE 'releases/(download|tag)/v[0-9]+\.[0-9]+\.[0-9]+' "$f" >/dev/null; then
    echo "FAIL: $f pins a release asset to a version tag. Use releases/latest/download/<asset> instead:"
    grep -nE 'releases/(download|tag)/v[0-9]+\.[0-9]+\.[0-9]+' "$f" | sed 's/^/    /'
    fail=1
  fi

  # 2. Fabricated endpoints that were never real.
  if grep -nF '/v1/webhooks' "$f" >/dev/null; then
    echo "FAIL: $f references /v1/webhooks, which no TackQuote connector calls or implements:"
    grep -nF '/v1/webhooks' "$f" | sed 's/^/    /'
    fail=1
  fi
  if grep -nF '/v1/widget/quotes' "$f" >/dev/null; then
    echo "FAIL: $f references /v1/widget/quotes, which no TackQuote connector calls:"
    grep -nF '/v1/widget/quotes' "$f" | sed 's/^/    /'
    fail=1
  fi
}

if [ "$#" -gt 0 ]; then
  for f in "$@"; do check_one "$f"; done
else
  # Every README in the repo except node_modules/vendor/dist/target trees, if any exist locally.
  while IFS= read -r f; do
    check_one "$f"
  done < <(find . \( -iname 'README.md' -o -iname 'readme.txt' \) \
    -not -path '*/node_modules/*' -not -path '*/vendor/*' -not -path '*/dist/*' \
    -not -path '*/target/*' -not -path './.git/*')
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "See the retired hub's issue #20 (archived) for why these are load-bearing checks."
  exit 1
fi

echo "OK: no version-pinned release URLs or fabricated endpoints found in ${count} file(s)."
