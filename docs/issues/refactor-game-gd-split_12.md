# #12 — game.gd aufteilen (God Object auflösen)

**Typ:** Refactoring  
**Prio:** 🔴 Hoch  
**Status:** Offen  
**Betrifft:** `src/scripts/game.gd` (1.054 Zeilen)

---

## Problem

`game.gd` ist ein God Object mit **6 Verantwortlichkeiten** in einer einzigen Datei:

1. **Spiellogik** — Board, Pieces, Kollision, Clear, Scoring
2. **Rendering** — `_draw()`, `_draw_board()`, `_draw_piece()`, `_draw_preview()`
3. **Input-Handling** — DAS/ARR, Hard Drop, Rotation, Soft Drop
4. **Multiplayer-Sync** — RPCs, Board-Encoding/Decoding, Opponent-State
5. **UI-Updates** — Labels positionieren, Status aktualisieren
6. **Game-State-Management** — Start, Game Over, Round-Reset

Das erschwert:
- Wartbarkeit (Änderungen in einem Bereich können andere brechen)
- Testbarkeit (Rendering nicht isoliert testbar)
- Lesbarkeit (1.000+ Zeilen ist schwer navigierbar)

## Ziel

Aufsplitten in **3–4 eigenständige Scripts** mit klarer Verantwortung.

## Vorgeschlagene Struktur

```
src/scripts/
├── game.gd              — Orchestrator (Lifecycle, State, Minimallogik)
├── board_logic.gd       — Board-Operationen (Create, Clear, Collision, Valid)
├── game_renderer.gd     — Rendering (Draw-Board, Draw-Piece, Draw-Preview, UI-Labels)
├── game_input.gd        — Input-Handling (DAS/ARR, Move, Rotate, Drop)
├── piece_data.gd        — ✅ bereits extrahiert
├── board_codec.gd       — ✅ bereits extrahiert
├── MultiplayerManager.gd
├── lobby.gd
└── summary.gd
```

## Aufgaben

- [ ] `board_logic.gd` erstellen: `_create_empty_board()`, `_is_valid()`, `_is_resting()`, `_clear_lines()`, Board-Variablen
- [ ] `game_renderer.gd` erstellen: `_draw_board()`, `_draw_piece()`, `_draw_preview()`, `_draw_ui_labels()`, Farben/Konstanten
- [ ] `game_input.gd` erstellen: DAS/ARR-Logik, Lock-Delay-Timer, Move/Rotate/Drop-Dispatch
- [ ] `game.gd` als Orchestrator behalten: `_ready()`, `_process()`, `_unhandled_input()`, State-Variables, RPC-Handler
- [ ] Signal-Kommunikation zwischen den Split-Scripts (z.B. `board.cleared`, `input.drop_requested`)
- [ ] Sicherstellen, dass alle bestehenden Tests weiterhin funktionieren

## Akzeptanzkriterien

- `game.gd` enthält max. ~300 Zeilen
- Jedes neue Script hat eine einzelne Verantwortung (SRP)
- Keine direkten Node-Referenzen in den Logik-Scripts (nur über Signals/Parameter)
- Lint bleibt bei 0 Issues
- Gameplay bleibt identisch (kein Regressions-Fehler)

## Notes

- Die Extraktion von `PieceData` und `BoardCodec` (PR #Ref) ist ein gelungener erster Schritt — dieses Issue baut darauf auf
- `_draw_piece` und `_draw_board` wurden im Refactor-Branch bereits auf Lesbarkeit gebrochen (mehrzeilige Aufrufe)
- Multiplayer-Logik könnte ggf. in einen separaten `game_multiplayer.gd` wandern (optional, Phase 2)
