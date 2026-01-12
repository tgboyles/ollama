# Contributing

## Making Changes

### Modifying the Dockerfile

The `Dockerfile` is based on the official `ollama/ollama:latest` image and adds:
1. Python 3.10+ for running ollama-mcp-bridge
2. The ollama-mcp-bridge Python package
3. A custom entrypoint script

If you need to add additional dependencies, add them in the `RUN apt-get install` line.

### Modifying the Entrypoint Script

The `entrypoint.sh` script handles:
1. Starting the Ollama server
2. Waiting for Ollama to be ready
3. Preloading the gemma3 model
4. Starting the MCP bridge (if config exists)

To change the preloaded model, edit line 29:
```bash
curl -X POST http://localhost:11434/api/pull -d '{"name": "your-model", "stream": false}'
```

Available models can be found at: https://ollama.com/library

### Testing Changes

1. Build the image:
```bash
make build
```

2. Run the container:
```bash
make run
```

3. Check logs:
```bash
make logs
```

4. Test the API:
```bash
curl http://localhost:11434/api/version
curl http://localhost:11434/api/tags
```

### Adding New MCP Servers

To use different MCP servers, create or modify `mcp-config.json`:

```json
{
  "mcpServers": {
    "your-server-name": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-name"]
    }
  }
}
```

Popular MCP servers:
- `@modelcontextprotocol/server-filesystem` - File system access
- `@modelcontextprotocol/server-brave-search` - Web search
- `@modelcontextprotocol/server-github` - GitHub integration
- `@modelcontextprotocol/server-slack` - Slack integration

See: https://github.com/modelcontextprotocol/servers

## Project Structure

```
.
├── Dockerfile              # Container image definition
├── docker-compose.yml      # Docker Compose configuration
├── entrypoint.sh          # Container startup script
├── mcp-config.json.example # Example MCP configuration
├── Makefile               # Build and run commands
├── README.md              # Main documentation
├── USAGE.md              # Detailed usage guide
├── CONTRIBUTING.md        # This file
├── .dockerignore         # Files to exclude from Docker build
└── .gitignore           # Files to exclude from git
```

## Common Customizations

### Change the Base Model

Edit `entrypoint.sh` line 29 to use a different model:
- `llama3` - Meta's Llama 3 model
- `mistral` - Mistral AI's model
- `gemma3` - Google's Gemma 3 model (current default)
- `codellama` - Code-focused model

### Add Additional Python Packages

If MCP bridge requires additional Python packages, add them to the Dockerfile:
```dockerfile
RUN pip3 install --upgrade ollama-mcp-bridge your-package-name --break-system-packages
```

### Change Ollama Port

To use a different port:
1. Update `docker-compose.yml` ports section
2. Update `EXPOSE` in Dockerfile
3. Update references to port 11434 in entrypoint.sh

### Add Health Checks

Add to `docker-compose.yml`:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:11434/api/version"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## Development Workflow

1. Make changes to files
2. Test locally: `make clean && make build && make run`
3. Verify functionality: `make logs`
4. Commit changes
5. Push to repository

## Getting Help

- Ollama Issues: https://github.com/ollama/ollama/issues
- MCP Bridge Issues: https://github.com/jonigl/ollama-mcp-bridge/issues
- Model Context Protocol: https://github.com/modelcontextprotocol
