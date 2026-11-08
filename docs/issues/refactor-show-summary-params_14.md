# #14 — show_summary() Parameter reduzieren

**Typ:** Refactoring  
**Prio:** 🟡 Mittel  
**Status:** Offen  
**Betrifft:** `src/scripts/summary.gd`, `src/scripts/game.gd`

---

## Problem

`show_summary()` hat **8 Parameter**:

```gdscript
func show_summary(
    local_data: Dictionary,
    opponent: Dictionary = {},
    is_multiplayer: bool = false,
    round_num: int = 0,
    local_name: String = "YOU",
    opp_name: String = "OPPONENT",
    local_lost: bool = false,
    opponent_lost: bool = false,
) -> void:
```

Das ist:
- Fehleranfällig (Parameter-Reihenfolge)
- Schwer lesbar (8 Argumente an jeder Call-Site)
- Wächst mit jeder neuen Feature-Anforderung

## Ziel

Reduktion auf **max. 3–4 Parameter** durch Einführung eines `SummaryContext`-Dictionary oder einer Data-Klasse.

## Vorgeschlagene Lösung

### Option A: Dictionary (GDScript-idiomatisch)

```gdscript
func show_summary(context: Dictionary) -> void:
    # context = {
    #     local_data: {}, opponent_data: {},
    #     is_multiplayer: bool, round_num: int,
    #     local_name: String, opp_name: String,
    #     local_lost: bool, opponent_lost: bool,
    # }
```

### Option B: Data-Klasse (strenger)

```gdscript
class_name SummaryContext
extends RefCounted
var local_data: Dictionary
var opponent_data: Dictionary
var is_multiplayer: bool
var round_num: int
var local_name: String
var opp_name: String
var local_lost: bool
var opponent_lost: bool
```

## Aufgaben

- [ ] Entscheidung: Option A (Dictionary) oder Option B (Data-Klasse)
- [ ] `show_summary()` Signatur ändern
- [ ] Alle Call-Sites in `game.gd` anpassen (`_show_summary_with_synced_opponent_data`, `_show_summary_with_received_data`, `_on_opponent_topped_out`)
- [ ] `update_opponent_stats()` ebenfalls anpassen
- [ ] `game.gd`: `_build_local_stats()` um zusätzliche Felder erweitern

## Akzeptanzkriterien

- `show_summary()` hat max. 4 Parameter
- Alle Aufrufstellen sind lesbar
- Kein Verhalten-Änderung
