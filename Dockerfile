FROM ollama/ollama:latest

# Build argument for model name (can be overridden at build time)
ARG MODEL_NAME=gemma3

# Install Python 3.10+ and pip
RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create virtual environment and install ollama-mcp-bridge
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install ollama-mcp-bridge

# Add venv to PATH so ollama-mcp-bridge is available
ENV PATH="/opt/venv/bin:$PATH"

# Preload the model at build time
# Start Ollama server, pull the model, then stop the server
RUN ollama serve & \
    OLLAMA_PID=$! && \
    echo "Waiting for Ollama to start..." && \
    while ! curl -s http://localhost:11434/api/version > /dev/null 2>&1; do \
        echo "Waiting for Ollama..." && \
        sleep 2; \
    done && \
    echo "Ollama is ready, pulling ${MODEL_NAME} model..." && \
    ollama pull ${MODEL_NAME} && \
    echo "Model ${MODEL_NAME} pulled successfully!" && \
    echo "Stopping Ollama gracefully..." && \
    kill -TERM $OLLAMA_PID 2>/dev/null || true && \
    sleep 2 && \
    kill -KILL $OLLAMA_PID 2>/dev/null || true && \
    wait $OLLAMA_PID 2>/dev/null || true && \
    echo "Verifying model files exist..." && \
    ls -la /root/.ollama/models/ || echo "Model directory structure:" && \
    find /root/.ollama -type f 2>/dev/null | head -20 || true

# Store the model name as an environment variable for runtime use
ENV PRELOADED_MODEL=${MODEL_NAME}

# Create directory for MCP config
RUN mkdir -p /app/config

# Copy the startup script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose Ollama port
EXPOSE 11434

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
