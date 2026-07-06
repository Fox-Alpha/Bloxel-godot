---
category: styleguide
language: any
tool: copilot
---

# i18n / Lokalisierungs-Workflow

Dieses Dokument beschreibt den vollständigen Übersetzungs-Workflow für das Projekt.
Vor jeder Commit-Session mit Übersetzungsänderungen einmal lesen.

---

## Systemübersicht

Das Projekt nutzt Godots eingebautes `.po`-Übersetzungssystem (`TranslationServer`).
Texte werden mit `tr("msgid", &"CONTEXT")` abgerufen. Godot lädt alle registrierten
`.po`-Dateien beim Start und wählt anhand der aktiven Locale (`TranslationServer.get_locale()`).

### Dateien

| Datei | Zweck |
|---|---|
| `i18n/towns.pot` | Auto-generiert vom Godot Editor (`.tscn` + `.gd`-Strings) |
| `i18n/towns_const.pot` | **Manuell gepflegt** — Strings die Godot nicht erkennt |
| `i18n/towns_buildings.pot` | Auto-generiert per Script — Building-Namen/-Beschreibungen |
| `i18n/de_DE.po` | Deutsch — aus `towns.pot` |
| `i18n/en_GB.po` | Englisch — aus `towns.pot` |
| `i18n/de_DE-const.po` | Deutsch — aus `towns_const.pot` |
| `i18n/en_GB-const.po` | Englisch — aus `towns_const.pot` |
| `i18n/de_DE-buildings.po` | Deutsch — Building-Namen |
| `i18n/en_GB-buildings.po` | Englisch — Building-Namen |

Alle `.po`-Dateien müssen in `project.godot` unter `locale/translations` registriert sein.

---

## Sprachauswahl im Spiel

`LocalizationManager.set_locale("de_DE")` — ruft `TranslationServer.set_locale()` auf
und emittiert `locale_changed`. Wird vom `OptionButton` im Hauptmenü ausgelöst.
Die Einstellung wird via `ConfigManager.locale` persistiert.

---

## Konventionen in GDScript

### Context-Konstante

Jede Datei mit übersetzten Texten hat eine `_CTX`-Konstante:

```gdscript
const _CTX: StringName = &"SCRIPTNAME_"
```

Namensgebung: Kurzform der Datei/Komponente in Grossbuchstaben, mit Unterstrich.

Beispiele: `&"HUD_"`, `&"CTX_MENU_"`, `&"CMD_PANEL_"`, `&"MSG_PANEL_"`

### tr()-Aufruf

```gdscript
# Einfach
label.text = tr("Spring", _CTX)

# Mit Format
_label.text = tr("Year %d  %s  Day %d", _CTX) % [year, season, day]

# Aus JSON-Daten
label.text = tr(def.get("name_id", fallback_id), &"RESOURCE_BLDG")
```

### NOTIFICATION_TRANSLATION_CHANGED

Nodes die Texte **nur in `_ready()`** setzen, müssen auf Locale-Wechsel reagieren:

```gdscript
func _notification(what: int) -> void:
    if what == NOTIFICATION_TRANSLATION_CHANGED:
        _rebuild_ui()  # Labels neu befüllen
```

Nodes die Texte in `_process()` oder via Signal laufend aktualisieren brauchen das **nicht**
(z.B. `hud.gd` — `_format_time()` wird jeden Frame aufgerufen).

---

## Wann kommt ein String wohin?

### → `towns.pot` / `de_DE.po` / `en_GB.po`

Strings die Godot **automatisch erkennt**:
- Texte direkt in `.tscn`-Dateien (Label, Button `text`-Properties)
- `tr("...")` Aufrufe in `.gd`-Dateien, die in `locale/translations_pot_files` gelistet sind

**Workflow:**
1. `tr("English text", _CTX)` im Script verwenden
2. Im Godot Editor: Project → Tools → Localization → Generate POT
3. `de_DE.po` / `en_GB.po` in Poedit öffnen → "Update from POT" → übersetzen

### → `towns_const.pot` / `de_DE-const.po` / `en_GB-const.po`

Strings die Godot **NICHT automatisch erkennt**:
- Strings in **Array-Konstanten**: `const SEASONS = ["Spring", "Summer", ...]`
- Strings in **Dictionary-Werten** innerhalb von Konstanten
- ID-artige Keys die als Anzeigetext genutzt werden (z.B. Kategorie-Buttons)

