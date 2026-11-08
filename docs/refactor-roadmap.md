# Refactoring Roadmap

Empfohlene Umsetzungsreihenfolge für die offenen Issues (#12–#19).

---

## Übersicht

```
#12 game.gd Split
 └─► #15 class_name-Deklarationen
      ├─► #13 Docstrings konsistent
      ├─► #14 show_summary() Parameter
      └─► #19 Translations
           └─► #17 Unit Tests (nach Split)
                ├─► #18 lobby hardcoded path
                └─► #16 Magic Numbers UI
```

---

## Phase 1 — Fundament

### #12 game.gd Split 🔴
> Voraussetzung für fast alles Weitere.

| Schritt | Inhalt |
|---|---|
| 1 | `board_logic.gd` auslagern (Board-Clear, Collision, Valid) |
| 2 | `game_renderer.gd` auslagern (Draw-Board, Draw-Piece, UI-Labels) |
| 3 | `game_input.gd` auslagern (DAS/ARR, Lock-Delay, Move/Rotate/Dispatch) |
| 4 | `game.gd` als Orchestrator auf ~300 Zeilen reduzieren |
| 5 | Signal-Kommunikation zwischen Split-Scripts einrichten |

**Ergebnis:** `game.gd` von 1.054 → ~300 Zeilen, klare SRP pro Datei.

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
- Sprache: Englisch

### #14 show_summary() Parameter 🟡
> Vereinfacht den Code, der durch #13 erst lesbar geworden ist.

- 8 Parameter → Dictionary oder Data-Klasse
- Alle Call-Sites in `game.gd` anpassen

---

## Phase 3 — Features

### #19 Translations 🟡
> Braucht die sauberen Strings aus #13.

| Schritt | Inhalt |
|---|---|
| 1 | Alle UI-Strings in `tr("KEY")` umwandeln |
| 2 | `en.csv` + `de.csv` erstellen |
| 3 | Sprach-Auswahl in Lobby |

---

## Phase 4 — Qualität

### #17 Unit Tests 🟢
> Nach dem Split (#12) sind Logik-Scripts testbar.

| Priorität | Test |
|---|---|
| 1 | `BoardCodec.encode/decode` Roundtrip |
| 2 | `PieceData.get_cells` Rotation |
| 3 | Board-Clear-Logik (nach #12) |

### #18 lobby hardcoded path 🟢
> Einfacher Fix, aber Abhängig von #15 (`class_name`).

- `get_node("/root/Main/MultiplayerManager")` → relativer Pfad oder `class_name`

### #16 Magic Numbers UI 🟢
> Letzter Schritt, rein kosmetisch.

- Pixel-Offsets in benannte Konstanten umbenennen

---

## Abhängigkeiten

```
#12 ──► #15 ──► #13 ──► #14
         │               │
         └───────────────┘──► #19 ──► #17
                                    ──► #18
                                    ──► #16
```

Kein Issue ausser #12 hat harte Abhängigkeiten — die Reihenfolge ist **empfohlen**, nicht zwingend.
