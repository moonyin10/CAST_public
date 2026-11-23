---
name: mcp-connection-setup
description: This skill should be used when the user wants to connect Claude Code to a CAST Imaging MCP server, or to test or troubleshoot that connection. Triggers on phrases like "connect to CAST Imaging MCP", "set up the Imaging MCP server in .mcp.json", "where do I get my Imaging API key", "configure x-api-key / x-user-tenant", "my MCP connection to Imaging fails", or errors such as "Unable to find instance for mcpserver" and HTTP 503 / 401 / 404 from the /mcp endpoint. Collects the Imaging URL, API key and optional tenant without exposing secrets, writes .mcp.json, and verifies each layer of the connection. If the MCP server is not installed on the Imaging side, hand off to the mcp-server-install skill.
---

Follow the workflow in [skills/mcp-connection-setup.md](../../../../skills/mcp-connection-setup.md).

> Path note: this link resolves inside the asset folder. After you copy `skills/` and `.claude/` into your project root, the workflow is at `skills/mcp-connection-setup.md` and its helper scripts are in `skills/scripts/`.
