"""Simple Hello World MCP server with minimal Azure-friendly tooling."""
from __future__ import annotations

from datetime import datetime
import os
from typing import Dict, Any

from mcp.server.fastmcp import FastMCP


app = FastMCP("hello-world-azure")


@app.tool()
async def hello(name: str = "Azure Builder") -> Dict[str, str]:
    """Return a friendly greeting."""

    return {
        "message": f"Hello, {name}! 👋",
        "environment": os.getenv("AZURE_ENV_NAME", "local"),
    }


@app.tool()
async def server_info() -> Dict[str, Any]:
    """Return basic runtime information for troubleshooting."""

    return {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "working_directory": os.getcwd(),
        "python_version": os.sys.version,
        "available_tools": [tool.name for tool in app.list_tools()],
    }


if __name__ == "__main__":
    app.run()
