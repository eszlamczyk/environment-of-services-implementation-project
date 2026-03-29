import json
import os

import click
import requests
from dotenv import load_dotenv

from utils.tools_mapper import ToolsMapper

load_dotenv()


def call_tool(name: str, args: dict) -> dict:
    print(f"[MCP] Calling tool: {name} with args: {args}")

    payload = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": name,
            "arguments": args
        }
    }

    response = requests.post(os.getenv("MCP_URL"), json=payload, timeout=30)
    response.raise_for_status()

    data = response.json()

    if "error" in data:
        raise RuntimeError(f"MCP error: {data['error']}")

    content = data["result"]["content"][0]["text"]

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return {"raw": content}


def call_llm(messages: list[dict], tools: list[dict]) -> dict:
    payload = {
        "model": os.getenv("LLM_MODEL"),
        "messages": messages,
        "tools": tools,
        "stream": False
    }

    response = requests.post(os.getenv("LLM_URL"), json=payload, timeout=60)
    response.raise_for_status()

    data = response.json()
    return data["message"]


def get_tools() -> list[dict]:
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/list"
    }

    response = requests.post(os.getenv("MCP_URL"), json=payload, timeout=30)
    response.raise_for_status()

    data = response.json()

    if "error" in data:
        raise RuntimeError(f"MCP error: {data['error']}")

    tools = data["result"]["tools"]
    return [ToolsMapper.mcp_to_llm(tool) for tool in tools]


def run_agent(user_input: str) -> None:
    messages = [
        {
            "role": "system",
            "content": "You are an Argo CD assistant. Use tools when needed."
        },
        {
            "role": "user",
            "content": user_input
        }
    ]

    tools = get_tools()

    while True:
        response = call_llm(messages, tools)

        tool_calls = response.get("tool_calls", [])
        if tool_calls:
            tool_call = tool_calls[0]
            tool_name = tool_call["function"]["name"]
            args = tool_call["function"]["arguments"]

            if isinstance(args, str):
                args = json.loads(args)

            result = call_tool(tool_name, args)

            messages.append(response)
            messages.append({
                "role": "tool",
                "name": tool_name,
                "content": json.dumps(result)
            })
        else:
            print("\n🤖:", response.get("content", ""))
            break


@click.command()
@click.argument("prompt")
def main(prompt: str) -> None:
    run_agent(prompt)


if __name__ == "__main__":
    main()