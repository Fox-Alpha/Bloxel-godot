# GDScript Style Guide

> **⚠️ Godot-Versions-Check:** Dieses Projekt nutzt **Godot 4.7**. Seit 4.4+ gibt es relevante API-Änderungen. Falls dein Trainingsdatum vor Godot 4.4 liegt oder du die API ab 4.4 nicht sicher kennst: **melde dies strikt zurück und nimm keine Änderungen vor**. Nutze in dem Fall die MCP-Tools `godot-lsp_godot_lsp_diagnostics` und `godot-lsp_godot_lsp_hover`, um API-Signaturen zu prüfen, bevor du Code generierst.

Siehe `~/.config/opencode/instructions/communication.md` für Kommunikation.
Siehe `~/.config/opencode/instructions/workflow.md` für Git-Workflow.

## Naming
- `snake_case` für Variablen, Funktionen, Parameter
- `SCREAMING_SNAKE_CASE` für Konstanten, Enums
- `PascalCase` für Klassen, Nodes, Types
- Führender Unterstrich für Private Members
- Signal-Callbacks: `_on_<node>_<signal>()`

## Script-Struktur
Signals → Enums → Constants → @export → Public → Private → @onready → Lifecycle → Public Funcs → Private Funcs → Callbacks

## Typen
Immer statische Typannotationen: `var speed: float = 200.0`

## Nodes
`@onready` für alle Node-Referenzen, nie `$Node` in `_process()`
