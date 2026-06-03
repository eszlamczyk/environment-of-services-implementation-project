class ToolsMapper:
    @staticmethod
    def mcp_to_llm(tool: dict):
        return {
            "type": "function",
            "function": {
                "name": tool["name"],
                "description": tool["description"],
                "parameters": tool["inputSchema"],
            },
        }