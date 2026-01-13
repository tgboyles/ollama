#!/usr/bin/env python3
"""
Mock Weather MCP Server for Testing
Provides a simple get_current_temperature tool for integration testing.
Based on: https://github.com/jonigl/ollama-mcp-bridge/blob/main/mock-weather-mcp-server/main.py
"""
from mcp.server.fastmcp import FastMCP
import random

mcp = FastMCP("weather")


@mcp.tool()
async def get_current_temperature(city: str) -> str:
    """Get current temperature for a location.

    Args:
        city: str: The name of the city.
    """
    temperature = random.randint(0, 30)
    return f"The current temperature in {city} is {temperature}°C."


if __name__ == "__main__":
    mcp.run(transport="stdio")
