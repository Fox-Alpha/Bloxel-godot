# Bloxel – Entwicklungshandbuch

## Übersicht

Bloxel ist ein Tetris-Klon in Godot 4.7, entwickelt mit KI-Unterstützung via OpenCode.
Das Projekt nutzt zwei MCP-Server für die Editor- und Code-Integration.

---

## Voraussetzungen

- **Godot 4.7+** installiert
- **OpenCode** CLI installiert
- **uv** (Python package manager, `>=0.5.x`)
- **godot-lsp-bridge** (optional, wenn Godot-LSP über TCP genutzt werden soll)
- **gdscript-formatter** (optional, für Formatierung/Linting)

---

## MCP-Server

### godot-ai (Remote – Editor-Automation)

Stellt Werkzeuge für Scene-/Node-/Script-Manipulation direkt im Godot Editor bereit.

| Tool-Gruppe | Beschreibung |
|---|---|
| `scene_manage` | Scene erstellen, öffnen, speichern |
| `node_create`, `node_set_property` | Nodes erstellen und konfigurieren |
| `script_create`, `script_attach` | Skripte anlegen und zuweisen |
| `project_run`, `test_run` | Spiel starten, Tests ausführen |
| `tilemap_*`, `animation_*`, `material_*` | Tilemaps, Animationen, Materialien |
| `editor_screenshot` | Viewport-Screenshot |

**Konfiguration:** `~/.config/opencode/opencode.json`

```json
"godot-ai": {
  "type": "remote",
  "url": "http://127.0.0.1:8000/mcp",
  "enabled": true
}
```

**Voraussetzung:** Godot Editor muss laufen und das Plugin "Godot AI" muss aktiviert sein.

### godot-lsp (Lokal – Code-Analyse)

Stellt GDScript-Analyse- und Formatierungs-Werkzeuge bereit, die direkt mit Godots
LSP-Server kommunizieren.

| Tool | Beschreibung | Godot nötig? |
|---|---|---|
| `godot_lsp_diagnostics` | Fehler/Warnungen für eine .gd-Datei | Ja |
| `godot_lsp_symbols` | Struktur-Übersicht (Klassen, Funktionen, Variablen) | Ja |
| `godot_lsp_hover` | Typ-Info und Doku an einer Position | Ja |
| `gdscript_format` | GDScript formatieren (gdscript-formatter) | Nein |
| `gdscript_lint` | GDScript auf Stil-Konformität prüfen | Nein |
| `generate_changelog` | CHANGELOG.md aus Git-Historie generieren | Nein |

**Konfiguration:** `~/.config/opencode/opencode.json`

```json
"godot-lsp": {
  "type": "local",
  "command": ["/home/buckdi/.local/bin/uv", "run", "--script",
    "/home/buckdi/.config/opencode/tools/godot-lsp-mcp"],
  "enabled": true,
  "env": {
    "GODOT_LSP_PORT": "6005"
  }
}
```

**Voraussetzung (LSP-Tools):** Godot Editor mit geöffnetem Projekt (Port 6005).
Format/Lint/Changelog funktionieren auch ohne laufenden Editor.

---

## Projekt-Struktur

```
.
├── addons/godot_ai/        # Godot-AI MCP Plugin (Editor-Plugin)
├── scripts/
│   ├── game.gd             # Hauptspiel-Logik (855 Zeilen)
│   ├── lobby.gd            # Menü/Lobby (152 Zeilen)
│   ├── summary.gd          # Zusammenfassungs-Bildschirm (101 Zeilen)
│   └── MultiplayerManager.gd # Netzwerk-Manager (89 Zeilen)
├── ui/
│   ├── lobby.tscn          # Lobby-Szene
│   └── summary.tscn        # Summary-Szene
├── main.tscn               # Hauptszene
├── project.godot           # Godot-Projektdatei
├── opencode.json           # OpenCode-Projekt-Konfiguration
├── CHANGELOG.md            # Versionshistorie
└── docs/
    ├── GUIDE.md            # Dieses Handbuch
    └── AI_CONTEXT.md       # KI-optimierte Projektbeschreibung
```

---

## Entwicklung mit OpenCode

1. **Godot Editor starten** – Projekt öffnen, Godot-AI Addon aktivieren
2. **Godot-AI MCP** startet automatisch mit dem Editor (Plugin auf Port 8000)
3. **OpenCode** im Projektverzeichnis starten:
   ```bash
   opencode
   ```
4. **godot-lsp MCP** wird automatisch von OpenCode gestartet (User-Config)
5. Bei Bedarf: `GODOT_LSP_PORT` auf Godots LSP-Port setzen (Standard 6005)

### Changelog generieren

```bash
# Über OpenCode – Tool-Namen: generate_changelog
# Parameter:
#   repo_path: Pfad zum Git-Repository
#   output:    Ausgabedatei (z.B. CHANGELOG.md)
#   title:     Optionaler Titel
```

---

## Fehlerbehebung

| Problem | Lösung |
|---|---|
| `-32000` beim MCP-Enable | OpenCode neu starten (Config-Cache) |
| godot-lsp: "Not connected" | Godot Editor muss laufen & Projekt geöffnet |
| godot-ai: "Connection refused" | Godot-AI Plugin im Editor aktivieren |
| LSP kein Output | Port prüfen (Godot → Editor → Editor Settings → LSP Port) |

---

## Multiplayer (für Tester)

1. Eine Instanz hostet (Port 21277)
2. Zweite Instanz joined via IP:Port
3. Beide Namen eingeben → Runde startet automatisch
4. Nach Game-Over: Ready drücken für nächste Runde

---

## Lizenz

MIT – siehe `LICENSE` im Projektroot.
