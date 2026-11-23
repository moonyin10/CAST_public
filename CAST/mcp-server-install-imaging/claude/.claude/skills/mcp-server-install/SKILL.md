---
name: mcp-server-install
description: This skill should be used when the user wants to install, deploy, enable or update the CAST Imaging MCP Server on the Imaging side, or asks which MCP Server version fits their Imaging release. Triggers on phrases like "install the Imaging MCP server", "deploy MCP on Linux / Docker / Windows", "the MCP endpoint returns 503 Unable to find instance for mcpserver", "which MCP version works with Imaging 3.6.x", or "update the MCP server". Reads the current CAST install guide for the user's OS, matches the MCP version to the Imaging version, operates the target host over SSH, and verifies the result. For connecting Claude Code to an already-working MCP server, use mcp-connection-setup instead.
---

Follow the workflow in [skills/mcp-server-install.md](../../../../skills/mcp-server-install.md).

> Path note: this link resolves inside the asset folder. After you copy `skills/` and `.claude/` into your project root, the workflow is at `skills/mcp-server-install.md` and its helper script is in `skills/scripts/`.
