# Integration Tests

This directory contains integration tests for the Ollama + MCP Bridge container.

## Test Components

### mock-weather-server.py
A simple MCP server that provides a weather tool for testing. Based on the example from the [ollama-mcp-bridge project](https://github.com/jonigl/ollama-mcp-bridge/tree/main/mock-weather-mcp-server).

**Tool provided:**
- `get_current_temperature(city: str)` - Returns a mock temperature for a city

### mcp-config-test.json
Configuration file that tells the MCP bridge to use the mock weather server for testing.

### integration-test.sh
Comprehensive end-to-end integration test that validates:

1. **Docker Build** - Ensures the image builds successfully with the specified model
2. **Container Startup** - Verifies the container starts and runs
3. **Ollama Server** - Checks that Ollama is accessible on port 11434
4. **Model Availability** - Confirms the specified model is pre-loaded
5. **Basic Chat** - Tests simple chat functionality
6. **MCP Bridge** - Validates MCP bridge is running and the weather tool is available

## Running the Tests

### Using Make (Default Model)
```bash
make test
```

### Using Make (Custom Model)
```bash
MODEL_NAME=llama3 make test
```

### Manually (Default Model)
```bash
cd test
./integration-test.sh
```

### Manually (Custom Model)
```bash
cd test
MODEL_NAME=mistral ./integration-test.sh
```

## Test Output

The test provides colored output showing the progress:
- 🟡 Yellow: Test step in progress
- 🟢 Green: Test passed
- 🔴 Red: Test failed

At the end, it displays:
- Summary of all tests
- Container logs for troubleshooting
- Overall pass/fail status

## What the Test Validates

The integration test ensures:
- The Docker image includes all dependencies (Python, ollama-mcp-bridge, specified model)
- Ollama server starts correctly
- The specified model is available immediately (no download time)
- Basic chat functionality works
- MCP bridge successfully starts
- The mock weather MCP server can be configured and used

This provides confidence that the entire stack (Ollama + MCP Bridge + Model) works together correctly.

## Environment Variables

- `MODEL_NAME`: Specifies which model to build and test with (default: `gemma3`)
