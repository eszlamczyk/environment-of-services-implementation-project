# Usage

## Overview

`llm-agent` is a CLI tool that sends prompts to an LLM-based agent and interacts with external tools via an MCP (Model Context Protocol) server.

---

## Requirements

- Running MCP server
- Running LLM API

---

## Environment setup

Install dependencies using PDM:

```bash
pdm install
```

---

## Environment variables

Create `.env` file by copying `.env.example` and fill the variables with correct values.

```bash
cp .env.example .env
```

---

## Running the agent

Basic usage:

```bash
pdm run llm-agent "Check app status"
```

---

## How it works

1. The CLI receives your prompt
2. It fetches available tools from the MCP server (MCP_URL) (if needed)
3. The agent decides which tools to use
4. Executes actions and returns a response
