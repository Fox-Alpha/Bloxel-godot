---
name: new-godot-project
description: Setup a new Godot project with OpenCode support. Creates repo structure, git, .opencode/, and copies template files. Ask for project name and optional description before running.
---

# New Godot Project — Boilerplate

## Vorbereitung

1. Frage nach dem **Projektnamen** (wird für Ordner, `project.godot`, README etc. verwendet)
2. Frage optional nach einer **Kurzbeschreibung** für `project.md`
3. Frage ob es bereits einen **Remote Host** für das Repository git. Wird in Step 4 für Git Initialisierung benötigt.

## Verzeichnisstruktur

```
{project-name}/
├── .exports/
├── .opencode/{instructions,agents,files}/
├── .submodule/{addons,andere}/
├── assets/{sprites,sounds,fonts}/
├── docs/
├── src/
│   ├── addons/
│   ├── assets/
│   ├── scenes/
│   ├── scripts/
│   ├── project.godot
│   └── icon.svg
├── reference/
├── .gitignore
├── .editorconfig
├── AGENTS.md
├── opencode.json
└── README.md
```

## Ausführung

### 1. Verzeichnisse anlegen

```bash
mkdir -p {project-name}/{src/{assets,scenes,scripts,addons},assets/{sprites,sounds,fonts},docs,reference,.exports,.opencode/{instructions,agents,files},.submodule/{addons,andere}}
```
- Erzeuge in allen Ordnern eine '.GITKEEP' um die Ordner Struktur im Repository zu erzeugen

### 2. Templates kopieren

```bash
TEMPLATES=~/.config/opencode/templates/godot
PROJECT={project-name}

# Godot-Projekt-Konfiguration
cp "$TEMPLATES/project.godot" "$PROJECT/src/project.godot"
# Platzhalter ersetzen
sed -i "s/{PROJECT_NAME}/{project-name}/g" "$PROJECT/src/project.godot"

# Git / Editor
cp "$TEMPLATES/gitignore" "$PROJECT/.gitignore"
cp "$TEMPLATES/editorconfig" "$PROJECT/.editorconfig"

# AI Instructions
cp "$TEMPLATES/gdscript.md" "$PROJECT/.opencode/instructions/gdscript.md"
cp "$TEMPLATES/project.md" "$PROJECT/.opencode/instructions/project.md"
sed -i "s/{PROJECT_NAME}/{project-name}/g" "$PROJECT/.opencode/instructions/project.md"
sed -i "s/{PROJECT_DESCRIPTION}/{project-description}/g" "$PROJECT/.opencode/instructions/project.md"
```
### 2.1 Godot Addons hinzufügen
- Frage den User ob Godot Addons hinzugefügt werden soll. Direkt oder als Submodule
  - Direkt, dann in src/addons/
  - Als SubModule, durch angabe der Repository Adresse in die Git Struktur aufnehmen und im Ordner: '$PROJECT/.submodule/'

### 3. README.md, AGENTS.md, opencode.json

**README.md:**
```markdown
# {project-name}

A Godot 4 project.

## Development

Dieses Projekt wird mit [OpenCode](https://opencode.ai) und KI-Assistenz entwickelt.
```

**AGENTS.md:**
```markdown
# {project-name}

Godot 4 Projekt. Siehe `.opencode/instructions/project.md` für Details.
```

**opencode.json:**
```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "AGENTS.md",
    ".opencode/instructions/gdscript.md",
    ".opencode/instructions/project.md"
  ],
  "permission": {
    "external_directory": {
      "/**": "deny",
      "~/.config/opencode/**": "allow",
      "~/Projekte/Godot/**": "ask"
    },
    "edit": {
      "~/.config/opencode/**": "deny",
      "~/.config/opencode/opencode.json": "ask"
    },
    "glob": {
      "~/.config/opencode/**" : "ask"
    }
  },
  "mcp": {
    "godot-ai": {
      "url": "http://127.0.0.1:8000/mcp",
      "type": "remote",
      "enabled": true
    },
    "ziva-godot": {
      "type": "local",
      "command": [
        "/home/buckdi/.local/share/ziva-local/bin/zivacode",
        "--mcp-bridge",
        "--godot-bin",
        "/home/buckdi/Projekte/Godot/Engine/4.7_stable/Godot_v4.7-stable_linux.x86_64",
        "--upstream",
        "http://localhost:7012/api/mcp"
      ],
      "enabled": true
    },
		"godot-lsp": {
			"type": "local",
			"command": ["~/.local/bin/uv", "run", "--script", "~/.config/opencode/tools/godot-lsp-mcp"],
			"enabled": true,
			"environment": {
				"GODOT_LSP_PORT": "6005"
			}
		},
		"godot-export": {
			"type": "local",
			"command": ["~/.local/bin/uv", "run", "--script", "~/.config/opencode/tools/godot-export-mcp"],
			"enabled": true
		}
  },
  "agent": {},
  "formatter": {
    "gdscript-formatter": {
      "command": ["gd4formatter", "--safe", "$FILE"],
      "extensions": [".gd"]
    }
  }
}
```

### 4. Git initialisieren

```bash
cd {project-name}
git init
git config core.autocrlf false
git config user.name "Fox-Alpha"
git config user.email "fox-alpha@users.noreply.github.com"
git checkout -b main
git add .
git commit -m "Add: initial project setup"
git checkout -b development
```

- Wenn ein Remote Host existiert, füge diesen vor dem Checkout mit ein.

### 5. Abschluss

Gib eine Zusammenfassung aus:
- Struktur angelegt unter `{project-name}/`
- Git auf `development`-Branch, initialer Commit auf `main`
- `autocrlf = false` gesetzt (Windows-kompatibel)
- Nächste Schritte: Meldung an User: OpenCode CLI neustartet (Einlesen der opencode.json, instructions usw.), Godot öffnen, `src/project.godot` importieren, erste Szene anlegen, `project.md` mit Details befüllen
