# Quick start — copy and paste

Use this when you want your AI coding assistant (Claude Code, GitHub Copilot, Cursor, Gemini CLI, Codex, or another harness that supports remote MCP servers) to connect to your CAST Imaging MCP server, and you have not installed the asset's skill files. If you did install them, just say *"connect to my CAST Imaging MCP server"* — the prompt below is the same workflow in a single paste.

The prompt does not assume any one harness. It makes the assistant read the live CAST documentation for **your** harness (configuration file, format, header names, how to approve and reconnect), because those differ from one harness to the next. CAST's page documents GitHub Copilot in VS Code, Claude Code and Claude Desktop; for other harnesses the assistant falls back to that harness's own MCP documentation.

**How to use**

1. Open your AI coding assistant in the project folder where you want the connection to live.
2. Copy everything in the box below and paste it into the chat.
3. Fill in the placeholders, or delete a line and the assistant will ask. You can name your harness, or leave it blank and it will detect it.
4. **Do not paste your API key anywhere in the chat.** The assistant will tell you how to store it yourself, in your own terminal.

```text
Help me connect my active AI coding harness to a CAST Imaging MCP server.

If a skill named "mcp-connection-setup" is available, invoke it and follow it. Otherwise follow the instructions below. Work step by step and tell me what you are doing and what you found at each step.

My details (fill in; leave blank to be asked):
- AI coding harness: <leave blank to detect from the current environment, or ask if unclear>
- Imaging URL: <for example http://my-imaging-server:8090 — the address I open Imaging at, including the port>
- Tenant / domain: <leave blank unless my Imaging has more than one domain>

RULES

1. Read the live CAST documentation first, every time. Do not rely on memory.
   Download https://doc.castsoftware.com/imaging/mcp-server/connect/ yourself with curl and convert it to text. Do not use a summarizing web-fetch for this page: it may omit configuration JSON and commands.
   Read the section for my active harness, including its configuration filename/location, configuration shape, header names, and the "Test your connection" guidance. If the page has moved, look through https://doc.castsoftware.com/imaging/ for the new location.
   Also consult the active harness's official MCP documentation if the CAST page does not document it. Do not assume one config filename or format works for all harnesses. If the docs disagree with these instructions, the live docs win; tell me what changed.

2. Protect my secrets.
   - NEVER ask me to paste my API key into this chat. Never print, echo, log, or write it in clear text to a configuration file.
   - The key is named CAST_API_KEY. Use an environment-variable reference only if the active harness officially supports it; otherwise use its documented secure secret/input mechanism. Never assume `${CAST_API_KEY}` interpolation works in every harness.
   - Give me the exact one-line command for my operating system to enter the key without displaying it. On Windows PowerShell (5.1 or 7), use:
     [Environment]::SetEnvironmentVariable('CAST_API_KEY',[Net.NetworkCredential]::new('',(Read-Host 'Paste your CAST Imaging API key' -AsSecureString)).Password,'User')
     On macOS/Linux, use a hidden prompt and export it in the shell that will launch the harness. Do not write the key in clear text to a shell profile or other file; if persistence for a GUI-launched harness requires another method, use the OS's secure environment/credential mechanism.
   - Give me a command to confirm it was saved without showing it. Windows:
     $v=[Environment]::GetEnvironmentVariable('CAST_API_KEY','User'); if($v){"SET - $($v.Length) characters"}else{"NOT SET"}
     macOS/Linux: [ -n "$CAST_API_KEY" ] && echo "SET (${#CAST_API_KEY} characters)" || echo "NOT SET"
   - A running program only reads environment variables when it starts. Tell me to fully close every instance of the active harness, including leftover processes, then reopen this project and resume the conversation. For VS Code, specifically mention all windows and leftover Code.exe processes in Task Manager.
   - Before running any connection check, confirm THIS session can see CAST_API_KEY without displaying it. Use the OS-appropriate presence/length check. If it is not visible, stop and tell me a restart is needed. Never run a check with an empty key.
   - If I insist on putting a literal key in a config file, warn me it is plain text and offer a secure alternative. Do not write it unless I explicitly insist; if I do, ensure the file is excluded from sharing/commits and never show the key back.
   - Mask any command output that could contain the key.

3. API key handling:
   First ask whether I already have a key. If so, reuse it: each user has only one key, and generating another immediately invalidates the existing one for every client using it.
   Only if I have none or lost it, read the live documentation linked as "Generating an API key" and tell me only what it says. Do not invent menu clicks. Warn that generating a new key invalidates the old one. If the live page still says the profile's "Edit your name and email" section must be filled before the Generate button is enabled, include that. If the page gives explicit steps, use those.

4. Ask only for information needed, one question at a time: Imaging URL; tenant only if there is more than one domain; and whether to register Gatekeeper only if it is installed. Do not ask for the API key in chat.

5. Configure the active harness:
   - Use the project-scoped MCP configuration path and format documented for the active harness. Do not assume `.mcp.json` or any other filename is universal.
   - Read the existing config first if it exists. Preserve all unrelated MCP servers and settings; do not replace the whole file.
   - Use the documented remote HTTP MCP format and headers. Use the server name `imaging` where the harness supports server names.
   - Include `x-user-tenant` only when a tenant is needed; otherwise remove that header entirely.
   - Keep the API key in the supported environment/secret mechanism, never as a literal in the config.
   - Validate the file using the correct parser for its format. Show me the resulting config with all secrets masked and environment references visible.
   - If an old config tab may be open in an editor, tell me to close it without saving before using the updated file, so a stale copy cannot overwrite the new config.

6. Verify in layers, using the key from the environment or the harness's secure secret mechanism, never from a command-line argument, and never printing it:
   a. GET <url>/rest/ready should return true.
   b. GET <url>/imaging/apis/rest/applications with the x-api-key header should return a list.
   c. POST <url>/mcp with an MCP "initialize" request should return HTTP 200. Send Content-Type: application/json and Accept: application/json, text/event-stream.
   d. Do the same for <url>/mcp/gatekeeper only if I want Gatekeeper and it is installed.

   Explain each result in plain language:
   - 000/timeout: check URL, port, HTTP vs HTTPS, VPN, and firewall.
   - 401/403/302 on the authenticated REST call: first rule out an empty key (a session that cannot see the variable can produce the same symptoms), then consider a wrong or since-regenerated key. Re-copy it from my profile; generate a new one only if lost, and warn that this invalidates the old one.
   - 503 "Unable to find instance for mcpserver": Imaging is reachable, but that MCP server is not installed there. Stop. Do not install it without my say-so; offer the "mcp-server-install" skill or the repository's install prompt, or suggest asking my Imaging administrator.
   - 404 only when a tenant is sent: the tenant name may be wrong; retry without it or use the real domain name.
   - 503 on /mcp/gatekeeper only: Gatekeeper is not installed; it has its own install guide.
   Never continue testing after a result that the live documentation says requires stopping.

7. Finish using the active harness's documented approval/reconnect workflow; do not assume a `/mcp` command exists. Tell me how to approve the project server, reconnect or restart the harness if a server that failed earlier is not retried automatically, then ask the harness: "List all applications."
   Use only read-only checks/tools such as applications, stats, and get_mcp_info. Never use tools that tag, annotate, or change data.

Begin with step 1 now.
```
