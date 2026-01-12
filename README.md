# Ollama + MCP Bridge Custom Build

This is a custom container build that combines:
- **Ollama** (latest version)
- **MCP Bridge** (Model Context Protocol Bridge for tool integration)
- **Pre-loaded Model** (gemma3 model automatically downloaded on startup)

## Features

- 🚀 Based on official `ollama/ollama:latest` image
- 🔧 Integrated MCP Bridge for enhanced tool capabilities
- 📦 Automatically preloads the gemma3 model on first run
- 🔌 Easy configuration via mounted config file
- 💾 Persistent model storage via Docker volumes

## Quick Start

### Using Make (Easiest)

```bash
# Build the image
make build

# Run with docker-compose
make run

# View logs
make logs

# Stop the container
make stop
```

### Using Docker Compose (Recommended)

1. Create your MCP configuration file:
```bash
cp mcp-config.json.example mcp-config.json
# Edit mcp-config.json with your MCP servers
```

2. Start the container:
```bash
docker-compose up -d
```

3. Access Ollama API at `http://localhost:11434`

### Using Docker CLI

Build the image:
```bash
docker build -t ollama-mcp-custom .
```

Run the container:
```bash
docker run -d \
  -p 11434:11434 \
  -v $(pwd)/mcp-config.json:/app/config/mcp-config.json:ro \
  -v ollama-data:/root/.ollama \
  --name ollama-mcp-bridge \
  ollama-mcp-custom
```

## Configuration

### MCP Config File

The container expects an MCP configuration file at `/app/config/mcp-config.json`. You should mount your local config file to this path.

Example `mcp-config.json`:
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
    }
  }
}
```

For more MCP server options, see the [MCP documentation](https://github.com/jonigl/ollama-mcp-bridge).

### Environment Variables

- `MCP_CONFIG_PATH`: Path to MCP config file (default: `/app/config/mcp-config.json`)

## Model Preloading

The container automatically pulls the `gemma3` model on startup. This happens in the background and may take a few minutes depending on your connection speed.

To verify the model is loaded:
```bash
curl http://localhost:11434/api/tags
```

## Usage

Once running, you can use the Ollama API as usual:

```bash
# Generate a response
curl http://localhost:11434/api/generate -d '{
  "model": "gemma3",
  "prompt": "Why is the sky blue?"
}'

# Chat with the model
curl http://localhost:11434/api/chat -d '{
  "model": "gemma3",
  "messages": [
    { "role": "user", "content": "Hello!" }
  ]
}'
```

## Troubleshooting

### Container logs
```bash
docker-compose logs -f
```

### MCP Bridge not starting
Ensure your `mcp-config.json` file is properly mounted and has valid JSON syntax.

### Model not loading
Check the container logs to see the model download progress. Large models may take time to download.

## Architecture

The container starts three main processes:
1. **Ollama Server** - The core LLM server
2. **Model Preloader** - Downloads gemma3 in the background
3. **MCP Bridge** - Connects MCP tools to Ollama (if config provided)

## References

- [Ollama](https://ollama.ai/)
- [MCP Bridge](https://github.com/jonigl/ollama-mcp-bridge)
- [MCP Bridge Article](https://medium.com/@jonigl/ollama-mcp-bridge-effortless-tool-integration-e32b55086395)
