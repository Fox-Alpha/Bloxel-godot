# #19 — Localization / Übersetzungssystem einführen

**Typ:** Feature
**Prio:** 🟡 Mittel
**Status:** Offen
**Betrifft:** Alle UI-Texte, `project.godot`

---

## Problem

Das Projekt hat **gemischte Sprachen** in UI-Texten:
- Englisch: "SCORE:", "LINES:", "LEVEL:", "GAME OVER", "NEXT", "TIME:", "ROUND:", "Ready", "Waiting..."
- Deutsch: "Spieler 1", "Spieler 2" (Fallback-Namen in `lobby.gd`)

Für ein Tetris-Spiel mit potenziellem Multiplayer-Audience sollte die Sprache konsistent und austauschbar sein.

## Ziel

Einführung von Godots eingebautem **Translation-System** (`tr()`, `.po`/`.csv`-Dateien).

## Vorgehensweise

### Phase 1: Strings extrahieren
- [ ] Alle UI-Texte in `game.gd`, `lobby.gd`, `summary.gd` identifizieren
- [ ] Durch `tr("KEY")`-Aufrufe ersetzen
- [ ] Fallback-Sprache: Englisch (als String-Key)

### Phase 2: Übersetzungsdateien
- [ ] `project.godot`: `internationalization/locale/translation_add_mode = "replace"`
- [ ] `res://translations/en.csv` (oder `.po`) als Basis erstellen
- [ ] `res://translations/de.csv` für deutsche Übersetzung

### Phase 3: Anwendung
- [ ] Sprach-Auswahl in der Lobby hinzufügen (OptionMenu oder Dropdown)
- [ ] `TranslationServer.set_locale()` bei Sprachwechsel aufrufen
- [ ] Fallback auf Englisch wenn Übersetzung fehlt

## Zu übersetzende Strings

### game.gd
- `"SCORE: "`, `"LINES: "`, `"LEVEL: "`, `"TIME: "`, `"ROUND: "`
- `"GAME OVER"`, `"GAME OVER - Round "`
- `" (Joined)"`, `" (Host)"`

### lobby.gd
- `"Spieler 1"`, `"Spieler 2"` (Fallback-Namen)
- `"Status: "`, `"Idle"`, `"Waiting for opponent..."`
- `"Connected! Starting game..."`, `"Opponent disconnected"`
- `"Invalid port"`, `"Enter an IP address"`
- `"Hosting on port "`, `"Connecting to "`

### summary.gd
- `"GAME OVER"`, `"GAME OVER - Round "`
- `" WINS!"`, `"DRAW!"`
- `"Ready"`, `"Waiting..."`, `"Back to Menu"`

## Akzeptanzkriterien

- Alle Hardcoded-Strings durch `tr()` ersetzt
- Mindestens `en` und `de` als Locale-Dateien vorhanden
- Sprachwechsel funktioniert zur Laufzeit
- Kein String-Bruch bei fehlender Übersetzung (Fallback auf Key)
