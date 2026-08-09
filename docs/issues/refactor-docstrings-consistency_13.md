# #13 — Docstrings konsistent in allen .gd-Dateien aktualisieren

**Typ:** Refactoring  
**Prio:** 🟡 Mittel  
**Status:** Offen  
**Betrifft:** Alle `.gd`-Dateien im Projekt (6 Dateien)

---

## Problem

Die `##`-Docstrings sind inhaltlich gut, aber **nicht konsistent**:

- Manche Funktionen haben ausführliche Docstrings mit `[param]`- und `[return]`-Tags
- Andere haben nur eine einzeilige Beschreibung oder gar keinen Docstring
- Private Funktionen (`_on_*`, `_set_*`) haben meist keinen Docstring
- Signals haben fast nie eine Dokumentation
- Variablen-Docstrings variieren in Länge und Detailgrad

## Ziel

Alle öffentlichen und wichtigen internen Funktionen haben ein **einheitliches Docstring-Format**:

```gdscript
## Kurzbeschreibung der Funktion.
## [param name] — Beschreibung des Parameters.
## [return] — Beschreibung des Rückgabewerts.
```

## Richtlinien

1. **Öffentliche Funktionen** — Immer vollständiger Docstring mit `[param]` und `[return]`
2. **Signal-Callbacks** (`_on_*`) — Mindestens einzeilige Beschreibung
3. **Private Hilfsfunktionen** — Mindestens einzeilige Beschreibung
4. **Signale** — `##`-Kommentar über der Signal-Deklaration mit Beschreibung
5. **Variablen** — `##`-Kommentar für alle nicht-trivialen Variablen
6. **Sprache:** Englisch (konsistent mit Code-Identifiern)

## Aufgaben

- [ ] `game.gd` — Docstrings für alle ~40 Funktionen prüfen/ergänzen
- [ ] `lobby.gd` — Docstrings für alle ~15 Funktionen prüfen/ergänzen
- [ ] `MultiplayerManager.gd` — Docstrings für alle ~10 Funktionen + 5 Signale ergänzen
- [ ] `summary.gd` — Docstrings für alle ~10 Funktionen + 2 Signale ergänzen
- [ ] `piece_data.gd` — Vorhandene Docstrings prüfen (sind bereits gut)
- [ ] `board_codec.gd` — Vorhandene Docstrings prüfen (sind bereits gut)
- [ ] Nach dem game.gd-Split (#12): Auch die neuen Dateien mit Docstrings versehen

## Akzeptanzkriterien

- Jede Funktion hat einen `##`-Docstring
- Alle `[param]`- und `[return]`-Tags sind vorhanden, wo zutreffend
- Signale haben eine Beschreibung
- `godot-lsp_gdscript_lint` meldet keine Docstring-bezogenen Warnungen
