# Refactoring Roadmap

Empfohlene Umsetzungsreihenfolge für die offenen Issues (#13–#20).

---

## Übersicht

```
#17 Unit Tests (BoardCodec, PieceData)
 └─► #20 game.gd Split
      └─► #15 class_name-Deklarationen
           ├─► #13 Docstrings konsistent
           ├─► #14 show_summary() Parameter
           ├─► #18 lobby hardcoded path
           └─► #19 Translations
                └─► #16 Magic Numbers UI
```

---

## Phase 1 — Fundament

### #17 Unit Tests 🟡
> Sichert den Split ab. `PieceData` und `BoardCodec` sind schon heute testbar.

| Priorität | Test |
|---|---|
| 1 | `BoardCodec.encode/decode` Roundtrip |
| 2 | `PieceData.get_cells` Rotation |
| – | Board-Clear-Logik: gehört zu #20 |

### #20 game.gd Split 🔴
> Voraussetzung für fast alles Weitere.

| Schritt | Inhalt |
|---|---|
| 1 | `board_logic.gd` auslagern (Board-Clear, Collision, Valid) |
| 2 | `game_renderer.gd` auslagern (Draw-Board, Draw-Piece, UI-Labels bleiben in `game.gd`) |
| 3 | `game_input.gd` auslagern (DAS/ARR, Move/Rotate/Dispatch, Lock-Delay bleibt in `game.gd`) |
| 4 | `game.gd` als Orchestrator auf ~300 Zeilen reduzieren |
| 5 | Signal-Kommunikation zwischen Split-Scripts einrichten |

**Ergebnis:** `game.gd` von 1.095 auf 932 Zeilen. Die ~300 waren eine grobe Schätzung, übrig sind vor allem
Zustandsvariablen, Multiplayer mit RPCs und Game Over.

---

## Phase 2 — Konsistenz

### #15 class_name-Deklarationen 🟡
> Direkt nach dem Split, weil neue Dateien direkt korrekt benannt werden.

| Datei | Neuer Name |
|---|---|
| `game.gd` | `TetrisGame` |
| `lobby.gd` | `Lobby` |
| `summary.gd` | `GameSummary` |
| `MultiplayerManager.gd` | `MultiplayerManager` |

### #13 Docstrings konsistent 🟡
> Profitiert von #15 (Type-Hints in Docstrings).

- Alle öffentlichen Funktionen: vollständiger Docstring mit `[param]`/`[return]`
- Signale: Beschreibung über Deklaration
- Variablen: `##`-Kommentar für nicht-triviale Felder
- Sprache: Deutsch

### #14 show_summary() Parameter 🟡
> Vereinfacht den Code, der durch #13 erst lesbar geworden ist.

- 8 Parameter → Dictionary oder Data-Klasse
- Alle Call-Sites in `game.gd` anpassen

### #18 lobby hardcoded path 🟢
> Einfacher Fix, aber abhängig von #15 (`class_name`).

- `get_node("/root/Main/MultiplayerManager")` → relativer Pfad oder `class_name`

---

## Phase 3 — Features

### #19 Translations 🟡
> Braucht die sauberen Strings aus #13.

| Schritt | Inhalt |
|---|---|
| 1 | Alle UI-Strings in `tr("KEY")` umwandeln |
| 2 | `en.csv` + `de.csv` erstellen |
| 3 | Sprach-Auswahl in Lobby |

### #16 Magic Numbers UI 🟢
> Letzter Schritt, rein kosmetisch.

- Pixel-Offsets in benannte Konstanten umbenennen

---

Harte Abhängigkeiten stehen im Issue selbst (`Depends on`): #20 braucht #17, #15 braucht #20. Die übrige Reihenfolge
ist **empfohlen**, nicht zwingend.
