# Quick start — copy and paste

Use this when you want Claude Code to connect to your CAST Imaging MCP server and you have not installed the asset's skill files. If you did install them, just say *"connect Claude Code to my CAST Imaging MCP server"* (or run `/mcp-connection-setup`) — the prompt below is the same workflow in a single paste.

**How to use**

1. Open Claude Code in the folder where you want the connection to live (the project root).
2. Copy everything in the box below and paste it into the chat.
3. Replace the placeholder on the `Imaging URL` line, or delete that line and Claude will ask.
4. **Do not paste your API key anywhere in the chat.** Claude will tell you how to set it in your own terminal.

```text
Help me connect Claude Code to a CAST Imaging MCP server.

If a skill named "mcp-connection-setup" is available, invoke it and follow it. Otherwise follow the instructions below. Work step by step and tell me what you are doing and what you found at each step.

My details (fill in; leave blank to be asked):
- Imaging URL: <for example http://my-imaging-server:8090 — the address I open Imaging at, including the port>
- Tenant / domain: <leave blank unless my Imaging has more than one domain>

RULES

1. Read the live documentation first, every time. Do not rely on memory.
   Download https://doc.castsoftware.com/imaging/mcp-server/connect/ yourself with curl and convert it to text, for example:
   curl -sL <url> | sed -E 's/<script[^>]*>.*<\/script>//g; s/<br *\/?>/\n/g; s/<\/(p|div|li|tr|h[1-6]|pre)>/\n/g; s/<[^>]+>//g' | grep -v '^[[:space:]]*$'
   Do not use a summarizing web-fetch for this page: it drops the JSON and commands. Read the Claude Code section: the .mcp.json shape, the header names, and the "Test your connection" table. If this page and these instructions disagree, the page wins — tell me what changed. If the page has moved, say so and look through https://doc.castsoftware.com/imaging/ for the new location.

2. Protect my secrets.
   - NEVER ask me to paste my API key into this chat. Never print it, echo it, or write it into a file in clear text.
   - The key goes in an environment variable (CAST_API_KEY) that I set in my own terminal. In .mcp.json refer to it as ${CAST_API_KEY}.
   - Give me the exact command for my operating system as ONE single line that asks for the key hidden. On Windows PowerShell (5.1 or 7):
     [Environment]::SetEnvironmentVariable('CAST_API_KEY',[Net.NetworkCredential]::new('',(Read-Host 'Paste your CAST Imaging API key' -AsSecureString)).Password,'User')
     On macOS/Linux: read -rs CAST_API_KEY; echo "export CAST_API_KEY='$CAST_API_KEY'" >> ~/.profile
     It prints nothing when it works.
   - Then give me a command to confirm it saved WITHOUT showing it. Windows: $v=[Environment]::GetEnvironmentVariable('CAST_API_KEY','User'); if($v){"SET - $($v.Length) characters"}else{"NOT SET"}  (never tell me to print the variable itself).
   - A running program only reads environment variables when it starts. Tell me to fully close EVERY VS Code window (check Task Manager for leftover Code.exe), reopen this project and resume the conversation. Closing one window is not enough.
   - Before running any check, confirm YOUR session can see the variable, without printing it: [ -n "$CAST_API_KEY" ] && echo "visible (${#CAST_API_KEY} chars)" || echo "NOT visible". If it is not visible, stop and tell me a restart is needed. Do not run the check without it: an empty key gives 302 and 401, which looks like a wrong key.
   - If I insist on a literal key in .mcp.json, warn me it is plain text, make sure the folder is not shared or committed (add .mcp.json to .gitignore), and never show it back.
   - If a command's output could contain the key, mask it.

3. The API key. First ask whether I already have a key, and if so REUSE it: each user has exactly one key, and generating a new one instantly invalidates the old one for every client that uses it. Only if I have none (or lost it) tell me how to generate one, and warn me about that. Read the docs link "Generating an API key" and tell me only what it actually says: the key is generated from my profile in CAST Imaging with a Generate button, and the "Edit your name and email" section must be filled in first or the button stays disabled. That page does not give exact menu clicks, so do not invent them: say "open CAST Imaging, sign in, open your profile page; if you cannot find the API key there, ask your Imaging administrator." If the live page now gives explicit steps, use those.

4. Ask me only for what you need, one question at a time: the Imaging URL, the optional tenant (only if there is more than one domain), and whether to register the gatekeeper server too (only if it is installed).

5. Write .mcp.json at the project root, using the shape from the live page. Read the file first if it exists and keep any other servers. Remove the x-user-tenant header entirely when there is no tenant. The file must be valid JSON (no trailing commas). Show me the result with the key shown only as ${CAST_API_KEY}. If I might have an old .mcp.json open in my editor, tell me to close that tab without saving: saving a stale tab would overwrite this file (and could put a literal key back).

6. Verify in layers, reading the key from the environment (never from an argument) and never printing it:
   a. GET <url>/rest/ready returns true
   b. GET <url>/imaging/apis/rest/applications with the x-api-key header returns a list
   c. POST <url>/mcp with an MCP "initialize" request (headers Content-Type: application/json, Accept: application/json, text/event-stream) returns HTTP 200
   d. The same for <url>/mcp/gatekeeper, only if I want gatekeeper
   Explain each result in plain language:
   - 000/timeout: URL, port, http vs https, VPN or firewall
   - 401/403/302 on the REST call: first rule out an empty key (the variable not visible to this session gives the same symptoms), then a wrong or since-regenerated key. Re-copy the key from my profile; generate a new one only if it is lost, and warn me it invalidates the old one
   - 503 "Unable to find instance for mcpserver": the Imaging side is fine but the MCP server is NOT installed there. Stop and tell me so. Do not try to install it from here without my say-so — offer the "mcp-server-install" skill or the install prompt from this repo, or suggest I ask my Imaging administrator.
   - 404 only when a tenant is sent: the tenant name is wrong; retry without it or with the real domain name
   - 503 on /mcp/gatekeeper only: gatekeeper is not installed (it has its own install guide)

7. Finish: tell me to approve the project servers and reconnect "imaging" with /mcp (a server that failed earlier is not retried automatically; restart the session if needed), then ask Claude "List all applications." Use only read-only calls (applications, stats, get_mcp_info) as tests — never tools that tag, annotate or change data.

Begin with step 1 now.
```
