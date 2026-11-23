# CAST_public

Personal collection of reusable assets for AI coding assistants (Claude Code).

> These are personal, community-style assets. They are not an official CAST Software product, and
> the CAST documentation they read at run time remains the source of truth.

## CAST

Assets that help you work with CAST Imaging and its MCP server.

| Asset | What it does |
|---|---|
| [`CAST/mcp-connection-setup-imaging`](CAST/mcp-connection-setup-imaging/) | Connect an AI coding assistant to a CAST Imaging MCP server: a generic copy-and-paste prompt for any major harness, plus a Claude Code skill. Keeps your API key out of the chat, writes the MCP configuration, and verifies the connection layer by layer. |
| [`CAST/mcp-server-install-imaging`](CAST/mcp-server-install-imaging/) | Install or update the CAST Imaging MCP Server on the Imaging host (Linux via Docker, or Windows), matching the MCP version to your Imaging release. |

Each asset has its own README (what it does, prerequisites, limitations) and a `PROMPT.md` you can
copy and paste into Claude Code for a one-step setup, with no installation needed.

Both assets follow the same principles: they read the **live** CAST documentation instead of relying on
remembered commands, they keep API keys and passwords out of the chat, and they inspect before they
change anything.
