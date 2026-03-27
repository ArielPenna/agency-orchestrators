# agency-orchestrators

**122 OpenCode agents** — 8 orchestrators + 114 subagents — organized by agency discipline.

Each orchestrator appears in the OpenCode TAB-switcher and delegates work to specialized subagents on demand. Activate `@engineering`, describe your task, and the orchestrator routes it to the right expert automatically.

---

## Installation

### Method 1 — Recommended (no cloning required)

```bash
curl -fsSL https://raw.githubusercontent.com/ArielPenna/agency-orchestrators/main/install.sh | bash
```

### Method 2 — Clone and run locally

```bash
git clone https://github.com/ArielPenna/agency-orchestrators.git
cd agency-orchestrators
bash install.sh
```

### Method 3 — Manual

Copy the agent files directly:

```bash
cp agents/*.md ~/.config/opencode/agents/
```

---

## Interactive installer

The installer is interactive — it lets you choose which orchestrators (and their subagents) to install. It auto-detects the best available UI:

- **[fzf](https://github.com/junegunn/fzf)** — multi-select TUI (best experience)
- **dialog / whiptail** — checkbox menu fallback
- **Numeric menu** — plain terminal fallback (works everywhere)

All agents install to `~/.config/opencode/agents/` (global — available in every project).

---

## Orchestrators

| Orchestrator | Subagents | Specialty |
|---|:---:|---|
| `@engineering` | 22 | Frontend, backend, mobile, AI/ML, DevOps, architecture |
| `@design` | 8 | UI/UX, brand identity, motion design, design systems |
| `@marketing` | 21 | Content, SEO, social media, growth, paid media |
| `@product` | 5 | Strategy, user research, roadmap, prioritization |
| `@pm` | 6 | Project planning, delivery tracking, team operations |
| `@testing` | 8 | QA, e2e, performance, accessibility, security testing |
| `@gamedev` | 20 | Unity, Unreal, Godot, Roblox, Blender, game design |
| `@specialized` | 24 | Compliance, identity systems, accessibility, MCP tooling |

---

## How it works

OpenCode's TAB-switcher lets you switch between agents mid-conversation. Each orchestrator is a thin coordinator: it receives your request, selects the best subagent for the job, and delegates using `permission.task` — loading **only the relevant subagents** into context, not all 122 at once.

```
@engineering refactor this service to use the repository pattern
```

The engineering orchestrator picks `engineering-backend-developer` and hands off. You stay in one conversation; the routing happens transparently.

---

## Requirements

- [OpenCode](https://opencode.ai) installed and configured
- `bash` — macOS, Linux, or Git Bash on Windows
- `fzf` — optional, recommended for the best installer experience

---

## Uninstall

```bash
rm ~/.config/opencode/agents/{engineering,design,marketing,product,pm,testing,gamedev,specialized}.md
rm ~/.config/opencode/agents/{engineering,design,marketing,product,pm,testing,gamedev,specialized}-*.md
```

---

## Known limitations

- **MCP tool permissions** — due to [OpenCode Issue #16491](https://github.com/sst/opencode/issues/16491), MCP permissions are not inherited by subagents. Workaround: add explicit `permission.mcp` blocks to individual subagent files.
- **Global install only** — agents install to `~/.config/opencode/agents/`. For project-scoped installs, copy manually to `.opencode/agents/` in your project root.
