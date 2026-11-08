# #18 — lobby.gd: Hardcoded-Pfad entfernen

**Typ:** Refactoring
**Prio:** 🟢 Niedrig
**Status:** Offen
**Betrifft:** `src/scripts/lobby.gd`

---

## Problem

`lobby.gd` nutzt einen **hardcoded absoluten Pfad** für den MultiplayerManager:

```gdscript
@onready var mp_manager = get_node("/root/Main/MultiplayerManager")
```

Das ist:
- Fragil bei Szenen-Umbenennungen
- Nicht testbar (feste Abhängigkeit zur Scene-Struktur)
- Im Widerspruch zu `game.gd`, das `$MultiplayerManager` nutzt (relativer Pfad)

## Ziel

Konsistente Referenzierung über entweder:
- Relativen Pfad (wie `game.gd`)
- oder `class_name`-Referenz (nach #15)

## Aufgaben

- [ ] Nach #15: `@onready var mp_manager: MultiplayerManager = $MultiplayerManager` (oder Übergeben via `game.gd`)
- [ ] Alternative: `mp_manager` als Parameter an Lobby übergeben (Dependency Injection)
- [ ] Prüfen, ob der Scene-Pfad in der `.tscn`-Datei korrekt ist

## Akzeptanzkriterien

- Kein `get_node("/root/...")` mehr in `lobby.gd`
- Referenz ist konsistent mit `game.gd`
