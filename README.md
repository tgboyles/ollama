# Ollama + MCP Bridge Custom Build

![Integration Tests](https://github.com/tgboyles/ollama/workflows/Integration%20Tests/badge.svg)
![Deploy to Container Registry](https://github.com/tgboyles/ollama/workflows/Deploy%20to%20Container%20Registry/badge.svg)

A custom containerized deployment of Ollama with integrated Model Context Protocol (MCP) bridge and configurable automatic model preloading (defaults to gemma3).

## Features

- 🚀 Based on official `ollama/ollama:latest` image
- 🔧 Integrated MCP Bridge for enhanced tool capabilities
- 📦 Configurable pre-baked model in the container image (defaults to gemma3, ready instantly on startup)
- 🔌 Easy configuration via mounted config file
- 💾 Persistent model storage via Docker volumes
- 🐍 Python virtual environment for clean package isolation
- ✅ Health checks and error handling

## Why This Project?

This project combines Ollama with the MCP Bridge in a single, easy-to-deploy container to provide a powerful local development environment. Here's why this matters:

### 💰 Cost-Effective Local Development
Running language models locally eliminates API costs associated with cloud-based services. Instead of paying per token or per request, you can develop and test AI-powered applications without worrying about usage bills. This is especially valuable during development when you're iterating frequently.

### ⚡ Performance and Privacy
Local models provide faster response times by eliminating network latency and keep your data private. Your prompts and responses never leave your machine, making this ideal for working with sensitive or proprietary information.

### 🔧 MCP Capabilities
The [Model Context Protocol (MCP)](https://github.com/modelcontextprotocol) enables language models to interact with external tools and data sources. By integrating the [ollama-mcp-bridge](https://github.com/jonigl/ollama-mcp-bridge), this container allows your local Ollama models to leverage the same powerful tool-calling capabilities that cloud services provide.

### 🎯 Commodity Endpoint Compatibility
This setup is designed to feel like using any commodity AI endpoint (like Anthropic's Claude or OpenAI's GPT). The standard Ollama API means you can easily swap between local and cloud models with minimal code changes, giving you flexibility in your development workflow.

### 🙏 Built on Excellent Foundations
We're incredibly grateful to:
- The [Ollama team](https://github.com/ollama/ollama) for creating an amazing local LLM platform that makes running models simple and efficient
- [@jonigl](https://github.com/jonigl) for developing the [ollama-mcp-bridge](https://github.com/jonigl/ollama-mcp-bridge) that seamlessly integrates MCP capabilities with Ollama
- The [Model Context Protocol](https://github.com/modelcontextprotocol) community for defining a standard way for LLMs to interact with tools

This project simply packages these excellent tools together in a convenient, production-ready container that's ready to use out of the box.

## Table of Contents

- [Why This Project?](#why-this-project)
- [Docker Best Practices](#docker-best-practices)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Common Operations](#common-operations)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Customization](#customization)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [References](#references)

## Quick Start

### Using Pre-built Image from GitHub Container Registry

The easiest way to get started is to use the pre-built image from GitHub Container Registry:

```bash
# Pull the latest image
docker pull ghcr.io/tgboyles/ollama-mcp-custom:latest

# Or pull a specific version
docker pull ghcr.io/tgboyles/ollama-mcp-custom:v1.0.0

# Run the container
docker run -d \
  -p 11434:11434 \
  -v $(pwd)/mcp-config.json:/app/config/mcp-config.json:ro \
  -v ollama-data:/root/.ollama \
  --name ollama-mcp-bridge \
  ghcr.io/tgboyles/ollama-mcp-custom:latest
```

### Using Make (Easiest)

```bash
# Build the image with default model (gemma3)
make build

# Build with any model from the Ollama library
make build MODEL_NAME=llama3

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

2. Build and start the container:
```bash
# With default model (gemma3)
docker-compose up -d

# With a specific model
MODEL_NAME=llama3 docker-compose up -d --build
```

3. Access Ollama API at `http://localhost:11434`

### Using Docker CLI

Build the image:
```bash
# With default model (gemma3)
docker build -t ollama-mcp-custom .

# With a specific model
docker build --build-arg MODEL_NAME=llama3 -t ollama-mcp-custom .
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
- `PRELOADED_MODEL`: The model that was pre-loaded at build time (set automatically, default: `gemma3`)

### Model Preloading

The container is fully configurable to pre-install **any model** from the [Ollama library](https://ollama.com/library) during build time for instant availability. By default, `gemma3` is used if no model is specified.

#### Available Models

- `llama3` - Meta's Llama 3 model
- `mistral` - Mistral AI's model
- `gemma3` - Google's Gemma 3 model (default)
- `codellama` - Code-focused model
- `phi3` - Microsoft's Phi-3 model
- `qwen2` - Alibaba's Qwen 2 model

See all models at: https://ollama.com/library

#### Configuring the Preloaded Model

The preloaded model is **entirely configurable**. You can select any model from the Ollama library to pre-load at **build time** using the `MODEL_NAME` build argument:

**Using Make:**
```bash
make build MODEL_NAME=llama3
```

**Using Docker Compose:**
```bash
MODEL_NAME=mistral docker-compose up -d --build
```

**Using Docker CLI:**
```bash
docker build --build-arg MODEL_NAME=phi3 -t ollama-mcp-custom .
```

**Best Practices:**
- Choose models based on your use case (general chat, coding, etc.)
- Larger models provide better quality but require more resources
- Pre-loading the model at build time ensures instant availability
- You can always pull additional models after the container starts

The model is **pre-installed in the container image during build time**. This means:
- No download wait time on first container start
- The model is immediately available when the container starts
- Faster deployment and predictable startup times

To verify the model is available:
```bash
curl http://localhost:11434/api/tags
```

You should see the model you selected at build time listed (defaults to `gemma3` if not specified).

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

### Push to Container Registry

To push the built image to GitHub Container Registry:
```bash
# Login to GitHub Container Registry (requires GitHub token)
docker login ghcr.io -u YOUR_USERNAME

# Push with automatic tag extraction
make push

# Push with a specific version tag
make push TAG=v1.0.0
```

**Note:** Pushing to the registry requires authentication and appropriate permissions.

## Testing

### Integration Tests

A comprehensive integration test suite is included to validate the entire stack (Ollama + MCP Bridge + Model).

**Run tests:**
```bash
# With default model (gemma3)
make test

# With a specific model
make test MODEL_NAME=llama3
```

**What gets tested:**
- Docker image builds successfully
- Container starts and runs properly
- Ollama server is accessible on port 11434
- Preloaded model (defaults to gemma3) is available
- Basic chat functionality works
- MCP bridge starts and runs
- Mock weather MCP server integration (tool calling)

The test uses a mock weather server (based on the [ollama-mcp-bridge example](https://github.com/jonigl/ollama-mcp-bridge/tree/main/mock-weather-mcp-server)) to validate end-to-end functionality.

**Test details:**
See [test/README.md](test/README.md) for more information about the test suite.

### Continuous Integration

The integration tests run automatically on every commit via GitHub Actions:
- Tests run on all pushes to `main` branch and pull requests
- Validates the complete stack on a clean Ubuntu environment
- Test results are visible in the GitHub Actions tab
- Failed builds prevent merging until tests pass

The CI workflow is defined in [`.github/workflows/test.yml`](.github/workflows/test.yml).

### Automated Deployment

The project includes automated deployment to GitHub Container Registry:
- Triggered automatically when a new Git tag is created (e.g., `v1.0.0`)
- Builds the Docker image
- Runs the full integration test suite
- Pushes the image to `ghcr.io/tgboyles/ollama-mcp-custom` with both the tag version and `latest`
- Only deploys if all tests pass

The deployment workflow is defined in [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml).

**To create a new release:**
```bash
git tag v1.0.0
git push origin v1.0.0
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

### Model Not Loading

The preloaded model (defaults to gemma3 if not configured) is pre-installed in the container image, so it should be immediately available. If you don't see it listed, check the container logs for any errors during startup.

## Customization

### Change the Preloaded Model

The preloaded model is **entirely configurable** and is set at **build time** using the `MODEL_NAME` build argument. You can choose any model from the Ollama library. See the [Configuring the Preloaded Model](#configuring-the-preloaded-model) section above for detailed instructions.

Quick example:
```bash
# Build with llama3 instead of gemma3
make build MODEL_NAME=llama3

# Then run the container
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
- **Model**: Configurable model pre-installed during Docker build (defaults to gemma3, baked into the image)

### Startup Sequence

The container starts with the following process:

1. **Ollama Server** starts in the background
2. **Health Check** waits for Ollama to be ready (30 retries × 2s = 60s timeout)
3. **MCP Bridge** starts only if config file is mounted
4. Container keeps running until a process exits

Note: The preloaded model (configurable, defaults to gemma3) is already present in the image, so there's no download step at startup.

### Error Handling
- Ollama startup failure → exits with error code 1  
- Missing MCP config → warning only, continues without bridge
- Proper exit status propagation from background processes
- Model availability verified during build (build fails if model pull fails)

## Project Structure

```
.
├── .github/                 # GitHub configuration
│   ├── workflows/
│   │   └── test.yml         # CI/CD workflow for automated testing
│   └── copilot-instructions.md # Symlink to CLAUDE.md
├── CLAUDE.md                # Docker best practices (REQUIRED READING)
├── Dockerfile                # Container image definition
├── docker-compose.yml        # Docker Compose configuration
├── entrypoint.sh            # Container startup script
├── mcp-config.json.example  # Example MCP configuration
├── Makefile                 # Build and run commands
├── README.md                # This file
├── test/                    # Integration tests
│   ├── integration-test.sh  # Main test script
│   ├── mock-weather-server.py # Mock MCP server for testing
│   ├── mcp-config-test.json # Test MCP configuration
│   └── README.md            # Test documentation
├── .dockerignore           # Files to exclude from Docker build
└── .gitignore             # Files to exclude from git
```

## Docker Best Practices

**Important:** This project follows Docker's official best practices for container builds. 

📖 **Please read [CLAUDE.md](CLAUDE.md) before making any changes to the Dockerfile or build process.**

The CLAUDE.md file contains:
- Comprehensive Docker best practices based on [Docker's official documentation](https://docs.docker.com/build/building/best-practices/)
- Project-specific build guidelines
- Security considerations
- Testing procedures
- Common build commands

Following these guidelines ensures we always create the best possible version of our container.

## Contributing

### Development Workflow

1. **Review [CLAUDE.md](CLAUDE.md)** for Docker best practices
2. Make changes to files
3. Test locally: `make clean && make build && make run`
4. Verify functionality: `make logs`
5. Commit changes
6. Push to repository

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
3. Confirming the preloaded model is available (configurable, defaults to gemma3)
4. Starting the MCP bridge (if config exists)

## References

- [Ollama Official Documentation](https://docs.ollama.com/)
- [Ollama GitHub Repository](https://github.com/ollama/ollama)
- [Ollama Official Site](https://ollama.ai/)
- [MCP Bridge GitHub](https://github.com/jonigl/ollama-mcp-bridge)
- [MCP Bridge Article](https://medium.com/@jonigl/ollama-mcp-bridge-effortless-tool-integration-e32b55086395)
- [Model Context Protocol](https://github.com/modelcontextprotocol)
- [Available MCP Servers](https://github.com/modelcontextprotocol/servers)

## Getting Help

- Ollama Issues: https://github.com/ollama/ollama/issues
- MCP Bridge Issues: https://github.com/jonigl/ollama-mcp-bridge/issues
- Model Context Protocol: https://github.com/modelcontextprotocol
