# #15 — class_name-Deklarationen für alle Scripts

**Typ:** Refactoring  
**Prio:** 🟡 Mittel  
**Status:** Offen  
**Betrifft:** `game.gd`, `lobby.gd`, `summary.gd`, `MultiplayerManager.gd`

---

## Problem

Nur 2 von 6 Scripts haben eine `class_name`-Deklaration:

| Script | class_name | Status |
|---|---|---|
| `piece_data.gd` | `PieceData` | ✅ |
| `board_codec.gd` | `BoardCodec` | ✅ |
| `game.gd` | — | ❌ Fehlt |
| `lobby.gd` | — | ❌ Fehlt |
| `summary.gd` | — | ❌ Fehlt |
| `MultiplayerManager.gd` | — | ❌ Fehlt |

Ohne `class_name`:
- Keine Type-Hints in anderen Scripts möglich
- IDE-Autovervollständigung funktioniert nicht
- `is`-Checks sind ungenau

## Ziel

Jedes Script bekommt ein `class_name` gemäss GDScript-Style-Guide (PascalCase).

## Vorgeschlagene Namen

| Script | class_name | Begründung |
|---|---|---|
| `game.gd` | `TetrisGame` | Klar, distinkt von generischem "Game" |
| `lobby.gd` | `Lobby` | Selbsterklärend |
| `summary.gd` | `GameSummary` | Unterscheidbar von generischem "Summary" |
| `MultiplayerManager.gd` | `MultiplayerManager` | Selbsterklärend |

## Aufgaben

- [ ] `class_name` am Dateianfang jedes Scripts einfügen
- [ ] `@onready var mp_manager` in `lobby.gd` und `game.gd` mit `: MultiplayerManager` typisieren
- [ ] `@onready var lobby` in `game.gd` mit `: Lobby` typisieren
- [ ] `@onready var summary` in `game.gd` mit `: GameSummary` typisieren
- [ ] Prüfen, ob `extends` korrekt bleibt (z.B. `extends Control` bei `Lobby`)

## Akzeptanzkriterien

- Alle 6 Scripts haben ein `class_name`
- Typannotationen in `@onready`-Variablen nutzen die neuen Klassennamen
- Kein Lint-Fehler
