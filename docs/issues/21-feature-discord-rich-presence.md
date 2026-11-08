# #21 — Discord Rich Presence einbinden

GitHub: #21

**Typ:** Feature
**Prio:** 🟢 Niedrig
**Status:** Zurückgestellt
**Betrifft:** `src/plug.gd`, `src/project.godot`, `src/scripts/game.gd`

---

## Problem

Im Discord-Profil ist nicht zu sehen, ob und in welchem Modus jemand Bloxel spielt.

## Ziel

Der aktuelle Spielzustand (Hauptmenü, Einzelspieler, Mehrspieler) erscheint über Discord Rich Presence.

## Ausgangslage

- Addon: [discord-rpc-godot](https://codeberg.org/DiscordGodot/RPC-Legacy), in `src/plug.gd` auskommentiert vorgemerkt
- Eine erste Einbindung samt Bildern für die Discord-App liegt auf dem Branch `feature/addon_discord_rpc`
- Der Branch ist vor dem Refactor von `game.gd` entstanden, seine Änderungen an `game.gd` müssen neu eingepasst werden

## Aufgaben

- [ ] Eintrag in `src/plug.gd` aktivieren und einen Tag festlegen
- [ ] Autoload und Plugin in `project.godot` eintragen
- [ ] Zustände aus `game.gd` und `lobby.gd` an Discord melden
- [ ] Bilder aus dem Branch übernehmen und den Branch danach löschen

## Hinweise

- Liegt das Addon im Ordner `src/addons/`, trägt es sich bei jedem Godot-Start selbst in `project.godot` ein
