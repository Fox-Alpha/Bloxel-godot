---
name: Bug report
about: Winner-Ermittlung fehlerhaft bei Gleichzeitigkeit
title: "[BUG] Winner-Ermittlung prüft nur local_lost – Gleichzeitigkeit nicht erkannt"
labels: bug, multiplayer
assignees: ''

---

**Describe the bug**
`_determine_winner` in `scripts/summary.gd:67-73` prüft nur den bool `local_lost`. Verlieren beide Spieler gleichzeitig (selten, aber bei Sync-Timing möglich), wird fälschlich der lokale Spieler zum Sieger erklärt.

**To Reproduce**
1. Zwei Clients im Multiplayer verbinden
2. Beide erreichen gleichzeitig Game Over (z.B. durch synchrones Auffüllen des Boards)
3. Der lokale Spieler sieht sich als Sieger, obwohl beide gleichzeitig verloren haben

**Expected behavior**
Bei Gleichzeitigkeit sollte der Punktestand verglichen werden. Der Spieler mit mehr Punkten gewinnt. Bei Punktgleichstand → Unentschieden anzeigen.

**Error Message (or attach screenshot)**  
Kein Fehler, aber logisch falsche Winner-Anzeige.

**Desktop**
 - OS: alle
 - Version: aktuell

**Additional context**
Code-Review 2026-07-06, Punkt #3

---

## Status: BEHOBEN ✅

**Behoben in:** `feature/refactor-bugs-and-structure` (Commit `b66e96d`)
**Datum:** 2026-07-10

**Lösung:**
`_determine_winner` in `summary.gd` vergleicht nun bei gleichzeitigem Top-Out beider Spieler die Scores. Beide Bildschirme zeigen denselben Gewinner:

```gdscript
func _determine_winner() -> String:
    if not _is_multiplayer or _opponent_data.is_empty():
        return ""
    if _local_lost and _opponent_lost:
        var ls := int(_local_data.get("score", 0))
        var os := int(_opponent_data.get("score", 0))
        if ls > os:
            return _local_name + " WINS!"
        if os > ls:
            return _opp_name + " WINS!"
        return "DRAW!"
    if _local_lost:
        return _opp_name + " WINS!"
    if _opponent_lost:
        return _local_name + " WINS!"
    return ""
```

Zusätzlich wurde `update_opponent_stats()` in `summary.gd` eingeführt, damit ein verspätet eintreffender reliable RPC die Winner-Anzeige korrigieren kann. In `game.gd` wurde das `opponent_topped_out`-Flag ergänzt, das den Zeitpunkt des gegnerischen Top-Outs verarbeitet.
