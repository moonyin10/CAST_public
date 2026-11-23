# MCP Server Install — CAST Imaging

## Executive Summary

Installs (or updates) the CAST Imaging MCP Server on the Imaging side, guided by the current CAST documentation. The asset works out which install guide applies (Linux via Docker or Windows), checks the target's Imaging version against the MCP compatibility table so that the right MCP release is chosen, operates the host over SSH, installs the server, and verifies it end to end. It is aimed at CAST Imaging administrators who see `503 Unable to find instance for mcpserver` or who simply need the MCP server deployed. Secrets such as the CAST Extend download key never pass through the chat.

## CAST Use Case

Other

## Target Users

CAST Imaging administrator, DevOps engineer, Tech lead

## Benefits

- Picks the MCP release that matches the installed Imaging version instead of blindly installing `latest`
- Always follows the live CAST install guide, so it stays correct as the docs and releases change
- Read-only inspection of the target first; every change is announced, and secrets are handled outside the chat
- Verifies the result: container health, service registration, gateway routing, MCP handshake and a read-only data call
- Leaves the rest of the host untouched; the MCP server runs as its own compose project

## Asset Status

Demonstration only

## Version

1.0.0

- 1.0.0 — initial release (Claude Code adapter; Linux via Docker tested with CAST Imaging 3.6.7 and MCP Server 3.0.4)

## Solution Description

The skill downloads and reads the current text of CAST's MCP Server installation page with a helper script (`fetch_doc.sh`), selects the guide for the user's OS from the site navigation, and reads the compatibility table that maps each MCP Server release to the minimum CAST Imaging release. It then inspects the target host read-only: Imaging service image versions, Docker and Compose availability, free disk space, whether the MCP port is free, whether the Control Panel answers, and whether an MCP server is already registered.

Remote work is done over SSH with key login (the user types the host password once, in their own terminal, to install the key). The CAST Extend API key needed to download the installer is saved by the user into a private temporary file on the host, used for the download only, and deleted immediately afterwards. The skill backs up and edits only the configuration values the guide marks as required, reads the installer script before running it and explains what it will do, then runs it.

Verification checks the container, confirms the server registered with the Imaging service registry (Control Panel), waits for the Imaging gateway to start routing `/mcp`, and finally performs an MCP handshake, a tool listing and a read-only call (listing applications).

## Outputs Produced

- A running CAST Imaging MCP Server container (or Windows service) registered with the Imaging gateway
- An install report: Imaging version found, MCP release chosen and why, configuration changes made, verification results
- A hand-off to `mcp-connection-setup-imaging` to connect Claude Code

## Workflow

Developer prompt → read live CAST install docs and compatibility table → read-only inspection of the target (Imaging version, Docker, ports) → choose guide and MCP release → set up SSH key login → user stores Extend key on the host → download pinned release → configure and review installer script → install → verify registration, gateway routing and a read-only MCP call → hand off to `mcp-connection-setup-imaging`

## Pre-requisites

- A CAST Imaging deployment whose version is known (the skill detects it on Linux/Docker)
- A login on the Imaging host with permission to run Docker (Linux), or an administrator account (Windows)
- A CAST Extend account and its API key (https://extend.castsoftware.com — the live page shows where to find it)
- SSH access to the host for the Linux path
- `bash`, `curl`, `ssh` on the machine running the AI assistant (on Windows: Git Bash)
- An AI IDE / coding assistant that can run shell commands (Claude Code)

## Limitations

- Only the Linux via Docker path was exercised; the Windows path points to CAST's Windows guide and was not tested.
- If no MCP release is compatible with the installed Imaging version, the skill stops and asks the user to choose (use an older guide, upgrade Imaging, or stop); it does not upgrade Imaging itself.
- CAST Gatekeeper's MCP server has its own install guide and is not installed by this asset.
- The MCP port is published on the host; restricting it to the Imaging hosts (Docker bypasses `ufw` / `firewalld`) needs a network or firewall administrator and is only recommended, not applied.
- The registry refresh can take one to two minutes after the install before the gateway routes requests.
- Validated against one environment (CAST Imaging 3.6.7, MCP Server 3.0.4).

## Assets / Package Contents

| Path | Description |
|------|-------------|
| `skills/mcp-server-install.md` | Core workflow — provider-agnostic, all providers reference this |
| `PROMPT.md` | Copy-and-paste quick-start prompt — runs the same workflow in one paste, no skill files needed |
| `skills/scripts/fetch_doc.sh` | Prints the current text of a documentation page (read the live docs, never a remembered copy) |
| `claude/` | Claude Code adapter (slash command `/mcp-server-install` and skill) — copy the contents of `claude/` **and** the `skills/` folder into your project root |
