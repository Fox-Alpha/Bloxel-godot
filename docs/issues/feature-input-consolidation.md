---
name: Feature request
about: Input-Verarbeitung vereinheitlichen
title: "[REFACTOR] Input-Verarbeitung vereinheitlichen (_unhandled_input statt _process)"
labels: enhancement, refactor
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
Hard Drop und Rotation laufen über `_unhandled_input` (`scripts/game.gd:182-190`), horizontale Bewegung und Soft Drop über `_process` (`scripts/game.gd:144-173`). `is_action_just_pressed` in `_process` kann bei niedriger Framerate Tastendrücke verschlucken.

**Describe the solution you'd like**
Komplette Input-Verarbeitung nach `_unhandled_input` (oder `_input`) verschieben und DAS/ARR dort mit einer delta-Akkumulation timen.

**Describe alternatives you've considered**
- Aktueller Mix: inkonsistent, fehleranfällig
- Alles in `_process`: verschluckt weiterhin Events

**Additional context**
Code-Review 2026-07-06, Punkt #1
