# {PROJECT_NAME} — Projektkontext

{PROJECT_DESCRIPTION}

> **⚠️ Godot-Versions-Check:** Dieses Projekt nutzt **Godot 4.7**. Seit 4.4+ gibt es relevante API-Änderungen. Falls dein Trainingsdatum vor Godot 4.4 liegt oder du die API ab 4.4 nicht sicher kennst: **melde dies strikt zurück und nimm keine Änderungen vor**. Nutze in dem Fall die MCP-Tools `godot-lsp_godot_lsp_diagnostics` und `godot-lsp_godot_lsp_hover`, um API-Signaturen zu prüfen, bevor du Code generierst.
>
> **API-Audit:** Bei API-Unsicherheit, vor Merges oder Session-Ende den Agent `godot-api-audit` laden — er prüft Code gegen Godot-Changelogs (4.4–4.7) und erstellt einen Kompatibilitätsreport, ohne Änderungen vorzunehmen.

## Projektstruktur

```
src/                        ← Godot-Projekt-Root
├── assets/                 ← bearbeitete Assets
├── scenes/                 ← Szenen
├── scripts/                ← GDScript-Dateien
├── addons/                 ← Plugins
└── project.godot
assets/                     ← rohe Assets (unbearbeitet)
docs/                       ← GDD, Spezifikationen
reference/                  ← temporäre Dateien (nicht committed)
```

## Input-Mappings

(Inputs hier dokumentieren)

## Entwicklung

- Tool: Godot 4.7 mit OpenCode
- MCP: `godot-ai` (Editor), `godot-lsp` (Code), `godot-export` (Build)
- Siehe globale Instructions in `~/.config/opencode/`
