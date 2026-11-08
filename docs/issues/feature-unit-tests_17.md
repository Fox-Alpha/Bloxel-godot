# #17 — Unit Tests für Kernlogik einführen

**Typ:** Feature
**Prio:** 🟢 Niedrig
**Status:** Offen
**Betrifft:** `src/scripts/piece_data.gd`, `src/scripts/board_codec.gd`, zukünftige Logik-Scripts

---

## Problem

Es gibt **keine Tests** im Projekt. Die kürzlich extrahierten Klassen `PieceData` und `BoardCodec` sind ideal für Unit-Tests, weil sie:
- Statisch sind (kein Node-Bedarf)
- Rein funktionale Logik enthalten
- Isoliert getestet werden können

## Ziel

Grundlegende Testabdeckung für die Kernlogik mit Godots eingebautem Test-Runner (`--headless --script`).

## Priorität für Tests

| Klasse | Testbarkeit | Priorität |
|---|---|---|
| `BoardCodec.encode/decode` | Exzellent (statisch, deterministisch) | 🔴 Hoch |
| `PieceData.get_cells` | Exzellent (statisch, deterministisch) | 🔴 Hoch |
| `PieceData.get_kicks` | Exzellent | 🟡 Mittel |
| Board-Clear-Logik (nach Split) | Gut (nach #12) | 🟡 Mittel |
| Collision-Detection (nach Split) | Gut (nach #12) | 🟡 Mittel |

## Aufgaben

- [ ] Test-Infrastruktur einrichten (Godot `--headless` oder GdUnit4)
- [ ] `test_board_codec.gd`: Encode/Decode-Roundtrip, Edge Cases (leeres Board, maximale Werte)
- [ ] `test_piece_data.gd`: Rotation aller 7 Piece-Types, Wall-Kick-Offsets
- [ ] Nach game.gd-Split (#12): Tests für Board-Logik (Clear, Collision, Valid)
- [ ] CI-Integration (GitHub Actions mit `--headless`)

## Abhängigkeiten

- #12 (game.gd-Split) sollte zuerst abgeschlossen werden, damit Logik-Tests sinnvoll sind
