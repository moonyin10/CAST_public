# MCP Connection Setup — CAST Imaging

## Executive Summary

Connects an AI coding assistant to a CAST Imaging MCP server in a few guided steps and proves that it works. The asset points the user to the CAST Imaging API key page, collects the Imaging URL and the optional tenant, writes the assistant's MCP configuration without ever putting the key in the chat or in a committed file, and runs a layered check (server reachable → key accepted → MCP handshake) that explains in plain language what is wrong when something fails. It always reads the current CAST documentation before acting, so it keeps working when the docs change. It is for anyone who wants their AI assistant to query CAST Imaging.

The asset can be used in two ways:

- **`PROMPT.md` — generic.** One copy-and-paste prompt that works with any major AI coding harness that supports remote MCP servers (for example Claude Code, GitHub Copilot, Cursor, Gemini CLI, Codex). It makes the assistant read the live documentation for *its own* configuration file, format and approval workflow.
- **`skills/` and `claude/` — Claude Code specific.** An installable skill, slash command and helper scripts written around Claude Code (`.mcp.json`, `${VAR}` expansion, the `/mcp` approval flow).

## CAST Use Case

Other

## Target Users

Application developer, Architect, Tech lead, CAST Imaging administrator

## Benefits

- Setup in minutes, with step-by-step guidance on which page to open and what to click
- The API key stays private: it lives in an environment variable, is never echoed, and is never asked for in the chat
- A layered connection check turns opaque errors (503, 401, 404) into a specific next action
- Always follows the live CAST documentation instead of remembered commands, so it survives doc changes
- Hands off cleanly to the `mcp-server-install-imaging` asset when the MCP server is not installed on the Imaging side

## Asset Status

Demonstration only

## Version

1.0.0

- 1.0.0 — initial release (Claude Code adapter; tested against CAST Imaging 3.6.7 with MCP Server 3.0.4)

## Solution Description

The Claude Code skill (`skills/` and `claude/`) starts by downloading the current text of CAST's "Connect your AI client" page with a helper script (`fetch_doc.sh`; plain `curl` + `sed`, no Python needed). It reads the Claude Code section for the `.mcp.json` shape, header names and test table, and treats the live page as the source of truth over its own examples.

