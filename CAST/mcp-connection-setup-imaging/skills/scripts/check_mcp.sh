#!/usr/bin/env bash
# check_mcp.sh <imaging_base_url> [tenant]
#
# Layered health check for a CAST Imaging MCP connection. Prints a verdict per
# layer and a plain-language diagnosis. NEVER prints the API key.
#
#   imaging_base_url  e.g. http://my-server:8090   (no trailing /mcp)
#   tenant            optional x-user-tenant value (omit if single domain)
#
# The API key is read from the environment variable CAST_API_KEY (not from an
# argument, so it does not show up in process lists or shell history).
#   Linux/macOS/Git Bash:   export CAST_API_KEY='...'
#   PowerShell:             $env:CAST_API_KEY = '...'
set -uo pipefail

base="${1:?usage: check_mcp.sh <imaging_base_url> [tenant]}"
base="${base%/}"; base="${base%/mcp}"
tenant="${2:-}"
: "${CAST_API_KEY:?CAST_API_KEY is not visible to this shell. If you just saved it, fully close ALL VS Code windows and reopen (a running program only reads environment variables when it starts). See the header of this script for how to set it.}"

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
hdr=(-H "x-api-key: $CAST_API_KEY")
[ -n "$tenant" ] && hdr+=(-H "x-user-tenant: $tenant")
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"check","version":"1"}}}'

get()  { curl -s -m 25 -o "$tmp" -w '%{http_code}' "${hdr[@]}" -H 'Accept: application/json' "$1" 2>/dev/null || echo 000; }
post() { curl -s -m 25 -o "$tmp" -w '%{http_code}' "${hdr[@]}" -H 'Content-Type: application/json' \
           -H 'Accept: application/json, text/event-stream' -X POST -d "$INIT" "$1" 2>/dev/null || echo 000; }
snip() { head -c 220 "$tmp" | tr -d '\n\r'; }
mask() { sed "s/$CAST_API_KEY/<key>/g"; }

echo "Target: $base   tenant: ${tenant:-<none>}   key: set (${#CAST_API_KEY} chars, not shown)"
echo

c=$(get "$base/rest/ready")
echo "1. Imaging reachable   GET /rest/ready                  -> HTTP $c  $(snip | mask)"
if [ "$c" = "000" ]; then
  echo "   DIAGNOSIS: cannot reach the server. Check the URL, port (8090 default), http vs https, VPN/firewall."; exit 1
fi

c=$(get "$base/imaging/apis/rest/applications")
echo "2. API key accepted    GET /imaging/apis/rest/applications -> HTTP $c"
case "$c" in
  200) echo "   OK: key works; applications: $(grep -o '"displayName"' "$tmp" | wc -l | tr -d ' ') found." ;;
  401|403|302) echo "   DIAGNOSIS: key rejected/missing. Regenerate it in Imaging (a new key invalidates the old one)." ;;
  *) echo "   (unexpected HTTP $c: $(snip | mask))" ;;
esac

for ep in mcp mcp/gatekeeper; do
  c=$(post "$base/$ep")
  echo "3. MCP route           POST /$ep -> HTTP $c  $(snip | mask | cut -c1-160)"
  case "$c" in
    200) echo "   OK: MCP handshake succeeded." ;;
    401) echo "   DIAGNOSIS: gateway rejects the key on this route." ;;
    404) echo "   DIAGNOSIS: 404 - with a tenant set, the tenant (domain) name is probably wrong. Retry with no tenant, or 'default'." ;;
    503) if grep -qi 'Unable to find instance' "$tmp"; then
           echo "   DIAGNOSIS: the gateway is fine but the MCP server component is NOT installed/registered on this Imaging."
           echo "              -> use the cast-imaging-mcp-install skill (gatekeeper has its own, separate install)."
         else echo "   DIAGNOSIS: service unavailable; try again in a minute (a fresh install takes ~1 min to register)."; fi ;;
    000) echo "   DIAGNOSIS: timeout / no answer." ;;
  esac
done
