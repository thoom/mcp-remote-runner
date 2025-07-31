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

To run the container, you need to provide a server URL and a port for the application to listen on.

The general command structure is:

```bash
docker run -i --rm \
  -p <port>:<port> \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner --url <server_url> --port <port> [OPTIONS]
```

**Command Arguments Explained:**

- `-i`: Runs the container in interactive mode, which is necessary for `mcp-remote`.
- `--rm`: Automatically removes the container when it exits.
- `-p <port>:<port>`: Exposes the application's port to your local machine. The port number must be the same on both sides of the colon.
- `-v ~/.mcp-auth:/home/node/.mcp-auth`: Persists authentication credentials by mounting a local directory into the container.
- `ghcr.io/thoom/mcp-remote-runner`: The name of the Docker image.
- `--url <server_url>`: The URL of the MCP server you want to connect to.
- `--port <port>`: The port for `mcp-remote` to listen on. This **must match** the port used in the `-p` flag for authentication to work correctly.
- `[OPTIONS]`: Optional flags (see Tool Whitelisting section below).

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
  -p 3334:3334 \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse --port 3334

# Discover all available tools first
docker run -i --rm \
  -p 3334:3334 \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse --port 3334 --list-tools

# Only allow file reading and searching tools
docker run -i --rm \
  -p 3334:3334 \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse --port 3334 \
  --tools 'tools:read_*,tools:search_*'

# Allow only specific tools with debug logging
docker run -i --rm \
  -p 3334:3334 \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner \
  --url https://mcp.atlassian.com/v1/sse --port 3334 \
  --tools 'tools:read_file,tools:list_directory' --debug
```

### 3. Authentication

The first time you run the container, `mcp-remote` will generate a URL for you to open in your browser to complete the OAuth authentication flow.

By mounting the `~/.mcp-auth` directory, your credentials will be saved on your host machine, and subsequent runs of the container will be authenticated automatically.

## Example

Here is a full example of running the container to connect to an Atlassian MCP server on port `3334`.

```bash
docker run -i --rm \
  -p 3334:3334 \
  -v ~/.mcp-auth:/home/node/.mcp-auth \
  ghcr.io/thoom/mcp-remote-runner https://mcp.atlassian.com/v1/sse 3334
```

### Tool Configuration Examples

Here are example configurations for integrating the MCP Remote Runner with different development tools.

---

#### VSCode (`.vscode/tasks.json`)

In VSCode, a convenient way to run the Docker command is by creating a task in your project's `.vscode/tasks.json` file. This makes the runner available through the "Run Task" command palette option.

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run MCP Remote Runner",
      "type": "shell",
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-p", "3334:3334",
        "-v", "~/.mcp-auth:/home/node/.mcp-auth",
        "ghcr.io/thoom/mcp-remote-runner",
        "--url", "https://mcp.atlassian.com/v1/sse",
        "--port", "3334"
      ],
      "isBackground": true
    },
    {
      "label": "Run MCP Remote Runner (Read-only)",
      "type": "shell",
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-p", "3334:3334",
        "-v", "~/.mcp-auth:/home/node/.mcp-auth",
        "ghcr.io/thoom/mcp-remote-runner",
        "--url", "https://mcp.atlassian.com/v1/sse",
        "--port", "3334",
        "--tools", "tools:read_*,tools:search_*,tools:list_*"
      ],
      "isBackground": true
    }
  ]
}
```

---

#### Cursor / Claude Desktop

For Cursor or Claude Desktop, the configuration typically involves defining a runner command in your settings JSON file.

```json
{
  "npx-atlassian": {
    "command": "docker",
    "args": [
      "run",
      "-i",
      "--rm",
      "-p", "3334:3334",
      "-v", "~/.mcp-auth:/home/node/.mcp-auth",
      "ghcr.io/thoom/mcp-remote-runner",
      "--url", "https://mcp.atlassian.com/v1/sse",
      "--port", "3334"
    ]
  },
  "npx-atlassian-readonly": {
    "command": "docker",
    "args": [
      "run",
      "-i",
      "--rm",
      "-p", "3335:3335",
      "-v", "~/.mcp-auth:/home/node/.mcp-auth",
      "ghcr.io/thoom/mcp-remote-runner",
      "--url", "https://mcp.atlassian.com/v1/sse",
      "--port", "3335",
      "--tools", "tools:read_*,tools:search_*,tools:list_*"
    ]
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