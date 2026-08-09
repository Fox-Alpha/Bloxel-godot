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

---

## Status: UMGESETZT ✅

**Behoben in:** `feature/refactor-bugs-and-structure` (Commit `b66e96d`)
**Datum:** 2026-07-10

**Lösung:**
Alle diskreten Eingaben (Move, Rotate, Hard-Drop, Soft-Drop, Key-Release) werden nun in `_unhandled_input()` verarbeitet — keine verschluckten Tastendrücke mehr bei niedriger Framerate:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("hard_drop"):
        _hard_drop()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("rotate"):
        _rotate_cw()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("move_left"):
        _move(-1, 0)
        das_dir = -1
        das_timer = 0.0
        get_viewport().set_input_as_handled()
    ...
```

DAS-Repeat bleibt in `_process()` über `Input.is_action_pressed()` (kontinuierliche Taste gehalten), was dort sicher ist — `is_action_pressed` ist zustandslos und verschluckt keine Inputs.
