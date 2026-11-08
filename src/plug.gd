extends "res://addons/gd-plug/plug.gd"
## Addon-Liste von Bloxel für gd-plug.
##
## Installieren bzw. aktualisieren (im Ordner src/, Editor vorher schließen):[br]
## [code]godot --headless -s plug.gd install[/code][br]
## Weitere Befehle: [code]status[/code], [code]clean[/code], [code]help[/code].
## Übersicht der Addons: docs/addons.md.


## Deklariert die Addons. Standardmäßig wird nur der Ordner [code]addons/[/code] eines Repos installiert.
func _plugging() -> void:
	# Logging
	plug("Fox-Alpha/log.gd-fork", {
		"branch": "develope",
		"include": ["addons/log/"],
		"install_root": "addons/log/",
	})

	# Werkzeuge
	# Nur die Editor-Variante: Der Variante "standalone" fehlt im Repo die kompilierte Bibliothek.
	plug("GDQuest/GDScript-formatter", {
		"dev": true,
		"include": ["addons/GDQuest_GDScript_formatter/"],
	})

	# MCP: Version gemeinsam mit dem Server-Pin in ~/.claude.json halten
	plug("hi-godot/godot-ai", {
		"dev": true,
		"tag": "v4.4.1",
		"include": ["plugin/addons/godot_ai/"],
		"install_root": "addons/godot_ai",
	})

	# Unit-Tests
	plug("bitwes/Gut", {"dev": true, "tag": "v9.7.1"})

	# Discord-Anbindung (zurückgestellt, siehe Branch feature/addon_discord_rpc). Tag beim Aktivieren festlegen.
	#plug("https://codeberg.org/DiscordGodot/RPC-Legacy.git")
