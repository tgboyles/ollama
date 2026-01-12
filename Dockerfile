FROM ollama/ollama:latest

# Install Python 3.10+ and pip
RUN apt-get update && \
    apt-get install -y python3 python3-pip curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install ollama-mcp-bridge
RUN pip3 install --upgrade ollama-mcp-bridge --break-system-packages

# Create directory for MCP config
RUN mkdir -p /app/config

# Copy the startup script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose Ollama port
EXPOSE 11434

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
