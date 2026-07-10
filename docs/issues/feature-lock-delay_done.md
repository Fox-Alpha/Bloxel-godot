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

---

## Status: UMGESETZT ✅

**Behoben in:** `feature/refactor-bugs-and-structure` (Commit `b66e96d`)
**Datum:** 2026-07-10

**Lösung:**
Lock Delay von 500ms (`LOCK_DELAY = 0.5`) mit Infinite-Spin-Schutz (`MAX_LOCK_RESETS = 15`) implementiert. Das Stück lockt nicht mehr sofort beim Auftreffen, sondern nach Ablauf des Timers. Move/Rotate setzen den Timer zurück (bis max. 15 Resets):

```gdscript
func _process(delta: float) -> void:
    ...
    if not game_over and not current.is_empty():
        if _is_resting():
            lock_timer += delta
            if lock_timer >= LOCK_DELAY:
                _lock()
        else:
            lock_timer = 0.0
            lock_reset_count = 0

func _try_reset_lock() -> void:
    if lock_reset_count < MAX_LOCK_RESETS and _is_resting():
        lock_timer = 0.0
        lock_reset_count += 1
```

`_drop()` lockt nicht mehr sofort — das übernimmt ausschließlich das Lock-Delay in `_process()`. Hard-Drop umgeht das Lock-Delay bewusst (sofortiges Einrasten).
