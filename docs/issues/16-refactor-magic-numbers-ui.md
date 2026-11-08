# #16 — Hardcoded UI-Positionen durch Konstanten ersetzen

**Typ:** Refactoring
**Prio:** 🟢 Niedrig
**Status:** Offen
**Betrifft:** `src/scripts/game.gd` (_draw_ui_labels)

---

## Problem

`_draw_ui_labels()` enthält hardcoded Pixel-Offsets:

```gdscript
score_label.position = Vector2(ui_x, ly)
lines_label.position = Vector2(ui_x, ly + 26)
level_label.position = Vector2(ui_x, ly + 52)
time_label.position = Vector2(ui_x, ly + 78)
round_num_label.position = Vector2(ui_x, ly + 104)
```

Die Werte `26`, `52`, `78`, `104` sind Magic Numbers ohne Erklärung.

## Ziel

Die Offsets als benannte Konstanten oder in eine UI-Config-Datei auslagern.

## Vorgeschlagene Lösung

```gdscript
const LABEL_LINE_HEIGHT := 26
const LABEL_OFFSET_LINES := {
    score = 0,
    lines = 1,
    level = 2,
    time = 3,
    round = 4,
}
```

Oder: UI-Layout als `@export`-Ressource für Designer-Tunability.

## Aufgaben

- [ ] Magic Numbers in benannte Konstanten umwandeln
- [ ] Begründung der Werte als Docstring festhalten
- [ ] Prüfen, ob `@export` für UI-Tuning sinnvoll ist
