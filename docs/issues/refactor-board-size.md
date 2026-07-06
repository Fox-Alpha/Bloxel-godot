---
name: 'Refactor: Bloxel'
about: Board-Größe auf Guideline-Standard anpassen
title: 'Refactor: Bloxel – Board-Größe auf 20×10 + 2 Hidden'
labels: refactor
assignees: ''

---

## Zusammenfassung
Die Board-Größe in `scripts/game.gd` weicht vom Tetris-Guideline-Standard ab: aktuell 19 sichtbare Reihen + 2 Hidden. Standard sind 20 + 2. Ein Umbau auf 20 Reihen sorgt für Guideline-Kompatibilität und erleichtert das Spiel minimal (mehr Luft zum Manövrieren).

## Betroffene Bereiche
- `scripts/game.gd` — Konstanten `ROWS`, `TOTAL_ROWS`
- Board-Drawing und Ghost-Berechnung (arbeiten automatisch mit den Konstanten)
- Multiplayer-Sync (PackedByteArray-Größe ändert sich, aber RPCs sind flexibel)

## Was soll sich ändern?
- `ROWS = 19` → `ROWS = 20`
- `TOTAL_ROWS = ROWS + HIDDEN` (bleibt automatisch 22)
- Keine weiteren Änderungen — alle Schleifen und Array-Größen nutzen bereits die Konstanten

## Hintergrund / Motivation
- Tetris Guideline: 20 sichtbare Reihen
- Bietet eine Reihe mehr Spielraum
- Erleichtert den Vergleich mit Referenz-Implementierungen

## Akzeptanzkriterien
- [ ] `ROWS = 20` gesetzt
- [ ] Game startet ohne Fehler
- [ ] Board zeichnet 20 Reihen
- [ ] Multiplayer Sync funktioniert (Board-Größe ist beidseitig gleich)
- [ ] Keine Regression bei Piece-Spawning, Kollision, Ghost

## Hinweise / Kontext
Code-Review 2026-07-06, Punkt #6. Die Änderung ist minimal, da alle Loops bereits die Konstanten referenzieren.
