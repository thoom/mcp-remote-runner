#!/usr/bin/env node
/**
 * MCP Tool Discovery Script
 * Connects to an MCP server and lists all available tools
 */

const { spawn } = require('child_process');
const { EventEmitter } = require('events');

class MCPToolDiscovery extends EventEmitter {
    constructor() {
        super();
        this.tools = [];
        this.connected = false;
    }

    async discoverTools(mcpArgs) {
        return new Promise((resolve, reject) => {
            console.log('Connecting to MCP server to discover tools...');
            
            // Spawn mcp-remote process
            const child = spawn('mcp-remote', mcpArgs, {
                stdio: ['pipe', 'pipe', 'pipe']
            });

            let buffer = '';
            let toolsDiscovered = false;

            // Handle stdout (MCP protocol messages)
            child.stdout.on('data', (data) => {
                buffer += data.toString();
                const lines = buffer.split('\n');
                buffer = lines.pop() || ''; // Keep incomplete line in buffer

                for (const line of lines) {
                    if (line.trim()) {
                        try {
                            const message = JSON.parse(line);
                            
                            // Look for tools/list response
                            if (message.result && message.result.tools) {
                                this.tools = message.result.tools;
                                toolsDiscovered = true;
                                console.log('\n=== Available Tools ===');
                                this.tools.forEach((tool, index) => {
                                    console.log(`${index + 1}. ${tool.name}`);
                                    if (tool.description) {
                                        console.log(`   Description: ${tool.description}`);
                                    }
                                    console.log('');
                                });
                                
                                child.kill('SIGTERM');
                                resolve(this.tools);
                                return;
                            }
                        } catch (e) {
                            // Ignore non-JSON lines
                        }
                    }
                }
            });

            // Handle stderr (log messages)
            child.stderr.on('data', (data) => {
                const message = data.toString();
                if (message.includes('Connected to remote server') || 
                    message.includes('Proxy established successfully')) {
                    this.connected = true;
                    // Send tools/list request
                    const toolsRequest = {
                        jsonrpc: "2.0",
                        id: 1,
                        method: "tools/list",
                        params: {}
                    };
                    child.stdin.write(JSON.stringify(toolsRequest) + '\n');
                }
            });

            child.on('close', (code) => {
                if (!toolsDiscovered) {
                    if (this.connected) {
                        console.log('Connection established but no tools were discovered.');
                        console.log('The server may not support the tools/list method or may have no tools available.');
                    } else {
                        console.log('Failed to connect to the MCP server.');
                    }
                    resolve([]);
                }
            });

            child.on('error', (error) => {
                console.error('Error spawning mcp-remote:', error);
                reject(error);
            });

            // Timeout after 10 seconds
            setTimeout(() => {
                if (!toolsDiscovered) {
                    console.log('Timeout waiting for tools discovery. Connection may be successful but tools list not available.');
                    child.kill('SIGTERM');
                    resolve([]);
                }
            }, 10000);
        });
    }
}

async function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.error('Usage: list-tools.js [mcp-remote-args...]');
        process.exit(1);
    }

    const discovery = new MCPToolDiscovery();
    
    try {
        const tools = await discovery.discoverTools(args);
        
        if (tools.length === 0) {
            console.log('No tools discovered or server does not support tool enumeration.');
        } else {
            console.log(`\nTotal tools discovered: ${tools.length}`);
            console.log('\nTo filter these tools, use:');
            console.log('--tools "' + tools.map(t => t.name).join(',') + '"');
            console.log('\nOr use patterns like:');
            console.log('--tools "tools:read_*,tools:search_*"');
        }
    } catch (error) {
        console.error('Error during tool discovery:', error.message);
        process.exit(1);
    }
}

main();