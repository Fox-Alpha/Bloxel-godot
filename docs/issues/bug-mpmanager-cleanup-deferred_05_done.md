---
name: Bug report
about: _cleanup wird call_deferred – stop() dazwischen riskiert offenen Peer
title: "[BUG] _cleanup call_deferred kann offenen Peer hinterlassen"
labels: bug, multiplayer
assignees: ''

---

**Describe the bug**
In `scripts/MultiplayerManager.gd:79` wird `_cleanup` mittels `call_deferred()` aufgerufen. Wenn zwischen dem Disconnect-Event und dem deferred-Cleanup erneut `stop()` aufgerufen wird, bleibt ein offener ENet-Peer zurück.

**To Reproduce**
1. Verbindung trennen (löst `_on_peer_disconnected` aus → deferred `_cleanup`)
2. Noch vor dem nächsten Frame `stop()` aufrufen (z.B. per UI)
3. Der deferred-Aufruf läuft gegen einen bereits geräumten State

**Expected behavior**
Guard-Variable (`_cleaning_up`) einführen oder `stop()` vor dem deferred-Aufruf ausführen.

**Desktop**
 - OS: alle
 - Version: aktuell

**Additional context**
Code-Review 2026-07-06, Punkt #5

---

## Status: BEHOBEN ✅

**Behoben in:** `feature/refactor-bugs-and-structure` (Commit `b66e96d`)
**Datum:** 2026-07-10

**Lösung:**
Guard-Variable `_is_cleaning` in `_cleanup()` eingeführt, die einen doppelten Aufruf verhindert:

```gdscript
func _cleanup() -> void:
    if _is_cleaning:
        return
    _is_cleaning = true
    if enet_peer != null:
        enet_peer.close()
        enet_peer = null
    multiplayer.multiplayer_peer = null
    _is_cleaning = false
```

Zusätzlich wurde die Reihenfolge in `stop()` mit `_cleanup()` vereinheitlicht (erst `close()`, dann `null`) — siehe auch `bug-mpmanager-race-condition_done.md`.
