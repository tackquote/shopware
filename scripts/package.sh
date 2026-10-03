#!/usr/bin/env bash
#
# Build both installable Shopware artifacts, reproducibly.
#
# Carried over from the Shopware sections of scripts/package-all.sh in the
# former monorepo (github.com/ackm04/tack-ecommerce-extensions), adapted to this
# repository's flattened layout. The filenames and the internal zip structure are
# unchanged, so existing `releases/latest/download/<asset>` links keep resolving
# to the same kind of artifact:
#
#   tack-shopware-app.zip   TackQuoteApp/...   (Shopware Cloud / App system)
#   tack-shopware.zip       TackQuote/...      (self-hosted plugin)
#
# The top-level directory name is load-bearing on both: getting it wrong fails
# silently (the extension installs and then does nothing, or registration fails).
#
# Usage: scripts/package.sh [outdir]     (default: dist)

set -Eeuo pipefail

OUT="${1:-dist}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
rm -rf "$OUT" && mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# Excluded from every artifact. `-x` patterns are matched by zip against the
# paths as it stores them, so they are relative to the staged tree.
COMMON_EX=( -x '*/.git/*' -x '*/.gitignore' -x '*/.DS_Store' -x '*/__MACOSX/*' -x '*/._*' )

say() { printf '  %s\n' "$*"; }

# stage <dest-top-level-dir> <source-dir> — copy a source tree under the exact
# top-level directory name the platform requires.
stage() {
  local top="$1" src="$2" d="$STAGE/$1"
  rm -rf "$d"; mkdir -p "$(dirname "$d")"
  cp -R "$ROOT/$src" "$d"
  find "$d" -name '.DS_Store' -delete 2>/dev/null || true
}

pack() { # pack <zipname> <top-level-dir> [extra zip -x args...]
  local name="$1" top="$2"; shift 2
  ( cd "$STAGE" && zip -q -r -X "$OUT/$name" "$top" "${COMMON_EX[@]}" "$@" )
  say "$name  $(wc -c < "$OUT/$name" | tr -d ' ') bytes"
}

# ── Shopware: App (Cloud) ───────────────────────────────────────────────────
# <meta><name> "must equal the name of the folder your app is contained in"
# (Manifest Reference). That name is ALSO concatenated into the registration
# `proof` HMAC, so a mismatch breaks registration silently. bin/ is a dev-only
# validator and is not shipped.
say "shopware app"
python3 TackQuoteApp/bin/validate-manifest.py >/dev/null
stage TackQuoteApp TackQuoteApp
pack tack-shopware-app.zip TackQuoteApp -x 'TackQuoteApp/bin/*'

# ── Shopware: plugin (self-hosted) ──────────────────────────────────────────
# Top-level dir must match the plugin bundle class and the composer psr-4 root,
# i.e. `TackQuote/` (Creating Plugins — plugin structure).
say "shopware plugin"
stage TackQuote TackQuote
pack tack-shopware.zip TackQuote \
  -x 'TackQuote/tests/*' -x 'TackQuote/phpunit.xml.dist' -x 'TackQuote/.phpunit*'

echo
echo "artifacts in $OUT:"
ls -1 "$OUT"
