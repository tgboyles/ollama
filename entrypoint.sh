#!/bin/bash
set -e

# Default MCP config path
MCP_CONFIG_PATH="${MCP_CONFIG_PATH:-/app/config/mcp-config.json}"

# Start Ollama server in the background
echo "Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to be ready
echo "Waiting for Ollama to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0
while ! curl -s http://localhost:11434/api/version > /dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "ERROR: Ollama failed to start within timeout"
        exit 1
    fi
    echo "Waiting for Ollama... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done
echo "Ollama is ready!"

# Preload the gemma3 model
echo "Preloading gemma3 model..."
curl -X POST http://localhost:11434/api/pull -d '{"name": "gemma3"}' &
PULL_PID=$!

# Start MCP bridge if config exists
if [ -f "$MCP_CONFIG_PATH" ]; then
    echo "Starting ollama-mcp-bridge with config: $MCP_CONFIG_PATH"
    # Wait for the model pull to complete before starting bridge
    wait $PULL_PID
    echo "Model preload initiated. Starting MCP bridge..."
    ollama-mcp-bridge --config "$MCP_CONFIG_PATH" &
    MCP_PID=$!
else
    echo "WARNING: MCP config not found at $MCP_CONFIG_PATH"
    echo "MCP bridge will not be started. You can mount the config file with:"
    echo "  -v /path/to/mcp-config.json:$MCP_CONFIG_PATH"
    wait $PULL_PID
fi

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
