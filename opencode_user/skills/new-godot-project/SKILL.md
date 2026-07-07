---
name: new-godot-project
description: Setup a new Godot project with OpenCode support. Creates repo structure, git, .opencode/, and copies template files. Ask for project name and optional description before running.
---

# New Godot Project — Boilerplate

## Vorbereitung

1. Frage nach dem **Projektnamen** (wird für Ordner, `project.godot`, README etc. verwendet)
2. Frage optional nach einer **Kurzbeschreibung** für `project.md`

## Verzeichnisstruktur

```
{project-name}/
├── src/
│   ├── assets/
│   ├── scenes/
│   ├── scripts/
│   ├── addons/
│   ├── project.godot
│   └── icon.svg
├── assets/{sprites,sounds,fonts}/
├── docs/
├── reference/
├── .exports/
├── .opencode/{instructions,agents,files}/
├── AGENTS.md
├── opencode.json
├── README.md
├── .gitignore
└── .editorconfig
```

## Ausführung

### 1. Verzeichnisse anlegen

```bash
mkdir -p {project-name}/{src/{assets,scenes,scripts,addons},assets/{sprites,sounds,fonts},docs,reference,.exports,.opencode/{instructions,agents,files}}
```

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
      "~/.config/opencode/**": "allow"
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

### 5. Abschluss

Gib eine Zusammenfassung aus:
- Struktur angelegt unter `{project-name}/`
- Git auf `development`-Branch, initialer Commit auf `main`
- `autocrlf = false` gesetzt (Windows-kompatibel)
- Nächste Schritte: Godot öffnen, `src/project.godot` importieren, erste Szene anlegen, `project.md` mit Details befüllen
