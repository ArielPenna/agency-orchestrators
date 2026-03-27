# Agency Orchestrators for OpenCode

A collection of **8 orchestrators + 114 subagents** for [OpenCode](https://opencode.ai), organized by agency discipline.

## Installation

```bash
git clone https://github.com/your-org/agency-orchestrators.git
cd agency-orchestrators
./install.sh
```

Installs all agents to `~/.config/opencode/agents/` (global — available in all projects).

## Orchestrators

| Orchestrator | Subagents | Use for |
|---|---|---|
| `@engineering` | 22 | Frontend, backend, mobile, AI/ML, DevOps |
| `@design` | 8 | UI, UX, brand, motion, design systems |
| `@marketing` | 21 | Content, SEO, social, growth, paid media |
| `@product` | 5 | Strategy, research, roadmap, prioritization |
| `@pm` | 6 | Project planning, delivery, operations |
| `@testing` | 8 | QA, performance, accessibility, e2e |
| `@gamedev` | 20 | Unity, Unreal, Godot, Roblox, Blender |
| `@specialized` | 24 | Compliance, identity, accessibility, MCP |

## Usage

In OpenCode, type `@engineering` (or any orchestrator name) to activate it. The orchestrator will analyze your request and delegate to the most specialized subagent.

**Example:**
```
@engineering build a React form with validation and error handling
```

The engineering orchestrator will delegate to `engineering-frontend-developer` automatically.

## How It Works

Each orchestrator uses `permission.task` to load **only its subagents** into the context window — keeping token usage low even with 122 agents installed.

## Known Limitations

- **MCP permissions**: Due to [OpenCode Issue #16491](https://github.com/sst/opencode/issues/16491), MCP tool permissions are not inherited by subagents. Workaround: add explicit `permission.mcp` blocks to individual subagents if needed.
- **Global install only**: Agents install to `~/.config/opencode/agents/`. For project-specific install, copy manually to `.opencode/agents/`.

## Source

Generated from [agency-agents](https://github.com/your-org/agency-agents) — a collection of 144+ specialized agent system prompts for AI coding tools.
