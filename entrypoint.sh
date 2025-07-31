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
    echo "  --header <header>     Add custom header (e.g., 'Authorization: Bearer TOKEN')"
    echo "  --allow-http          Allow HTTP connections (trusted networks only)"
    echo "  --debug               Enable debug logging"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --url https://mcp.example.com/v1/sse --port 3334"
    echo "  $0 --url https://mcp.example.com/v1/sse --port 3334 --tools 'tools:read_*'"
    echo "  $0 --url https://mcp.example.com/v1/sse --port 3334 --header 'Authorization: Bearer AUTH_TOKEN'"
    echo "  $0 --url https://mcp.example.com/v1/sse --port 3334 --tools 'tools:read_*,tools:search_*' --debug"
    echo "  $0 --url https://mcp.example.com/v1/sse --port 3334 --list-tools"
}

# Parse command line arguments
TOOLS=""
HEADER=""
SERVER_URL=""
PORT=""
LIST_TOOLS=false
ALLOW_HTTP=false
DEBUG=false

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
        --header)
            HEADER="$2"
            shift 2
            ;;
        --allow-http)
            ALLOW_HTTP=true
            shift
            ;;
        --debug)
            DEBUG=true
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

# Build MCP arguments
MCP_ARGS=""
if [ "$ALLOW_HTTP" = true ]; then
    MCP_ARGS="$MCP_ARGS --allow-http"
fi
if [ "$DEBUG" = true ]; then
    MCP_ARGS="$MCP_ARGS --debug"
fi

# Handle list-tools mode
if [ "$LIST_TOOLS" = true ]; then
    echo "Discovering available tools from $SERVER_URL..." >&2
    if [ -n "$HEADER" ]; then
        if [ -n "$MCP_ARGS" ]; then
            exec ./list-tools.js $MCP_ARGS --header "$HEADER" "$SERVER_URL" "$PORT"
        else
            exec ./list-tools.js --header "$HEADER" "$SERVER_URL" "$PORT"
        fi
    else
        if [ -n "$MCP_ARGS" ]; then
            exec ./list-tools.js $MCP_ARGS "$SERVER_URL" "$PORT"
        else
            exec ./list-tools.js "$SERVER_URL" "$PORT"
        fi
    fi
fi

# Build the command
if [ -n "$TOOLS" ]; then
    # Use our custom filtering tool
    echo "Starting mcp-remote with tool filtering: $TOOLS" >&2
    if [ -n "$HEADER" ]; then
        if [ -n "$MCP_ARGS" ]; then
            exec ./filter-tools.js --allow "$TOOLS" -- mcp-remote $MCP_ARGS --header "$HEADER" "$SERVER_URL" "$PORT"
        else
            exec ./filter-tools.js --allow "$TOOLS" -- mcp-remote --header "$HEADER" "$SERVER_URL" "$PORT"
        fi
    else
        if [ -n "$MCP_ARGS" ]; then
            exec ./filter-tools.js --allow "$TOOLS" -- mcp-remote $MCP_ARGS "$SERVER_URL" "$PORT"
        else
            exec ./filter-tools.js --allow "$TOOLS" -- mcp-remote "$SERVER_URL" "$PORT"
        fi
    fi
else
    # Use mcp-remote directly
    echo "Starting mcp-remote without tool filtering" >&2
    if [ -n "$HEADER" ]; then
        if [ -n "$MCP_ARGS" ]; then
            exec mcp-remote $MCP_ARGS --header "$HEADER" "$SERVER_URL" "$PORT"
        else
            exec mcp-remote --header "$HEADER" "$SERVER_URL" "$PORT"
        fi
    else
        if [ -n "$MCP_ARGS" ]; then
            exec mcp-remote $MCP_ARGS "$SERVER_URL" "$PORT"
        else
            exec mcp-remote "$SERVER_URL" "$PORT"
        fi
    fi
fi