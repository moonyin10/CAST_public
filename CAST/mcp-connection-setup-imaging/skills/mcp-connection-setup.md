# CAST Imaging - MCP Connection Setup


Goal: a working `imaging` (and optionally `gatekeeper`) MCP connection in Claude Code,
without the API key ever being typed into the chat or committed to a file.

## Rule 0 - read the live docs first, every time

The CAST documentation changes between releases (header names, URLs, supported clients,
OAuth options). Do not rely on memory or on this skill's examples for exact wording.

```bash
bash skills/scripts/fetch_doc.sh \
  https://doc.castsoftware.com/imaging/mcp-server/connect/ "Claude Code" 120
```

- Use this script, not WebFetch: WebFetch returned only a summary of this page (and missed
  the JSON). The script downloads the real page and prints the real text. The second
  argument skips the site menu; the full text path is printed at the end so you can grep it.
- Read the **Claude Code** part: the `.mcp.json` shape, the header names, the CLI form,
  any OAuth option, and the "Test your connection" table.
- If the page returns an error or has moved, say so and look through the docs site
  navigation (https://doc.castsoftware.com/imaging/) for the new location. Never fall back
  to remembered values silently.
- Where this skill and the live page disagree, **the page wins**; tell the user what changed.

## Step 1 - collect the inputs (the user types secrets only into their own terminal)

Ask for the non-secret items with AskUserQuestion / plain questions. Secrets never go in chat.

| Input | Required | Where to get it | How it is handled |
|---|---|---|---|
| **Imaging URL** (e.g. `http://my-server:8090`, or `https://...`) | yes | The address people use to open CAST Imaging in a browser; the MCP path is added to it. Ask the user to copy the browser address up to the port. | Plain text; not secret. Include the port; `:8090` is the default. |
| **API key** | yes (unless OAuth is offered and chosen) | See "Where to click" below | **Secret.** Environment variable only. |
| **Tenant / domain** | optional | Only needed when Imaging has more than one domain. Ask the admin, or check Imaging's domain list. | Plain text. Omit the header if unsure. |
| **Which servers** | yes | `imaging` always; `gatekeeper` only if the admin installed CAST Gatekeeper | Plain choice |

### The API key: reuse the existing one, generate only if there is none
Read the docs link "Generating an API key" (currently `/imaging/administer/manage-access/profile/api-key/`)
and the "Quick start" on the connect page. As of writing they say:
- **Each user has exactly one key.** Generating a new key **instantly invalidates the old one**, and
  every client still using it stops working. So: **ask first whether the user already has a key and
  reuse it.** Only generate a new one if they have none or lost it, and warn them that other tools
  using the old key must be updated.
- The key is generated **from the user's profile** in CAST Imaging, with a **Generate** button, and the
  "Edit your name and email" section on that page must be filled in first or the button stays disabled.

**Be honest about what the page does not say.** The page does not give the exact menu clicks. Do not
invent them. Tell the user: "Open CAST Imaging in your browser, sign in, and open your profile page
(usually your name or avatar at the top of the screen); the API key and the Generate button are
there per the docs. If you cannot find it, ask your Imaging administrator." If the user already has
a key, they can copy it from the same page or from wherever they stored it.
If the live page now gives explicit steps, use those instead.

### Keeping the key private
- Never ask the user to paste the key into the chat, and never echo it. Do not print it in
  command output; mask it (`sed "s/$KEY/<key>/"`) if a tool might show it.
- Have the user store it as an **environment variable** in their own terminal, and reference
  it in `.mcp.json` as `${CAST_API_KEY}` (Claude Code expands `${VAR}` in `headers`).
  - Windows PowerShell (works on 5.1 and 7; saves for the Windows user). Give the user this as
    **one single line** (a two-line version failed in testing because only the second line was run).
    The key is typed hidden and never shown:
    `[Environment]::SetEnvironmentVariable('CAST_API_KEY',[Net.NetworkCredential]::new('',(Read-Host 'Paste your CAST Imaging API key' -AsSecureString)).Password,'User')`
    It prints nothing on success.
  - macOS/Linux: `read -rs CAST_API_KEY; echo "export CAST_API_KEY='$CAST_API_KEY'" >> ~/.profile` then new shell.
  - Optional tenant: same way with `CAST_TENANT`.
- **Confirm it saved, without showing it.** Give the user this to run in PowerShell:
  `$v=[Environment]::GetEnvironmentVariable('CAST_API_KEY','User'); if($v){"SET - $($v.Length) characters"}else{"NOT SET"}`
  (do NOT tell them to print `$env:CAST_API_KEY`: that shows the key on screen). `NOT SET` means the
  command did not run correctly; run it again.
- **A running program only reads environment variables when it starts.** Tell the user to **fully
  close every VS Code window** (check Task Manager for leftover `Code.exe`), reopen the project and
  resume the conversation. Closing one window of several is not enough.
- **Before any check, confirm Claude Code itself can see the variable**, in the session's shell, without
  printing it: `[ -n "$CAST_API_KEY" ] && echo "visible (${#CAST_API_KEY} chars)" || echo "NOT visible"`.
  If not visible, stop and say "restart needed" - do not run the connection check: with an empty key it
  returns 302 and 401, which looks like a wrong key and sends the user down the wrong path.
- If the user insists on a literal key in `.mcp.json`: warn it is plain text, make sure the
  folder is not synced/shared/committed (add `.mcp.json` to `.gitignore`), and never show it back.
- Do not put the key in memory files, notes, or commit messages.

## Step 2 - write `.mcp.json` (project root, not inside `.claude/`)

Use the shape from the **live page**. As of writing it is:

```json
{
  "mcpServers": {
    "imaging": {
      "type": "http",
      "url": "<IMAGING_URL>/mcp",
      "headers": { "x-api-key": "${CAST_API_KEY}", "x-user-tenant": "${CAST_TENANT}" }
    },
    "gatekeeper": {
      "type": "http",
      "url": "<IMAGING_URL>/mcp/gatekeeper",
      "headers": { "x-api-key": "${CAST_API_KEY}", "x-user-tenant": "${CAST_TENANT}" }
    }
  }
}
```

- Drop the `x-user-tenant` line entirely when there is no tenant. If the env var is unset,
  `${CAST_TENANT}` stays unexpanded, so remove the line instead of leaving it blank.
- Only include `gatekeeper` if it is installed (see below).
- The file must be **valid JSON**: no trailing commas (a leftover comma after removing the
  tenant line is the classic mistake).
- If `.mcp.json` already exists, read it first and edit; do not overwrite other servers.
- If the docs offer a CLI form (`claude mcp add --transport http ...`), mention it, but note
  the `claude` command is usually **not on PATH inside the VS Code extension terminal**.

## Step 3 - verify with the layered check

Run it only after confirming the session can see `CAST_API_KEY` (see "Keeping the key private").
The script reads the key from the environment; never pass it as an argument or type it in chat.

```bash
bash skills/scripts/check_mcp.sh http://my-server:8090 [tenant]
```

It tests, in order, and prints a diagnosis for each: server reachable -> key accepted ->
`/mcp` handshake -> `/mcp/gatekeeper` handshake. It never prints the key.

| Result | Meaning | Action |
|---|---|---|
| `/rest/ready` = `true`, applications listed | Imaging and key are fine | continue |
| HTTP 000 / timeout | URL, port, http/https, VPN, firewall | fix the URL |
| 401 / 403 / 302 on the REST call | **first rule out an empty key** (variable not visible to this session: same symptoms), then a wrong or since-regenerated key | confirm `CAST_API_KEY` is visible; if it is, re-copy the key from the user's profile page. Generate a new one only if it is lost, and warn that it invalidates the old one for every client |
| `/mcp` 503 `Unable to find instance for mcpserver` | gateway fine, **MCP server not installed** on that Imaging | run the `mcp-server-install` skill |
| `/mcp/gatekeeper` 503 `...GATEKEEPERMCPSERVER` | Gatekeeper not installed | separate install guide; or remove the entry |
| 404 only when a tenant is sent | tenant (domain) name wrong | omit it or use the real domain name (often `default`) |
| `/mcp` 200 | server side is ready | next step |

Lesson learned: a wrong tenant does not give a clear error; it shows up as 404 on the data
calls. A request with no tenant header works for single-domain installs.

## Step 4 - approve and test inside Claude Code

1. Claude Code asks to approve project MCP servers the first time; or type `/mcp`.
2. In `/mcp` select `imaging` and **reconnect** (a server that failed earlier is not retried
   automatically). Restart the session if needed. Environment variables set after VS Code
   started require restarting VS Code.
3. Test, as the docs say: ask **"List all applications."** Then call `get_mcp_info` for versions.
4. Success = a list of applications. Report the result back, not the key.

## Troubleshooting notes

- `.mcp.json` unreadable -> check JSON syntax first (trailing commas, BOM/blank first line is ok).
- **Stale editor tab.** If the user has an old `.mcp.json` open in the editor (for example one that
  still contains a literal key), saving that tab overwrites the clean file. After rewriting or
  resetting `.mcp.json`, tell the user to close that tab without saving or reload it from disk.
- Works with curl but not in Claude Code -> env var not visible to VS Code (restart it), or the
  server was not reconnected in `/mcp`.
- OAuth sign-in (Imaging 3.6.6+/some versions) is described on the live page; if the user
  prefers it, follow the page: remove the `x-api-key` header and authenticate via `/mcp`.
- Never run destructive or write tools (tagging, post-its, views) as a "test"; use read-only
  calls like `applications`, `stats`, `get_mcp_info`.
