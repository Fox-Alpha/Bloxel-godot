---
name: Feature request
about: T-Spin / Advanced Clear Detection für Guideline-Kompatibilität
title: "[FEATURE] T-Spin-, Tetris- und Back-to-Back-Boni"
labels: enhancement, gameplay
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
Das Spiel erkennt nur Full-Line-Clears, keine T-Spin-, Tetris- oder Back-to-Back-Boni (`scripts/game.gd:491-517`). Fortgeschrittene Spieltechniken werden nicht belohnt.

**Describe the solution you'd like**
- T-Spin Detection (3-Corner-Regel oder 2-Corner-Regel)
- Tetris-Bonus (4 Lines auf einmal)
- Back-to-Back-Bonus für aufeinanderfolgende Clears
- Angepasstes Scoring nach Guideline

**Describe alternatives you've considered**
- Aktuell: Guideline-Scoring mit 1/2/3/4 Lines = 100/300/500/800 × Level (keine T-Spin-Boni)

**Additional context**
Code-Review 2026-07-06, Punkt #9 — niedrige Priorität, aber schönes Ziel.
