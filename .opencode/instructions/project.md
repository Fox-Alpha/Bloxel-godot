# Bloxel — Projektkontext

Godot 4.7 Tetris-Klon mit 2P-Multiplayer (ENet), entwickelt mit OpenCode + KI-Assistenz.

> **Strukturhinweis:** Das Projekt liegt aktuell flach im Root (scripts/, ui/ etc.).
> Mittelfristig sollte alles in einen `src/`-Unterordner wandern (siehe Skill `new-godot-project`).
> Umbau ist nicht Teil dieser Session.

## Aktuelle Projektstruktur

```
scripts/
  game.gd              — Spiellogik, Input, Kollision, Scoring, Ghost Piece, DAS/ARR
  lobby.gd             — Multiplayer-Lobby UI, Host/Join, Name, Ready
  summary.gd           — Post-Game Score, Rematch
  MultiplayerManager.gd — ENet Peer Setup, RPCs, Disconnect
ui/
  lobby.tscn           — Lobby-Layout
  summary.tscn         — Summary-Layout
main.tscn              — Root-Szene (Node2D), CanvasLayer UI, Overlays
addons/godot_ai/       — MCP-Plugin — nicht manuell bearbeiten
```

## Input-Mappings

| Action | Taste |
|--------|-------|
| move_left / move_right | ← → |
| soft_drop | ↓ |
| hard_drop | Space / Ctrl |
| rotate | ↑ |

## MCP-Server Nutzung

### godot-ai (remote) — Editor-Automation
- URL: `http://127.0.0.1:8000/mcp`
- Scene/Node/Script-Manipulation, Projekt starten, Tests, Screenshots
- Tool-Prefix: `godot-ai_*`

### godot-lsp (local) — Code-Analyse
- Linting: `godot-lsp_gdscript_lint path=scripts/game.gd`
- Formatieren: `godot-lsp_gdscript_format path=scripts/game.gd`
- Diagnostics: `godot-lsp_godot_lsp_diagnostics path=scripts/game.gd`
- Changelog: `godot-lsp_generate_changelog`

### godot-export (local) — Builds
- Build via `build_config.json` oder Inline-Parametern
- Profile: Linux, Windows

## Version Control (Godot-spezifisch)

- `*.uid` — **immer committen!** Werden in `.tscn` referenziert. Fehlende UIDs verursachen Merge-Konflikte durch Neugenerierung.
- `.godot/` — nie committen (lokaler Editor-Cache)
- `*.import` — nie committen (automatisch generiert)
- UIDs statt Pfade in `preload()` verwenden: `preload("uid://abc123")`

## Entwicklungsworkflow

- Scene ändern → `godot-ai_scene_open`, Nodes per `godot-ai_node_create` / `godot-ai_node_set_property`
- Script bearbeiten → direkt via Edit, dann formatieren/linten per LSP-MCP
- Testen → `godot-ai_project_run mode=main`, Logs via `godot-ai_logs_read source=game`

## Export

`godot-export_export_build` nutzt `build_config.json`. Aktuelle Profile:
- Linux (debug)
- Windows (debug)
