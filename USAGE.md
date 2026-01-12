# Usage Guide

## Getting Started

### 1. Set up your MCP configuration

Copy the example config and customize it:
```bash
cp mcp-config.json.example mcp-config.json
```

Edit `mcp-config.json` to configure your MCP servers. Here are some common examples:

#### Filesystem Server
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/directory"]
    }
  }
}
```

#### Multiple MCP Servers
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

### 2. Build and Run

Using Make:
```bash
make build
make run
```

Or using Docker Compose directly:
```bash
docker-compose up -d
```

### 3. Verify the Setup

Check if Ollama is running:
```bash
curl http://localhost:11434/api/version
```

List available models:
```bash
curl http://localhost:11434/api/tags
```

### 4. Use the Model

Once gemma3 has finished downloading, you can use it:

```bash
# Simple generation
curl http://localhost:11434/api/generate -d '{
  "model": "gemma3",
  "prompt": "Explain quantum computing in simple terms",
  "stream": false
}'
```

```bash
# Chat with streaming
curl http://localhost:11434/api/chat -d '{
  "model": "gemma3",
  "messages": [
    {
      "role": "user",
      "content": "What are the benefits of using MCP?"
    }
  ]
}'
```

## Common Operations

### View Logs
```bash
make logs
# or
docker-compose logs -f
```

### Access Container Shell
```bash
make shell
# or
docker exec -it ollama-mcp-bridge /bin/bash
```

### Restart Container
```bash
make stop
make run
```

### Update the Model
If you want to use a different model, edit `entrypoint.sh` and change:
```bash
curl -X POST http://localhost:11434/api/pull -d '{"name": "gemma3", "stream": false}'
```
to your preferred model (e.g., `llama3`, `mistral`, etc.)

Then rebuild:
```bash
make clean
make build
make run
```

## Troubleshooting

### Container won't start
1. Check logs: `make logs`
2. Verify MCP config syntax: `cat mcp-config.json | python3 -m json.tool`
3. Ensure ports aren't already in use: `lsof -i :11434`

### MCP Bridge not working
1. Verify config file is mounted: `docker exec ollama-mcp-bridge ls -la /app/config/`
2. Check MCP bridge logs in container logs
3. Ensure Node.js is available if using npx-based MCP servers

### Model download is slow
The gemma3 model download happens on first startup and may take time depending on:
- Your internet connection speed
- The model size (gemma3 is several GB)

Monitor progress in the logs: `make logs`

### Using a different model
To use a different model, you can either:
1. Edit `entrypoint.sh` before building
2. Or pull the model manually after starting:
```bash
docker exec ollama-mcp-bridge curl -X POST http://localhost:11434/api/pull -d '{"name": "your-model"}'
```

## Advanced Configuration

### Custom Ollama Data Directory
To persist models across container rebuilds, the docker-compose.yml already includes a volume:
```yaml
volumes:
  - ollama-data:/root/.ollama
```

### Custom MCP Config Path
Set a different config path:
```bash
docker run -e MCP_CONFIG_PATH=/custom/path/config.json ...
```

### Running Without MCP Bridge
If you don't need MCP bridge, simply don't mount the config file. The container will run Ollama without the bridge.

## Resources

- [Ollama Documentation](https://github.com/ollama/ollama)
- [MCP Bridge GitHub](https://github.com/jonigl/ollama-mcp-bridge)
- [Model Context Protocol](https://github.com/modelcontextprotocol)
- [Available MCP Servers](https://github.com/modelcontextprotocol/servers)
