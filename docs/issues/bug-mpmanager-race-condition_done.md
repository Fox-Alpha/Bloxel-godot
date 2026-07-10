---
name: Bug report
about: Race Condition in MultiplayerManager.stop()
title: "[BUG] MultiplayerManager.stop() setzt peer null vor close()"
labels: bug, multiplayer, priority-medium
assignees: ''

---

**Describe the bug**
In `scripts/MultiplayerManager.gd:61-68` wird `multiplayer.multiplayer_peer = null` gesetzt, bevor `enet_peer.close()` aufgerufen wird. Ein zwischen den Zeilen feuernder Callback (`peer_disconnected`, `connection_failed`) kann auf eine null-Referenz zugreifen und das Spiel zum Absturz bringen.

**To Reproduce**
Schwer reproduzierbar (Race Condition), aber potenziell bei schnellem Verbindungsabbau + erneutem Host/Join.

**Expected behavior**
Reihenfolge umkehren: erst `enet_peer.close()`, dann `multiplayer.multiplayer_peer = null`.

**Desktop**
 - OS: alle
 - Version: aktuell

**Additional context**
Code-Review 2026-07-06, Punkt #4

---

## Status: BEHOBEN ✅

**Behoben in:** `feature/refactor-bugs-and-structure` (Commit `b66e96d`)
**Datum:** 2026-07-10

**Lösung:**
`stop()` und `_cleanup()` verwenden nun beide die Reihenfolge `close()` → `null`:

```gdscript
func stop() -> void:
    is_host = false
    opponent_id = 0
    if enet_peer != null:
        enet_peer.close()
        enet_peer = null
    multiplayer.multiplayer_peer = null
```

Zusätzlich wurde ein `_is_cleaning`-Guard in `_cleanup()` eingeführt, um doppelte Aufräumarbeit zwischen deferred und explizitem Aufruf zu verhindern (siehe auch `bug-mpmanager-cleanup-deferred_done.md`).
