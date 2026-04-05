import json
import os

import click
import requests
from dotenv import load_dotenv, dotenv_values
from openai import OpenAI

from llm.utils.tools_mapper import ToolsMapper

load_dotenv()


def get_openai_client() -> OpenAI:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("Failed to create openai client")
    return OpenAI(api_key=api_key)


def get_required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Env missing: {name}")
    return value


def call_tool(name: str, args: dict) -> dict:
    print(f"[MCP] Calling tool: {name} with args: {args}")

    payload = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": name,
            "arguments": args,
        },
    }

    response = requests.post(get_required_env("MCP_URL"), json=payload, timeout=30)
    response.raise_for_status()

    data = response.json()

    if "error" in data:
        raise RuntimeError(f"MCP error: {data['error']}")

    content = data["result"]["content"][0]["text"]

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return {"raw": content}


def call_llm(messages: list[dict], tools: list[dict] | None = None) -> dict:
    client = get_openai_client()

    kwargs = {
        "model": os.getenv("LLM_MODEL", "gpt-4o-mini"),
        "messages": messages,
    }

    if tools:
        kwargs["tools"] = tools

    response = client.chat.completions.create(**kwargs)

    return response.choices[0].message.model_dump()


def get_tools() -> list[dict]:
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/list",
    }

    response = requests.post(get_required_env("MCP_URL"), json=payload, timeout=30)
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
            "content": "You are an Argo CD assistant. Use tools when needed.",
        },
        {
            "role": "user",
            "content": user_input,
        },
    ]

    # tools = get_tools()  # uncomment when mcp finished
    tools = None

    while True:
        response = call_llm(messages, tools=tools)

        tool_calls = response.get("tool_calls") or []

        if tool_calls:
            tool_call = tool_calls[0]
            tool_name = tool_call["function"]["name"]
            args = tool_call["function"]["arguments"]

            if isinstance(args, str):
                args = json.loads(args)

            result = call_tool(tool_name, args)

            messages.append(response)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call["id"],
                    "content": json.dumps(result),
                }
            )
        else:
            print("\n🤖:", response.get("content", ""))
            break


@click.command()
@click.argument("prompt")
def main(prompt: str) -> None:
    load_dotenv()

    for key, value in dotenv_values().items():
        if value is None or value == "":
            raise ValueError(
                f"Environment variable '{key}' has an invalid value: {value!r}."
            )

    run_agent(prompt)


if __name__ == "__main__":
    main()