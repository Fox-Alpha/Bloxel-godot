# Workflow

> Read this file before making any commits or merges.

---

## Commit Messages

### Format

```
<Type>: <short description>
```

- Written in **English**
- Short description is imperative, lowercase after the colon
- **One logical change per commit** — never batch unrelated changes
- **This project uses its own commit types — never use Conventional Commits (`feat:`, `chore:`, `fix:` etc.)**

### Types

| Type | Meaning |
|------|---------|
| `Add:` | New files or features |
| `Chg:` | Logic/structure changes (NodeTree umbauen, UI-Layout ändern, Funktionen splitten) |
| `Ref:` | Pure refactoring, no behavior change |
| `Fix:` | Bug fixes |
| `Upd:` | Small adjustments: Funktionsnamen, Parameter, @export-Attribute, neue Variablen |
| `Del:` | Deletion of code or logic within a file |
| `Docs:` | Documentation changes |
| `Mve:` | File moves |
| `Rem:` | File deletions |
| `Ren:` | Renames |

### Examples

```
Add: player inventory system
Chg: split collision handling into separate functions
Fix: collision not detected on steep slopes
Upd: increase jump force from 400 to 500
Ref: extract damage calculation into helper method
Docs: add setup instructions to README
```

### Merge Commits

```
Merge: <feature description>

- bullet summary of what the feature contains
```

---

## Branching

| Branch | Purpose |
|--------|---------|
| `main` | Stable releases only — **never commit directly** |
| `development` | Ongoing development — default working branch |
| `feature/<name>` | Short-lived branches per session — always branch off `development` |

> **Hinweis:** `git init` erzeugt lokal den Branch `master`. GitHub erzeugt `main`. Nach `git init` sofort umbenennen:
> ```bash
> git branch -m master main
> ```
> Alle Projekt-Branches heißen `main` — einheitlich, kein `master` mehr.

### Rules
- Stelle vor dem Start sicher, dass `development` existiert. Falls nicht: von `main` abzweigen (`git checkout -b development main`)
- At the start of each session, create a new `feature/<name>` branch from `development`
- Delete feature branches after merging into `development`
- **Never merge into `development` or `main` autonomously** — always wait for explicit approval
- Merges into `development`: vorher `godot-api-audit` laufen lassen und Ergebnisse im Merge-Request vermerken
- Merges into `main` happen **only on explicit instruction** and only when the state is complete and error-free
- Releases on `main` are marked with a **version tag** (e.g. `v0.1.0`, `v1.0.0`)

---

## Session Behavior

### Session Start

1. Check if the current directory is a Git repository:
   - **Kein Git-Repo oder leeres Verzeichnis:** Frage ob der Skill `new-godot-project` angewendet werden soll
   - **Git-Repo vorhanden:** `git status`, `git log --oneline -5`, aktueller Branch, uncommitted changes — kurz melden
2. Create a new `feature/<name>` branch from `development` if not already on one
3. Ask for clarification if the task or scope is unclear before doing anything

### During a Session

- Before implementing, briefly describe the planned approach and wait for confirmation
- Commit in small steps after each logical change — do not batch into one final commit
- If a task turns out larger than expected, pause and re-confirm scope
- Bash-Befehle nicht mit `&&` oder `;` chainen — einzeln ausführen, sonst greifen Permission-Patterns nicht korrekt

### Session End

1. **API-Audit:** Starte den `godot-api-audit`-Agent für die geänderten Dateien
2. Provide a short summary:
   - What was changed (files, commits)
   - What is still open or unfinished
   - Suggested next steps

---

## Autonomy & Decision Making

- Always ask before creating new files, directories, or making structural/architectural changes
- For small, clearly scoped changes, proceed directly without asking
- If a better solution is spotted during implementation, mention it and give a recommendation — but do not implement it without confirmation
- If an unrelated bug is discovered while working, report it immediately — do not silently fix it
- Never make assumptions about ambiguous requirements; ask instead
