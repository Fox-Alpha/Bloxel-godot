# CLAUDE.md – Bloxel

Ergänzt die `CLAUDE.md` der Projektsammlung. Hier steht nur, was davon abweicht oder nur dieses Projekt betrifft.
Stand, offene Punkte und Planung: `docs/projekte/bloxel.md` im Repo der Projektsammlung.

## Projekteinstellungen

- Quellordner: `src/`
- Zusatz: `workflow-godot.md`
- Nutzer-Doku (für `Release: show`): `README.md`

## Besonderheiten

- Tetris-artiges Spiel mit 2-Spieler-Modus über ENet (Standardport 21277). Godot-Projektwurzel ist `src/`, Hauptszene
  ist `res://scenes/main/main.tscn`.
- Szene und Script liegen je Feature in `src/scenes/<feature>/`, Scripts ohne Szene in `src/scripts/`:

  | Datei | Aufgabe |
  |---|---|
  | `scenes/main/game.gd` | Spielablauf, Schwerkraft, Lock Delay, Punkte, UI-Labels, Multiplayer-Sync, Runden |
  | `scripts/board_logic.gd` | Regeln des Spielfelds: Kollision, Festsetzen, Reihen löschen |
  | `scripts/game_renderer.gd` | Zeichnet Spielfeld, Stücke und Vorschau in das `_draw()` von `game.gd` |
  | `scripts/game_input.gd` | Übersetzt Tasten in Signale, DAS/ARR |
  | `scripts/piece_data.gd` | Daten der Spielsteine |
  | `scripts/board_codec.gd` | Board für die Übertragung kodieren und dekodieren |
  | `scenes/lobby/lobby.gd` | Lobby, Host/Join, Spielername |
  | `scenes/summary/summary.gd` | Auswertung nach Spielende, Rematch |
  | `scenes/main/multiplayer_manager.gd` | ENet-Verbindung, Auf- und Abbau |

- `*.uid` und `*.import` immer mitcommitten, `.tscn`-Dateien verweisen auf diese UIDs.
- `src/addons/godot_ai/` ist seit 2026-11-08 nicht mehr versioniert. Ältere Stände und der Branch
  `feature/addon_discord_rpc` enthalten es noch: Beim Wechsel dorthin überschreibt Git die Dateien auf der Platte und
  entfernt sie beim Zurückwechseln. Danach die Addons neu installieren.
- Die Discord-Einbindung ruht auf `feature/addon_discord_rpc`.

## Unit-Tests

- Die Tests liegen in `src/tests/` und nutzen GUT. Jede Datei und jede Testfunktion beginnt mit `test_`.
  `test_board_codec.gd` erklärt im Kopf, wie GUT arbeitet.
- Im Editor: unten das Panel **GUT** öffnen, in dessen Einstellungen `res://tests` als Verzeichnis eintragen und
  **Run All** drücken.
- Headless im Ordner `src/`:

  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
  ```

  Exit-Code 0 heißt alle Tests bestanden. Nach einer frischen Addon-Installation einmal `godot --headless --import`
  ausführen, sonst kennt Godot die Klasse `GutTest` noch nicht.

## Testen mit zwei Instanzen

- `src/scripts/debug/dev_autostart.gd` startet Debug-Instanzen je nach `--instance=N` und
  `src/scripts/debug/run_roles.cfg` als `server`, `client`, `single` oder `menu`. Standard: Instanz 1 Server, Instanz 2
  Client.
- Einmal im Editor einstellen (*Debug > Customize Run Instances*, liegt in `.godot/`): 2 Instanzen mit
  `--instance=N --log-file res://logs/instance_N.log`.
- MCP steuert nur Instanz 1, deshalb die Logs direkt lesen: `src/logs/instance_1.log` und `instance_2.log`. Soll die
  andere Seite gesteuert werden, nur `run_roles.cfg` anpassen und danach zurücksetzen.
