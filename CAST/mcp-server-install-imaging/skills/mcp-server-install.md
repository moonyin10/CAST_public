# CAST Imaging - MCP Server Install


This changes a real server (usually shared). Be methodical, narrate each step to the user
("what I am doing / what I found"), read before you change, and **ask before anything that
modifies the machine** unless the user has clearly told you to install.

## Rule 0 - read the live docs, pick the right guide

The docs change per release and there are several guides. Never install from memory.

1. Start at the Docker/Linux page and read it with the script (WebFetch only gives a lossy
   summary of these pages and drops commands):
   ```bash
   bash skills/scripts/fetch_doc.sh \
     https://doc.castsoftware.com/imaging/mcp-server/admin/install-imaging/docker/ "Installation process" 200
   ```
   Also read its **Requirements** and the **compatibility table** (MCP release vs required Imaging
   release). The script prints the path of the saved full text; find the table in it with
   `grep -n -B3 -A14 "Required API version" <saved-file>` (searching by the phrase "CAST Imaging
   compatibility" lands on a later sentence that merely mentions it, not on the table).
2. **Choose the OS guide** from the live site navigation (the "Install Imaging MCP" menu lists
   one page per platform, e.g. Linux via Docker, Microsoft Windows). Ask the user which OS the
   *Imaging* server runs on if not obvious. Fetch the matching page the same way. Do not assume Linux.
3. **Choose the MCP version by the Imaging version** (below). The pages state which MCP release
   needs which Imaging release; the guide for newer MCP versions links to the older-version guide
   ("MCP Server 3.0.x installation ...").
4. Note any sub-pages the procedure links to (API key, HTTPS/OAuth, Gatekeeper, update/uninstall)
   and fetch them if they apply.

If any page cannot be fetched or has moved, say so and navigate from https://doc.castsoftware.com/imaging/.

## Step 1 - inspect the target BEFORE choosing anything (read-only)

Find out, on the Imaging host:
- **Imaging version** (decides the MCP version). On Linux/Docker:
  `docker ps --format '{{.Names}} {{.Image}}'` - the image tags (e.g. `castimaging/gateway:3.6.7`).
  Otherwise ask the admin or read the Imaging UI "About".
- Is an MCP server already there? `docker ps -a | grep -i mcp`, and the `/mcp` response
  (`Unable to find instance for mcpserver` = not installed/registered).
- Docker + Compose present and usable by the SSH user (`docker --version`, `docker compose version`,
  user in the `docker` group), free disk (guide states a minimum), and the MCP port free
  (`ss -ltn | grep :8282` or the 3.1+ ports from the live page).
- Imaging IP/hostname for config (the guide forbids `localhost` for the host settings).
- Control Panel reachable (default port 8098): `curl -s -o /dev/null -w '%{http_code}' http://<host>:8098/`.

### Version match - real example, check it against the live tables
In one case the live page for MCP 3.1.0+ required Imaging >= 3.6.9, while the server ran 3.6.7,
so the 3.0.x guide (MCP 3.0.1-3.0.4 need Imaging >= 3.6.0) was the right one. Installing a
newer MCP than Imaging supports can fail or run unsupported. If no MCP release fits, present the
choices (use the older guide, upgrade Imaging first, or stop) and let the user decide.
**Never use the `latest` package without checking this**; pin the version the table allows.

## Step 2 - operate the server over SSH (user does the password step once)

The Bash tool cannot answer password prompts, so use key login.
1. Check for an existing key: `ls ~/.ssh`. If none: `ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519`
   (no passphrase so a non-interactive session can use it - tell the user plainly this is a
   passwordless key and anyone running as them can use it).
2. Ask the user for the SSH username (do not guess accounts). Then the **user** runs, in their
   own terminal (it asks for the server password once; never ask them to type it into chat):
   `type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh <user>@<host> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"`
   (Linux/macOS: `ssh-copy-id <user>@<host>`).
3. Verify: `ssh -o BatchMode=yes <user>@<host> hostname`.

Practical gotchas learned:
- Passing multi-line scripts through PowerShell quoting breaks. Write a script file and feed it:
  `ssh -o BatchMode=yes <user>@<host> 'bash -s' < script.sh` (write it with LF line endings;
  a UTF-8 BOM or CRLF causes `syntax error near unexpected token do`). Running from the Git Bash
  tool is the most reliable.
- Foreground `sleep` is blocked in the tool; wait with a polling loop that checks a condition.
- Python may be missing on the user's Windows PC; use curl/sed/grep.

## Step 3 - get the Extend API key without seeing it

The installer package is downloaded from CAST Extend with a key (`x-nuget-apikey`), from the
user's Extend profile. Confirm the current location on the live page; the link has been
https://extend.castsoftware.com/#/profile/settings .

Never have the user paste it into chat. They store it on the server themselves:
```
ssh <user>@<host>
read -rs EXTEND_KEY && printf '%s' "$EXTEND_KEY" > ~/.extend_key && chmod 600 ~/.extend_key && unset EXTEND_KEY
wc -c ~/.extend_key        # should be > 0 (a UUID-style key is 36 characters)
```
Use it as `K=$(cat ~/.extend_key)` inside the remote command (never echo it), and **delete it
right after the download** (`shred -u ~/.extend_key`). Tell the user that is what you do.

## Step 4 - follow the guide's steps, adapted from the page you read

Typical shape for Linux/Docker (the **page overrides this list**; names/ports/versions differ by release):
1. **Connectivity check:** `curl -H "x-api-key: <imaging key>" http://<imaging>:8090/rest/ready` returns `true`.
   (Use the Imaging key the user already has; do not print it.)
2. **Download the pinned version:**
   `curl -sL -o pkg.zip "https://extend.castsoftware.com/api/package/download/com.castsoftware.imaging.mcpserver.docker/<VERSION>?platform=linux_x64" -H "x-nuget-apikey: $K" -H "accept: application/octet-stream"`;
   expect HTTP 200 and a real zip; `unzip` into a dedicated folder such as `~/mcp-install`.
3. **Configure** (`config/app.config`, `.env`): required host settings use the Imaging machine's
   real IP/hostname, never `localhost`. Back up the file first (`cp app.config app.config.orig`),
   change only what the guide marks as required, show the user the diff.
4. **Read `run.sh` before running it** and tell the user what it will do (typically: prepare
   `logs/` and `certificates/`, `docker compose up -d` which pulls one image and starts one
   container). Confirm it does not stop or touch existing containers.
5. **Run:** `chmod +x run.sh && ./run.sh --install`.
6. **Verify**, in this order:
   - `docker ps` shows the MCP container healthy/up.
   - `docker logs <container>` shows it registered with the service registry (Eureka) - look for
     "Successfully registered".
   - The Imaging gateway needs up to ~1-2 minutes to see the new service. Poll `/mcp` through the
     gateway until it stops returning 503 (loop with a limit, not one long sleep).
   - Handshake returns 200, `tools/list` returns tools, and a read-only call works (`applications`).
7. **Hand off to `mcp-connection-setup`** to wire up Claude Code and run its check script.

### Windows branch
Fetch the Windows page from the site navigation and follow its steps the same way (installer
package, configuration file, service/command to start it, verification). Use PowerShell remoting or
ask the user to run steps locally if SSH is not available; apply the same secret-handling rules.

## Safety and privacy rules
- Read-only first; announce each change; ask before restarting/stopping anything that existed before.
- Do not touch other containers/projects on the host (shared demo servers run many).
- Secrets: Extend key, Imaging key, Neo4j passwords - never print, never put in chat, files in the
  repo, or memory. Mask in logs. Delete temporary key files.
- Show the user what network exposure the install creates (published ports). The docs warn that
  Docker bypasses ufw/firewalld; recommend restricting the MCP port to the Imaging hosts
  (DOCKER-USER chain or a network firewall) and let an admin do it.
- Do not edit `/opt/...` Imaging service files; the MCP server is a separate compose project.

## Gatekeeper
CAST Gatekeeper's MCP has its **own install guide** (find it in the site navigation, e.g. under
"Install Imaging MCP"/Gatekeeper). `GATEKEEPERMCPSERVER` 503 means it is not installed; it is
optional for browsing applications.

## Troubleshooting
| Symptom | Likely cause |
|---|---|
| `/mcp` 503 `Unable to find instance for mcpserver` right after install | gateway has not refreshed yet - wait/poll up to ~2 min; else the container did not register (check its logs, `HOST_CONTROL_PANEL` value/port) |
| container exits | `docker logs`; wrong host config, port in use, image pull failed |
| MCP up but `applications` fails with 404 | wrong tenant header/domain - retry without tenant or with `default` |
| download not 200 | bad/expired Extend key, wrong package/version name, wrong platform |
| version mismatch warnings | compare `get_mcp_info` output (MCP version vs Imaging API version) with the compatibility table |
