#!/bin/sh

# MCP Remote Runner with Tool Whitelisting Support
# This script wraps mcp-remote and optionally applies tool filtering via mcp guard

show_help() {
    echo "Usage: $0 --url <server_url> [--port <port>] [OPTIONS]"
    echo ""
    echo "Required Arguments:"
    echo "  --url <server_url>     URL of the MCP server to connect to"
    echo ""
    echo "Options:"
    echo "  --port <port>          Port for mcp-remote to listen on (only needed for callback)"
    echo "  --tools <patterns>     Comma-separated list of tool patterns to whitelist"
    echo "                         (e.g., 'tools:read_*,tools:search_*')"
    echo "  --list-tools          List all available tools (unfiltered) and exit"
    echo "  --header <header>     Add custom header (e.g., 'Authorization: Bearer TOKEN')"
    echo "  --transport <type>    Transport type (e.g., 'sse', 'websocket')"
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
TRANSPORT=""
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
        --transport)
            TRANSPORT="$2"
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
if [ -z "$SERVER_URL" ]; then
    echo "Error: --url is required" >&2
    show_help >&2
    exit 1
fi

# Build MCP arguments
MCP_ARGS=""
if [ "$ALLOW_HTTP" = true ]; then
    if [ -n "$MCP_ARGS" ]; then
        MCP_ARGS="$MCP_ARGS --allow-http"
    else
        MCP_ARGS="--allow-http"
    fi
fi
if [ -n "$TRANSPORT" ]; then
    if [ -n "$MCP_ARGS" ]; then
        MCP_ARGS="$MCP_ARGS --transport $TRANSPORT"
    else
        MCP_ARGS="--transport $TRANSPORT"
    fi
fi
if [ "$DEBUG" = true ]; then
    if [ -n "$MCP_ARGS" ]; then
        MCP_ARGS="$MCP_ARGS --debug"
    else
        MCP_ARGS="--debug"
    fi
fi

# Handle list-tools mode
if [ "$LIST_TOOLS" = true ]; then
    echo "Discovering available tools from $SERVER_URL..." >&2
    CMD_ARGS="$SERVER_URL"
    if [ -n "$PORT" ]; then
        CMD_ARGS="$CMD_ARGS $PORT"
    fi
    
    if [ -n "$HEADER" ]; then
        if [ -n "$MCP_ARGS" ]; then
            exec ./list-tools.js $MCP_ARGS --header "$HEADER" $CMD_ARGS
        else
            exec ./list-tools.js --header "$HEADER" $CMD_ARGS
        fi
    else
        if [ -n "$MCP_ARGS" ]; then
            exec ./list-tools.js $MCP_ARGS $CMD_ARGS
        else
            exec ./list-tools.js $CMD_ARGS
        fi
    fi
fi

# Build the command arguments
CMD_ARGS="$SERVER_URL"
if [ -n "$PORT" ]; then
    CMD_ARGS="$CMD_ARGS $PORT"
fi

# Build the command
if [ -n "$TOOLS" ]; then
    # Use our custom filtering tool
    echo "Starting mcp-remote with tool filtering: $TOOLS" >&2
    if [ -n "$HEADER" ]; then
        if [ -n "$MCP_ARGS" ]; then
            exec ./filter-tools.js --allow "$TOOLS" -- mcp-remote $CMD_ARGS --header "$HEADER" $MCP_ARGS
        else
            exec ./filter-tools.js --allow "$TOOLS" -- mcp-remote $CMD_ARGS --header "$HEADER"
        fi
    else
        if [ -n "$MCP_ARGS" ]; then
            exec ./filter-tools.js --allow "$TOOLS" -- mcp-remote $CMD_ARGS $MCP_ARGS
        else
            exec ./filter-tools.js --allow "$TOOLS" -- mcp-remote $CMD_ARGS
        fi
    fi
else
    # Use mcp-remote directly
    echo "Starting mcp-remote without tool filtering" >&2
    if [ -n "$HEADER" ]; then
        if [ -n "$MCP_ARGS" ]; then
            exec mcp-remote $CMD_ARGS --header "$HEADER" $MCP_ARGS
        else
            exec mcp-remote $CMD_ARGS --header "$HEADER"
        fi
    else
        if [ -n "$MCP_ARGS" ]; then
            exec mcp-remote $CMD_ARGS $MCP_ARGS
        else
            exec mcp-remote $CMD_ARGS
        fi
    fi
fi