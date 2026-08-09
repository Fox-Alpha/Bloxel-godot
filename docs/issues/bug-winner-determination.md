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
