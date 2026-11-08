# Verwendete Addons

Welche Addons installiert werden, legt [`src/plug.gd`](../src/plug.gd) fest. Diese Datei hält fest, wozu sie dienen und
wo sie herkommen.

| Addon | Status |
|---|---|
| [gd-plug](#gd-plug) | aktiv, versioniert in `src/addons/gd-plug/` |
| [Godot-AI](#godot-ai) | aktiv, nur Entwicklung |
| [GDScript-formatter](#gdscript-formatter) | aktiv, nur Entwicklung |
| [GUT](#gut) | geplant, in `plug.gd` auskommentiert |
| [discord-rpc-godot](#discord-rpc-godot) | zurückgestellt, in `plug.gd` auskommentiert |
| [log.gd](#loggd) | aktiv, statische Klasse `Log` für alle Ausgaben |

## gd-plug

GitHub: https://github.com/Fox-Alpha/fork-gd-plug (Fork von https://github.com/imjp94/gd-plug)

**Beschreibung**
Verwaltet die Addons des Projekts anhand von `src/plug.gd`.

## Godot-AI

Asset Store: https://store.godotengine.org/asset/dlight/godot-ai/
GitHub: https://github.com/hi-godot/godot-ai

**Beschreibung**
Connect MCP clients directly to a live Godot editor via the Model Context Protocol. Over 120 ops across ~43 MCP tools
(full list) let AI assistants (Claude Code, Codex, Grok Build, Antigravity, Hermes Agent, etc.) build scenes, edit
nodes and scripts, wire signals, and configure UI, materials, animations, particles, cameras, and environments.

## GDScript-formatter

GitHub: https://github.com/GDQuest/GDScript-formatter

**Beschreibung**
Formatiert und prüft GDScript-Dateien.

## GUT

GitHub: https://github.com/bitwes/Gut

**Beschreibung**
Unit-Test-Framework für GDScript, läuft im Editor und headless.

## discord-rpc-godot

Asset Store: https://store.godotengine.org/asset/vaporvee/discord-rpc-godot/
Codeberg: https://codeberg.org/DiscordGodot/RPC-Legacy

Die bisherige Einbindung liegt auf dem Branch `feature/addon_discord_rpc`.

**Beschreibung**
Discord RPC Plugin for GDScript with an easy-to-use code pattern in Godot Engine 4, with optional Editor Rich Presence!
(Compatible with Linux, Windows, & MacOS)

## log.gd

Asset Store: https://store.godotengine.org/asset/danger-russ-games/log-gd/
GitHub: https://github.com/russmatney/log.gd
Fork: https://github.com/Fox-Alpha/log.gd-fork/tree/develope

**Beschreibung**
Log.gd provides a drop-in replacement for GDScript's print(...) function.

It colors the output based on the value passed in, and adds a prefix based on the call-site's file and line number.
