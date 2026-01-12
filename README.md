# Ollama + MCP Bridge Custom Build

A custom containerized deployment of Ollama with integrated Model Context Protocol (MCP) bridge and automatic gemma3 model preloading.

## Features

- 🚀 Based on official `ollama/ollama:latest` image
- 🔧 Integrated MCP Bridge for enhanced tool capabilities
- 📦 Automatically preloads the gemma3 model on first run
- 🔌 Easy configuration via mounted config file
- 💾 Persistent model storage via Docker volumes
- 🐍 Python virtual environment for clean package isolation
- ✅ Health checks and error handling

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)
- [Customization](#customization)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [References](#references)

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

### Using Docker Compose

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

### Verify the Setup

Check if Ollama is running:
```bash
curl http://localhost:11434/api/version
```

List available models:
```bash
curl http://localhost:11434/api/tags
```

## Configuration

### MCP Config File

The container expects an MCP configuration file at `/app/config/mcp-config.json`. You should mount your local config file to this path.

#### Filesystem Server Example
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

#### Multiple MCP Servers Example
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

#### Popular MCP Servers

- `@modelcontextprotocol/server-filesystem` - File system access
- `@modelcontextprotocol/server-brave-search` - Web search
- `@modelcontextprotocol/server-github` - GitHub integration
- `@modelcontextprotocol/server-slack` - Slack integration

See: https://github.com/modelcontextprotocol/servers

### Environment Variables

- `MCP_CONFIG_PATH`: Path to MCP config file (default: `/app/config/mcp-config.json`)

### Model Preloading

The container automatically pulls the `gemma3` model on startup synchronously. This may take a few minutes depending on your connection speed.

To verify the model is loaded:
```bash
curl http://localhost:11434/api/tags
```

## Usage Examples

Once the container is running, you can use the Ollama API:

### Simple Generation
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "gemma3",
  "prompt": "Explain quantum computing in simple terms",
  "stream": false
}'
```

### Chat with Streaming
```bash
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

### Non-streaming Chat
```bash
curl http://localhost:11434/api/chat -d '{
  "model": "gemma3",
  "messages": [
    { "role": "user", "content": "Hello!" }
  ],
  "stream": false
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

### Pull Additional Models

After the container is running, you can pull additional models:
```bash
docker exec ollama-mcp-bridge curl -X POST http://localhost:11434/api/pull -d '{"name": "llama3", "stream": false}'
```

## Troubleshooting

### Container Won't Start

1. Check logs: `make logs`
2. Verify MCP config syntax: `cat mcp-config.json | python3 -m json.tool`
3. Ensure ports aren't already in use: `lsof -i :11434`

### MCP Bridge Not Working

1. Verify config file is mounted: `docker exec ollama-mcp-bridge ls -la /app/config/`
2. Check MCP bridge logs in container logs
3. Ensure Node.js is available if using npx-based MCP servers

### Model Download is Slow

The gemma3 model download happens on first startup and may take time depending on:
- Your internet connection speed
- The model size (gemma3 is several GB)

Monitor progress in the logs: `make logs`

### Model Not Loading

Check the container logs to see the model download progress. The container uses synchronous downloading with error handling, so if the download fails, the container will exit with an error.

## Customization

### Change the Preloaded Model

Edit `entrypoint.sh` line 29 to use a different model:
```bash
curl -f -X POST http://localhost:11434/api/pull -d '{"name": "your-model", "stream": false}'
```

Available models:
- `llama3` - Meta's Llama 3 model
- `mistral` - Mistral AI's model
- `gemma3` - Google's Gemma 3 model (current default)
- `codellama` - Code-focused model

See all models at: https://ollama.com/library

Then rebuild:
```bash
make clean
make build
make run
```

### Add Additional Python Packages

If MCP bridge requires additional Python packages, add them to the Dockerfile:
```dockerfile
RUN /opt/venv/bin/pip install your-package-name
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

## Architecture

### Container Build
- **Base**: `ollama/ollama:latest`
- **Python**: 3.10+ in isolated venv at `/opt/venv`
- **MCP Bridge**: Installed via pip
- **Model**: gemma3 preloaded synchronously with `stream: false`

### Startup Sequence

The container starts with the following process:

1. **Ollama Server** starts in the background
2. **Health Check** waits for Ollama to be ready (30 retries × 2s = 60s timeout)
3. **Model Preloader** synchronously downloads gemma3 with error handling
4. **MCP Bridge** starts only if config file is mounted
5. Container keeps running until a process exits

### Error Handling
- Ollama startup failure → exits with error code 1
- Model pull failure → exits with error code 1  
- Missing MCP config → warning only, continues without bridge
- Proper exit status propagation from background processes

## Project Structure

```
.
├── Dockerfile              # Container image definition
├── docker-compose.yml      # Docker Compose configuration
├── entrypoint.sh          # Container startup script
├── mcp-config.json.example # Example MCP configuration
├── Makefile               # Build and run commands
├── README.md              # This file
├── .dockerignore         # Files to exclude from Docker build
└── .gitignore           # Files to exclude from git
```

## Contributing

### Development Workflow

1. Make changes to files
2. Test locally: `make clean && make build && make run`
3. Verify functionality: `make logs`
4. Commit changes
5. Push to repository

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

### Modifying the Dockerfile

The `Dockerfile` is based on the official `ollama/ollama:latest` image and adds:
1. Python 3.10+ for running ollama-mcp-bridge
2. The ollama-mcp-bridge Python package in a virtual environment
3. A custom entrypoint script

If you need to add additional dependencies, add them in the `RUN apt-get install` line.

### Modifying the Entrypoint Script

The `entrypoint.sh` script handles:
1. Starting the Ollama server
2. Waiting for Ollama to be ready
3. Preloading the gemma3 model
4. Starting the MCP bridge (if config exists)

## References

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Ollama Official Site](https://ollama.ai/)
- [MCP Bridge GitHub](https://github.com/jonigl/ollama-mcp-bridge)
- [MCP Bridge Article](https://medium.com/@jonigl/ollama-mcp-bridge-effortless-tool-integration-e32b55086395)
- [Model Context Protocol](https://github.com/modelcontextprotocol)
- [Available MCP Servers](https://github.com/modelcontextprotocol/servers)

## Getting Help

- Ollama Issues: https://github.com/ollama/ollama/issues
- MCP Bridge Issues: https://github.com/jonigl/ollama-mcp-bridge/issues
- Model Context Protocol: https://github.com/modelcontextprotocol
