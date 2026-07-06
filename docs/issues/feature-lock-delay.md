---
name: Feature request
about: Lock Delay für faires Gameplay auf höheren Levels
title: "[FEATURE] Lock Delay implementieren"
labels: enhancement, gameplay
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
Das Piece lockt sofort beim Auftreffen auf das Board (`scripts/game.gd:477-488`). Auf Level 5+ wird das Spiel unfair hart, weil seitliches Manövrieren in enge Lücken kaum möglich ist. Modernes Tetris gewährt 500ms Lock Delay, das bei jeder erfolgreichen Bewegung zurückgesetzt wird.

**Describe the solution you'd like**
- Lock Delay von ~500ms einführen
- Bei erfolgreicher Move/Rotate wird der Timer zurückgesetzt (max. ~15 Resets)
- Nach Ablauf des Timers oder Erreichen des Reset-Limits: Lock

**Describe alternatives you've considered**
- Sofort-Lock (aktuell): zu hart ab Level 5
- Extended Placement (immer X Sekunden): zu großzügig

**Additional context**
Code-Review 2026-07-06, Punkt #2 — höchste Priorität für Gameplay-Verbesserung.