**Regel:** Wenn nach einem POT-Export ein `tr()`-String fehlt → in `towns_const.pot` eintragen.

**Workflow:**
1. `tr("MY_ID", _CTX)` im Script verwenden
2. Eintrag manuell in `towns_const.pot` ergänzen:
   ```
   msgctxt "CMD_PANEL_"
   msgid "MY_ID"
   msgstr ""
   ```
3. `de_DE-const.po` / `en_GB-const.po` aktualisieren — Übersetzung eintragen

### → `towns_buildings.pot` / `de_DE-buildings.po` / `en_GB-buildings.po`

Building-Namen und Beschreibungen aus `data/buildings.json`.

**Workflow:**
```bash
python3 tools/generate_building_translations.py
```
Das Script:
- Ergänzt `name_id` / `desc_id` Felder in `buildings.json` (Pattern: `BLDG_PIGFARM_NAME`)
- Aktualisiert `towns_buildings.pot`
- Aktualisiert alle `-buildings.po` Dateien — **bestehende `msgstr` bleiben erhalten**
- Danach in `de_DE-buildings.po` neue leere `msgstr ""` ausfüllen

In GDScript:
```gdscript
var name: String = tr(def.get("name_id", building_id), &"RESOURCE_BLDG")
var desc: String = tr(def.get("desc_id", ""), &"RESOURCE_BLDG") if def.has("desc_id") else ""
```

---

## Neue JSON-Ressource übersetzen — Checkliste

Wenn eine neue JSON-Datei aus `data/` übersetzt werden soll:

- [ ] Passendes Context-Kürzel wählen (z.B. `RESOURCE_TERRAIN`, `RESOURCE_ITEM`)
- [ ] Script analog zu `generate_building_translations.py` erstellen (oder erweitern)
- [ ] `name_id` / `desc_id` Felder in JSON ergänzen (Pattern: `PREFIX_KEY_NAME`)
- [ ] `.pot` und `-xx.po` Dateien generieren
- [ ] `.po` Dateien in `project.godot` registrieren
- [ ] GDScript-Stellen anpassen: `name.en` → `tr(name_id, &"CONTEXT")`

### Priorisierung der noch zu übersetzenden Ressourcen

| Datei | Einträge | Priorität | Kontext-Vorschlag |
|---|---|---|---|
| `terrain.json` | 33 | **Hoch** — sichtbar im Context-Menü | `RESOURCE_TERRAIN` |
| `zones.json` | 15 | **Hoch** — Zone-Namen im UI | `RESOURCE_ZONE` |
| `skills.json` | 20 | Mittel | `RESOURCE_SKILL` |
| `livingentities.json` | 132 Namen | Mittel — NPC-Namen | `RESOURCE_ENTITY` |
| `items.json` | 728 Einträge | Niedrig — sehr groß, später | `RESOURCE_ITEM` |
| `effects.json` | 1 | Niedrig | `RESOURCE_EFFECT` |
| `campaigns.json` | 1 | Niedrig | `RESOURCE_CAMPAIGN` |

---

## Wiederkehrende Aufgabe: Übersetzungen aktualisieren

Bei jeder Session in der neue spielseitige Texte hinzukommen:

1. **GDScript-Strings**: `tr()` + `_CTX` verwenden → POT neu generieren → `.po` in Poedit updaten
2. **Const/Dict-Strings**: manuell in `towns_const.pot` + `-const.po` eintragen
3. **Buildings**: `python3 tools/generate_building_translations.py` ausführen → neue `msgstr` ausfüllen
4. **Andere JSON**: entsprechendes Generate-Script ausführen oder erweitern
5. Alle `.po`-Änderungen committen

---

## Wichtige Hinweise

- **`msgid` = englischer String** (nicht ein Key). Godot nutzt den englischen Text als Fallback
  wenn keine Übersetzung gefunden wird.
- **`msgctxt`** verhindert Kollisionen wenn das gleiche Wort in verschiedenen Kontexten
  unterschiedlich übersetzt werden muss.
- **JSON-Inhalt (Spiellogik)** bleibt auf Englisch (`name.en`). Die `.po`-Datei ist die einzige
  Quelle für Übersetzungen — nicht das JSON.
- **Nie `*.mo` Dateien committen** — diese werden von Godot beim Build automatisch generiert.
