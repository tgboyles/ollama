FROM ollama/ollama:latest

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

# Create directory for MCP config
RUN mkdir -p /app/config

# Copy the startup script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose Ollama port
EXPOSE 11434

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
