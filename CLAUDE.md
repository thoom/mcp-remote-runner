# MCP Remote Runner

Docker-based wrapper for mcp-remote with tool filtering capabilities.

## Architecture

- **Base**: Node.js 22 Alpine image
- **Main Script**: `entrypoint.sh` - handles argument parsing and execution
- **Tool Filtering**: `filter-tools.js` - optional tool whitelisting via mcp guard
- **Tool Discovery**: `list-tools.js` - discover available tools from MCP servers

## Key Files

- `Dockerfile` - Multi-platform build (linux/amd64, linux/arm64)
- `entrypoint.sh` - Main entry point with argument parsing
- `filter-tools.js` - Tool filtering implementation
- `list-tools.js` - Tool discovery utility

## Common Commands

```bash
# Build Docker image
docker build -t mcp-remote-runner .

# Run with tool filtering
docker run -i --rm \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  mcp-remote-runner \
  --url https://mcp.example.com/v1/sse \
  --tools 'tools:read_*,tools:search_*'

# Run without filtering (port only needed for OAuth callback)
docker run -i --rm \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  mcp-remote-runner \
  --url https://mcp.example.com/v1/sse

# List available tools
docker run --rm \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  mcp-remote-runner \
  --url https://mcp.example.com/v1/sse \
  --list-tools
```

## GitHub Actions Workflow

- **Trigger**: PR labels (bump:major, bump:minor, bump:patch) or manual dispatch
- **Builds**: Multi-platform Docker images (amd64, arm64)
- **Publishes**: Docker Hub and GitHub Container Registry
- **Tags**: Latest + semantic versioning

## Development Notes

- Port parameter is optional (only required for OAuth callbacks)
- OAuth tokens cached in mounted `.mcp-auth` directory
- Tool filtering uses glob patterns for whitelisting
- Always test Docker builds before committing changes

## MCP Client Configuration Example

```json
"npx-atlassian": {
  "command": "docker",
  "args": [
    "run", "-i", "--rm",
    "-v", "~/.mcp-auth:/home/node/.mcp-auth",
    "mcp-remote-runner",
    "--url", "https://mcp.atlassian.com/v1/sse"
  ]
}
```