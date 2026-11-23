#!/usr/bin/env bash
# fetch_doc.sh <url> [start_regex] [max_lines]
#
# Download a documentation page and print it as plain text, so you read the
# CURRENT wording (never a remembered copy). Works with only curl + sed + grep
# (no Python needed - it is often missing on Windows).
#
#   url         page to read
#   start_regex optional: print from the LAST line matching this regex
#               (skips the site navigation menu that comes first).
#               Example: "Installation process" or "Overview"
#   max_lines   optional: cap on printed lines (default 220)
#
# The full text is also saved to $FETCH_DOC_DIR (default: system temp dir)
# so you can grep it again without re-downloading. Its path is printed last.
set -euo pipefail

url="${1:?usage: fetch_doc.sh <url> [start_regex] [max_lines]}"
start="${2:-}"
max="${3:-220}"
dir="${FETCH_DOC_DIR:-${TMPDIR:-/tmp}/cast-docs}"
mkdir -p "$dir"
name="$(echo "$url" | sed -E 's#https?://##; s#[^A-Za-z0-9]+#_#g').txt"
html="$dir/$name.html"
txt="$dir/$name"

code=$(curl -sL -m 60 -A "Mozilla/5.0" -o "$html" -w '%{http_code}' "$url") || {
  echo "ERROR: could not download $url" >&2; exit 2; }
if [ "$code" != "200" ]; then
  echo "ERROR: $url returned HTTP $code - the page may have moved. Check the docs site navigation." >&2
  exit 3
fi

sed -E 's/<script[^>]*>.*<\/script>//g; s/<br *\/?>/\n/g; s/<\/(p|div|li|tr|h[1-6]|pre)>/\n/g; s/<[^>]+>//g' "$html" \
  | sed -E 's/&gt;/>/g; s/&lt;/</g; s/&amp;/\&/g; s/&nbsp;/ /g; s/&thinsp;/ /g; s/&#39;|&rsquo;|&lsquo;/'"'"'/g; s/&quot;|&#34;|&ldquo;|&rdquo;/"/g' \
  | grep -v '^[[:space:]]*$' > "$txt"

if [ -n "$start" ]; then
  n=$(grep -nE "$start" "$txt" | tail -1 | cut -d: -f1 || true)
  if [ -z "${n:-}" ]; then
    echo "NOTE: start pattern '$start' not found; printing from the top." >&2
    n=1
  fi
  sed -n "${n},\$p" "$txt" | head -n "$max"
else
  head -n "$max" "$txt"
fi
echo
echo "[full text saved to: $txt  ($(wc -l < "$txt") lines)]"
