# Quick start — copy and paste

Use this when you are a CAST Imaging administrator and want Claude Code to install (or update) the CAST Imaging MCP Server on your Imaging host, without installing the asset's skill files. If you did install them, just say *"install the CAST Imaging MCP server"* (or run `/mcp-server-install`) — the prompt below is the same workflow in a single paste.

This changes a real server. Claude will inspect first, tell you what it intends to do, and ask before changing anything.

**How to use**

1. Open Claude Code on the machine you administer from (a laptop is fine; Claude reaches the host over SSH).
2. Copy everything in the box below and paste it into the chat.
3. Fill in the three placeholders, or delete them and Claude will ask.
4. **Do not paste passwords or keys into the chat.** Claude will tell you where to type them yourself.

```text
Help me install the CAST Imaging MCP Server on my CAST Imaging host.

If a skill named "mcp-server-install" is available, invoke it and follow it. Otherwise follow the instructions below. Work step by step, and at each step tell me what you are doing and what you found.

My details (fill in; leave blank to be asked):
- Imaging host (hostname or IP): <...>
- Operating system of the Imaging host: <Linux (Docker) or Windows>
- SSH username on the host (Linux): <...>

RULES

1. Read the live documentation first, every time. Do not install from memory.
   Download the page yourself with curl and convert it to text, for example:
   curl -sL <url> | sed -E 's/<script[^>]*>.*<\/script>//g; s/<br *\/?>/\n/g; s/<\/(p|div|li|tr|h[1-6]|pre)>/\n/g; s/<[^>]+>//g' | grep -v '^[[:space:]]*$'
   Do not use a summarizing web-fetch for these pages: it drops the commands.
   - Start at https://doc.castsoftware.com/imaging/mcp-server/admin/install-imaging/docker/ and use its navigation menu to find the page that matches my operating system (Linux via Docker, or Microsoft Windows). Read that page's Requirements, the CAST Imaging compatibility table, and the Installation process.
   - If a page cannot be fetched or has moved, say so and navigate from https://doc.castsoftware.com/imaging/. If the page and these instructions disagree, the page wins — tell me what changed.

2. Inspect the target BEFORE choosing anything (read-only):
   - the installed CAST Imaging version (on Linux: the image tags of the running Imaging containers, e.g. `docker ps --format '{{.Names}} {{.Image}}'`)
   - whether an MCP server already exists (running containers named like mcp, and the response of <imaging>:8090/mcp)
   - Docker and Docker Compose present and usable by my SSH user, free disk space, the MCP port free, and the Control Panel (default port 8098) reachable
   Tell me what you found.

3. Match the MCP Server release to my Imaging release using the compatibility table on the live page. The guide for newer MCP releases may require a newer Imaging than I have, and then an older-release guide (linked from the page) applies. NEVER download "latest" without checking; pin the release the table allows. If no MCP release fits, stop and give me the choices (use the older guide, upgrade Imaging first, or stop) — do not upgrade Imaging yourself.

4. SSH access (Linux): you cannot type passwords. Use key login. If I have no key, create one (`ssh-keygen -t ed25519`, no passphrase — tell me plainly that this key has no passphrase). Ask me for the username, then give me the one command that installs the public key on the host; I will run it in my own terminal and type the host password there. Verify with `ssh -o BatchMode=yes <user>@<host> hostname`. Never ask me for the password in the chat.

5. The installer download needs my CAST Extend API key (my profile at https://extend.castsoftware.com — confirm the current location on the live page). Never ask me to paste it into the chat. Give me this to run in my own terminal on the host:
   read -rs EXTEND_KEY && printf '%s' "$EXTEND_KEY" > ~/.extend_key && chmod 600 ~/.extend_key && unset EXTEND_KEY
   Use it only inside the remote download command (never echo it), and delete it right after the download (shred -u ~/.extend_key). Tell me you will do that.

6. Follow the guide's steps as written on the live page, adapted to my values:
   - connectivity check (<imaging>:8090/rest/ready returns true), using my Imaging key from an environment variable, never printed
   - download the pinned release into its own folder and unzip it; confirm the version in the package
   - configuration: use my host's real IP/hostname for the host settings (the guide says localhost is not supported). Back up each config file first, change only what the guide marks as required, and show me the diff
   - READ the installer script (run.sh or equivalent) before running it and tell me what it will do; confirm it does not stop or change other containers
   - run the installation

7. Be careful with the server:
   - Read before you change; announce every change; ask me before stopping, restarting or modifying anything that existed before
   - Do not touch other containers or projects on the host; the MCP server is its own compose project
   - Never print or store secrets (Extend key, Imaging key, database passwords) in the chat, in files in a repository, or in memory. Mask them in output. Remove temporary key files
   - Tell me which port the MCP container publishes and recommend restricting it to the Imaging hosts (Docker bypasses ufw/firewalld; use the DOCKER-USER chain or a network firewall). That needs an administrator; do not change firewall rules yourself
   - Shell tip: foreground `sleep` may be blocked; wait with a polling loop that checks a condition, with a time limit

8. Verify, in this order:
   a. the container is up/healthy (`docker ps`)
   b. its logs show it registered with the Imaging service registry (look for a successful registration message)
   c. poll <imaging>:8090/mcp with an MCP "initialize" request until it stops returning 503 — the gateway can take one to two minutes to see the new service
   d. the handshake returns HTTP 200, the tool list returns tools, and one read-only call works (list applications)
   Report the MCP Server version and the connected Imaging API version (the get_mcp_info tool) and whether they are compatible.

9. CAST Gatekeeper's MCP has its own install guide; if I want it, find it in the docs navigation and treat it as a separate task.

10. Finish by telling me the install worked or what failed, what you changed on the host (files, containers, ports), and what is left for an administrator. Then offer to connect Claude Code to the server using the "mcp-connection-setup" skill or the connect prompt from this repo.

Begin with step 1 now.
```
