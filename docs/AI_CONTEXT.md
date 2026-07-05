# AI Context: Bloxel (ai-tetris-deepseek)

## Project
Godot 4.7 Tetris clone (GDScript), multiplayer over LAN, developed with OpenCode + AI.

## Directory Layout
- `scripts/game.gd` — Main game loop, input, collision, scoring, ghost piece, DAS/ARR, round management
- `scripts/lobby.gd` — Multiplayer lobby UI, host/join, name entry, ready state
- `scripts/summary.gd` — Post-game score summary, rematch logic
- `scripts/MultiplayerManager.gd` — ENet peer setup, RPC wrappers, disconnect handling
- `main.tscn` — Scene root, CanvasLayer, sub-viewport composition (game + opponent + HUD)
- `ui/lobby.tscn` / `ui/summary.tscn` — Lobby and summary UI layouts
- `addons/godot_ai/` — Godot-AI MCP editor plugin (do not modify manually)

## MCP Servers
### godot-ai (remote)
- URL: `http://127.0.0.1:8000/mcp`
- Config: `~/.config/opencode/opencode.json`
- Purpose: Scene tree manipulation, node create/set, script attach, project run, screenshots
- Requires: Godot Editor running, godot_ai plugin enabled
- Tool prefix: `godot-ai_*` (e.g. `godot-ai_node_create`, `godot-ai_editor_screenshot`)

### godot-lsp (local)
- Command: `uv run --script ~/.config/opencode/tools/godot-lsp-mcp`
- Config: `~/.config/opencode/opencode.json` (global)
- Purpose: Code diagnostics, symbols, hover info, formatting, linting, changelog generation
- Available tools: `godot_lsp_diagnostics`, `godot_lsp_symbols`, `godot_lsp_hover`, `gdscript_format`, `gdscript_lint`, `generate_changelog`
- LSP tools require Godot Editor on port 6005; format/lint/changelog work standalone
- Tool prefix: `godot-lsp_*`

### godot-export (local)
- Command: `uv run --script ~/.config/opencode/tools/godot-export-mcp`
- Config: `~/.config/opencode/opencode.json` (global)
- Purpose: Headless project builds/exports
- Available tools: `export_build`, `export_generate_config`
- Requires: Godot CLI + export templates; `build_config.json` or inline params
- Tool prefix: `godot-export_*`

## Key Config Files
- `~/.config/opencode/opencode.json` — User-level MCP + model config
- `opencode.json` — Project-level config (currently minimal, schema-only)
- `~/.config/opencode/tools/godot-lsp-mcp` — MCP server script (Python, uv-run)

## LSP Architecture
- Godot LSP listens on TCP port 6005 (configurable via GODOT_LSP_PORT env)
- godot-lsp-mcp connects lazily (only when diagnostics/symbols/hover are called)
- Auto-reconnects on connection loss (up to 60 retries)
- Uses JSON-RPC 2.0 over TCP

## Commands
- `opencode` — Start development session
- `uv run --script ~/.config/opencode/tools/godot-lsp-mcp` — Standalone MCP server start
- `generate_changelog repo_path=<path> output=CHANGELOG.md` — Regenerate changelog

## Git History
- 5 commits: project setup → godot-ai addon → core game → opencode config → docs/changelog/fixes
- No remote configured; commit hashes are local

## Multiplayer Protocol
- ENet, port 21277 default
- Host sends board snapshots; client sends inputs
- RPCs: `_send_board`, `_receive_board`, `_send_game_over`, `_send_ready`, `_request_rematch`

## Common Operations
- Run game: `godot-ai_project_run mode=main`
- Take screenshot: `godot-ai_editor_screenshot source=game`
- Check logs: `godot-ai_logs_read source=game`
- Open scene: `godot-ai_scene_open path=res://main.tscn`
- Create node: `godot-ai_node_create type=Node2D parent_path=/Main name=MyNode`
- Get diagnostics: `godot-lsp_godot_lsp_diagnostics path=scripts/game.gd`
- Format file: `godot-lsp_gdscript_format path=scripts/game.gd`
- Generate changelog: `godot-lsp_generate_changelog`
