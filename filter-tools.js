#!/usr/bin/env node
/**
 * Simple MCP tool filtering proxy
 * Spawns mcp-remote and filters tool-related messages based on whitelist patterns
 */

const { spawn } = require('child_process');
const readline = require('readline');

function matchesPattern(toolName, patterns) {
    if (!patterns || patterns.length === 0) return true;
    
    return patterns.some(pattern => {
        // Convert pattern to regex (e.g., "tools:read_*" becomes /^tools:read_.*$/)
        const regexPattern = pattern
            .replace(/\*/g, '.*')
            .replace(/\?/g, '.')
            .replace(/\./g, '\\.');
        const regex = new RegExp(`^${regexPattern}$`);
        return regex.test(toolName);
    });
}

function filterMessage(message, allowedTools) {
    try {
        const parsed = JSON.parse(message);
        
        // Filter tools/list response
        if (parsed.result && parsed.result.tools && Array.isArray(parsed.result.tools)) {
            parsed.result.tools = parsed.result.tools.filter(tool => 
                matchesPattern(tool.name, allowedTools)
            );
        }
        
        // Filter individual tool calls
        if (parsed.method === 'tools/call' && parsed.params && parsed.params.name) {
            if (!matchesPattern(parsed.params.name, allowedTools)) {
                return JSON.stringify({
                    jsonrpc: "2.0",
                    id: parsed.id,
                    error: {
                        code: -32601,
                        message: `Tool '${parsed.params.name}' is not allowed by whitelist`
                    }
                });
            }
        }
        
        return JSON.stringify(parsed);
    } catch (e) {
        // If not valid JSON, pass through unchanged
        return message;
    }
}

function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.error('Usage: filter-tools.js --allow "pattern1,pattern2" -- command [args...]');
        process.exit(1);
    }
    
    let allowedTools = [];
    let commandStart = -1;
    
    // Parse arguments
    for (let i = 0; i < args.length; i++) {
        if (args[i] === '--allow' && i + 1 < args.length) {
            allowedTools = args[i + 1].split(',').map(s => s.trim());
            i++; // skip the next argument
        } else if (args[i] === '--') {
            commandStart = i + 1;
            break;
        }
    }
    
    if (commandStart === -1 || commandStart >= args.length) {
        console.error('No command specified after --');
        process.exit(1);
    }
    
    const command = args[commandStart];
    const commandArgs = args.slice(commandStart + 1);
    
    console.log(`Starting ${command} with tool filtering: ${allowedTools.join(', ')}`);
    
    // Spawn the mcp-remote process
    const child = spawn(command, commandArgs, {
        stdio: ['pipe', 'pipe', 'inherit']
    });
    
    // Set up readline interfaces
    const rl_stdin = readline.createInterface({
        input: process.stdin,
        output: child.stdin,
        terminal: false
    });
    
    const rl_stdout = readline.createInterface({
        input: child.stdout,
        terminal: false
    });
    
    // Forward input to child, no filtering needed
    rl_stdin.on('line', (line) => {
        child.stdin.write(line + '\n');
    });
    
    // Filter output from child
    rl_stdout.on('line', (line) => {
        const filtered = filterMessage(line, allowedTools);
        console.log(filtered);
    });
    
    // Handle cleanup
    child.on('close', (code) => {
        process.exit(code);
    });
    
    process.on('SIGINT', () => {
        child.kill('SIGINT');
    });
    
    process.on('SIGTERM', () => {
        child.kill('SIGTERM');
    });
}

main();