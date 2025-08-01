# MCP Remote Runner

This repository provides a Dockerized environment for running `mcp-remote`, the command-line tool for securely connecting to a Model Context Protocol server.

Using Docker provides a consistent, isolated environment for the tool without needing to install Node.js or `mcp-remote` directly on your host machine.

## Prerequisites

- Docker must be installed and running on your system.

## Usage

### 1. Pull the Docker Image

The recommended way to get the image is to pull it directly from the GitHub Container Registry (GHCR).

```bash
docker pull ghcr.io/thoom/mcp-remote-runner:latest
```

### 2. Run the Container

The general command structure is:

```bash
docker run -i --rm \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner --url <server_url> [OPTIONS]
```

**Command Arguments Explained:**

- `-i`: Runs the container in interactive mode, which is necessary for `mcp-remote`.
- `--rm`: Automatically removes the container when it exits.
- `-v ~/.mcp-auth:/home/node/.mcp-auth`: Persists authentication credentials by mounting a local directory into the container.
- `ghcr.io/thoom/mcp-remote-runner`: The name of the Docker image.
- `--url <server_url>`: The URL of the MCP server you want to connect to.
- `[OPTIONS]`: Optional flags (see sections below).

### Tool Whitelisting

You can now restrict which MCP tools are available by using the `--tools` option. This is useful when MCP hosts only allow a small set of tools, giving you control over which tools are enabled rather than allowing the host to randomly choose.

**Available Options:**

- `--tools <patterns>`: Comma-separated list of tool patterns to whitelist (e.g., `'tools:read_*,tools:search_*'`)
- `--list-tools`: List all available tools (unfiltered) and exit - useful for discovering what tools are available before creating a whitelist
- `--allow-http`: Allow HTTP connections (trusted networks only)  
- `--debug`: Enable debug logging
- `--help`: Show help message

**Tool Pattern Examples:**

- `tools:read_*` - Allow all file reading operations
- `tools:search_*` - Allow all search operations  
- `tools:list_*` - Allow all listing operations
- `tools:read_file,tools:search_files` - Allow only specific tools
- `tools:read_*,tools:search_*,tools:list_*` - Allow multiple categories

**Example Usage:**

```bash
# Basic connection without tool filtering
docker run -i --rm \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse

# Discover all available tools first
docker run -i --rm \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse --list-tools

# Only allow file reading and searching tools
docker run -i --rm \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse \
  --tools 'tools:read_*,tools:search_*'

# Allow only specific tools with debug logging
docker run -i --rm \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse \
  --tools 'tools:read_file,tools:list_directory' --debug
```

### 3. Authentication

**For OAuth-enabled MCP servers**, you'll need to complete authentication the first time:

```bash
# Initial OAuth setup (requires port for callback)
docker run -i --rm \
  -p 3334:3334 \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse --port 3334
```

The tool will generate a URL for you to open in your browser to complete the OAuth flow. By mounting the `~/.mcp-auth` directory, your credentials are saved on your host machine.

**After initial setup**, you can omit the port entirely since tokens are cached:

```bash
# All subsequent runs (no port needed)
docker run -i --rm \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse
```

This eliminates port conflicts when using the same MCP server across multiple clients (Claude Code, Claude Desktop, VSCode, Cursor, etc.).

## MCP Client Configuration

#### Claude Desktop / Cursor

For Claude Desktop or Cursor, add to your MCP servers configuration:

```json
{
  "mcpServers": {
    "npx-atlassian": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v", "~/.mcp-auth:/home/node/.mcp-auth",
        "ghcr.io/thoom/mcp-remote-runner",
        "--url", "https://mcp.atlassian.com/v1/sse"
      ]
    },
    "npx-atlassian-readonly": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v", "~/.mcp-auth:/home/node/.mcp-auth",
        "ghcr.io/thoom/mcp-remote-runner",
        "--url", "https://mcp.atlassian.com/v1/sse",
        "--tools", "tools:read_*,tools:search_*,tools:list_*"
      ]
    }
  }
}
```


## Building from Source (Optional)

If you need to modify the image or build it yourself, you can clone this repository and use the `docker build` command.

```bash
# 1. Clone the repository
git clone https://github.com/thoom/mcp-remote-runner.git
cd mcp-remote-runner

# 2. Build the image
docker build -t ghcr.io/thoom/mcp-remote-runner .
``` 