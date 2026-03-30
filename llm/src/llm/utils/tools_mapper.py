class ToolsMapper:
    @staticmethod
    def mcp_to_llm(tool: dict):
        return {
            "name": tool["name"],
            "desctiption": tool["desctiption"],
            "parameters": tool["inputSchema"]
        }