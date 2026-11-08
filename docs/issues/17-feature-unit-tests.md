# #17 — Unit-Tests für die Kernlogik mit GUT

GitHub: #17

**Typ:** Feature
**Prio:** 🟡 Mittel
**Status:** Offen
**Betrifft:** `src/scripts/piece_data.gd`, `src/scripts/board_codec.gd`, zukünftige Logik-Scripts

---

## Problem

Es gibt **keine Tests** im Projekt. Die kürzlich extrahierten Klassen `PieceData` und `BoardCodec` sind ideal für Unit-Tests, weil sie:
- Statisch sind (kein Node-Bedarf)
- Rein funktionale Logik enthalten
- Isoliert getestet werden können

## Ziel

Grundlegende Testabdeckung für die Kernlogik mit [GUT](https://github.com/bitwes/Gut). GUT ist in `src/plug.gd` bereits auskommentiert vorgemerkt und läuft im Editor und headless.

## Priorität für Tests

| Klasse | Testbarkeit | Priorität |
|---|---|---|
| `BoardCodec.encode/decode` | Exzellent (statisch, deterministisch) | 🔴 Hoch |
| `PieceData.get_cells` | Exzellent (statisch, deterministisch) | 🔴 Hoch |
| `PieceData.get_kicks` | Exzellent | 🟡 Mittel |
| Board-Clear-Logik (nach Split) | Gut (nach #20) | 🟡 Mittel |
| Collision-Detection (nach Split) | Gut (nach #20) | 🟡 Mittel |

## Aufgaben

- [ ] GUT in `src/plug.gd` aktivieren und installieren, Testordner `src/tests/` anlegen
- [ ] `test_board_codec.gd`: Encode/Decode-Roundtrip, Edge Cases (leeres Board, maximale Werte)
- [ ] `test_piece_data.gd`: Rotation aller 7 Piece-Types, Wall-Kick-Offsets
- [ ] Nach game.gd-Split (#20): Tests für Board-Logik (Clear, Collision, Valid)
- [ ] CI-Integration (GitHub Actions mit `--headless`)

## Abhängigkeiten

- Die Tests für `BoardCodec` und `PieceData` entstehen vor #20 und sichern den Split ab
- Tests für die Board-Logik folgen nach #20
