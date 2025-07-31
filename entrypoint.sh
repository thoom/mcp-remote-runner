#!/bin/sh

# MCP Remote Runner with Tool Whitelisting Support
# This script wraps mcp-remote and optionally applies tool filtering via mcp guard

show_help() {
    echo "Usage: $0 --url <server_url> --port <port> [OPTIONS]"
    echo ""
    echo "Required Arguments:"
    echo "  --url <server_url>     URL of the MCP server to connect to"
    echo "  --port <port>          Port for mcp-remote to listen on"
    echo ""
    echo "Options:"
    echo "  --tools <patterns>     Comma-separated list of tool patterns to whitelist"
    echo "                         (e.g., 'tools:read_*,tools:search_*')"
    echo "  --list-tools          List all available tools (unfiltered) and exit"
    echo "  --allow-http          Allow HTTP connections (trusted networks only)"
    echo "  --debug               Enable debug logging"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --url https://mcp.example.com/v1/sse --port 3334"
    echo "  $0 --url https://mcp.example.com/v1/sse --port 3334 --tools 'tools:read_*'"
    echo "  $0 --url https://mcp.example.com/v1/sse --port 3334 --tools 'tools:read_*,tools:search_*' --debug"
    echo "  $0 --url https://mcp.example.com/v1/sse --port 3334 --list-tools"
}

# Parse command line arguments
TOOLS=""
MCP_ARGS=""
SERVER_URL=""
PORT=""
LIST_TOOLS=false

while [ $# -gt 0 ]; do
    case $1 in
        --url)
            SERVER_URL="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --tools)
            TOOLS="$2"
            shift 2
            ;;
        --list-tools)
            LIST_TOOLS=true
            shift
            ;;
        --allow-http|--debug)
            MCP_ARGS="$MCP_ARGS $1"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            show_help >&2
            exit 1
            ;;
        *)
            echo "Unexpected argument: $1" >&2
            echo "Use --url and --port for server URL and port" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$SERVER_URL" ] || [ -z "$PORT" ]; then
    echo "Error: --url and --port are required" >&2
    show_help >&2
    exit 1
fi

# Handle list-tools mode
if [ "$LIST_TOOLS" = true ]; then
    echo "Discovering available tools from $SERVER_URL..."
    exec ./list-tools.js $MCP_ARGS "$SERVER_URL" "$PORT"
fi

# Build the command
if [ -n "$TOOLS" ]; then
    # Use our custom filtering tool
    echo "Starting mcp-remote with tool filtering: $TOOLS"
    exec ./filter-tools.js --allow "$TOOLS" -- mcp-remote $MCP_ARGS "$SERVER_URL" "$PORT"
else
    # Use mcp-remote directly
    echo "Starting mcp-remote without tool filtering"
    exec mcp-remote $MCP_ARGS "$SERVER_URL" "$PORT"
fi