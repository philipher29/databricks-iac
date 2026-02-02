# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

claude-iac is an Infrastructure as Code project for configuring Anthropic Claude API credentials. It provides environment variable setup for routing Claude API calls through Portkey AI to Vertex AI.

## Usage

Source the configuration script to load environment variables:

```bash
source claude.sh
```

## Architecture

The project uses a proxy architecture:
- **Portkey AI** (`api.portkey.ai`) serves as the API gateway
- Requests are routed to **Vertex AI** (Google Cloud's Claude hosting)
- Custom headers configure the Portkey provider routing

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | API key for authentication |
| `ANTHROPIC_BASE_URL` | Portkey AI gateway endpoint |
| `ANTHROPIC_CUSTOM_HEADERS` | Portkey routing headers (provider config) |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Default Claude Sonnet 4.5 model ID |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Default Claude Opus 4.5 model ID |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Default Claude Haiku 4.5 model ID |