It then collects the inputs: the Imaging URL, an API key (each user has one key, so the skill asks the user to reuse an existing key and only generate a new one if none exists, because a new key invalidates the old one; the live "Generating an API key" page says it is generated from the user's profile and does not give exact menu clicks, so the skill does not invent them), an optional tenant (domain), and which MCP servers to register (`imaging`, optionally `gatekeeper`). The API key is stored in an environment variable (`CAST_API_KEY`) set by the user in their own terminal and referenced from `.mcp.json` as `${CAST_API_KEY}`.

Finally a second helper script (`check_mcp.sh`) verifies the connection layer by layer — `GET /rest/ready`, a REST call with the key, and an MCP `initialize` handshake on `/mcp` and `/mcp/gatekeeper` — and prints a diagnosis for each failure. The key is read from the environment and is never printed.

`PROMPT.md` follows the same steps and the same rules, but is written for any AI coding harness. Instead of assuming Claude Code's `.mcp.json`, it tells the assistant to read the live CAST page and, if needed, the harness's own MCP documentation to find the right project-scoped configuration file and format, the supported secret mechanism, and the harness's approval and reconnect workflow. It carries out the same layered check with `curl` and never assumes that `${CAST_API_KEY}` expansion or a `/mcp` command exists.

## Outputs Produced

- A valid project-scoped MCP configuration that registers the CAST Imaging MCP server(s), with no hardcoded credentials (for Claude Code: `.mcp.json` at the project root; other harnesses use their own documented file and format)
- A connection report: server reachable, key accepted, MCP handshake OK per endpoint, with a diagnosis for anything that fails
- Confirmation that the assistant can call the server (for example "List all applications")

## Workflow

Developer prompt → read live CAST docs → collect Imaging URL / key / optional tenant (secrets only in the user's own terminal) → write the assistant's MCP configuration (Claude Code: `.mcp.json`) → layered connection check → approve and reconnect the server using the assistant's own workflow (Claude Code: `/mcp`) → read-only test call → (if the MCP server is missing) hand off to `mcp-server-install-imaging`

## Pre-requisites

- A CAST Imaging deployment reachable from your machine (default gateway port 8090)
- An Imaging API key (generated in the Imaging web UI) — or OAuth, if offered by your Imaging release
- An AI coding assistant that supports remote (HTTP) MCP servers: any major harness for `PROMPT.md`; Claude Code (CLI or VS Code extension) for the bundled skill files (`skills/`, `claude/`)
- `bash`, `curl`, `sed`, `grep` for the Claude Code skill's helper scripts (on Windows: Git Bash); `PROMPT.md` only needs `curl` or an equivalent shell the assistant can use
- The CAST Imaging MCP server installed on the Imaging side (see `mcp-server-install-imaging` if it is not)

## Limitations

- The installable skill, slash command and helper scripts (`skills/`, `claude/`) are **Claude Code specific**. `PROMPT.md` is **generic** (it reads the live CAST documentation for the assistant you use), but it has only been exercised with Claude Code; other harnesses are expected to work but are untested. The CAST documentation describes GitHub Copilot in VS Code, Claude Code and Claude Desktop; adapters for other harnesses are welcome.
- A wrong tenant does not raise a clear error (it appears as a 404 on data calls); omit the tenant if the Imaging has a single domain.
- Setting the API key as a persistent environment variable requires fully closing and reopening VS Code (a running program only reads environment variables when it starts), and the user must reconnect the server in `/mcp`. The skill checks that the variable is visible before running the connection check.
- The skill does not know the exact menu location of the API key in the Imaging UI (the live docs do not give it); it tells the user to open their profile page and to ask their administrator if they cannot find it.
- The OAuth sign-in option is delegated to the live documentation and was not exercised.
- `gatekeeper` is only verified, not installed; it has its own install guide.
- Validated against one environment (CAST Imaging 3.6.7, MCP Server 3.0.4).

**Possible future enhancements**

1. **Guided exploration after setup.** Once the connection is confirmed, offer example prompts and short usage guidance so the user can discover what the CAST Imaging MCP can do (for example listing applications, transactions and data graphs, reviewing quality insights, or exploring dependencies), drawing on the example queries in the live CAST documentation.
2. **Tenant configuration guide.** Explain what a tenant (domain) is, when the `x-user-tenant` header is needed (more than one domain, or domain mapping enabled), how to find the right domain name, how to set it (`CAST_TENANT`), and how to recognize a wrong value (a 404 on data calls, or empty answers).

## Assets / Package Contents

`PROMPT.md` is generic and works with any major AI coding harness. Everything else in this folder (`skills/`, `claude/`) is specific to Claude Code.

| Path | Scope | Description |
|------|-------|-------------|
| `PROMPT.md` | **Generic** — any major AI coding harness | Copy-and-paste quick-start prompt. Runs the full workflow in one paste, with no files to install. It makes the assistant read the live CAST docs for its own configuration file, format and approval workflow |
| `skills/mcp-connection-setup.md` | Claude Code specific | Core workflow, written around Claude Code (`.mcp.json`, `${VAR}` expansion, `/mcp`); the Claude skill adapter references this file |
| `skills/scripts/fetch_doc.sh` | Claude Code skill helper | Prints the current text of a documentation page (read the live docs, never a remembered copy) |
| `skills/scripts/check_mcp.sh` | Claude Code skill helper | Layered connection check; reads the key from `CAST_API_KEY`, never prints it |
| `claude/` | Claude Code specific | Claude Code adapter (slash command `/mcp-connection-setup` and skill) — copy the contents of `claude/` **and** the `skills/` folder into your project root |
