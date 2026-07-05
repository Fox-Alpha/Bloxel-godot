# Projekt Statistik – godot_towns

> Generiert: 2026-04-27 | Nicht versioniert (gitignore)

---

## Entwicklungszeit

| | |
|---|---|
| **Erster Commit** | 2026-04-23 23:18 |
| **Letzter Commit** | 2026-04-27 23:12 |
| **Zeitraum** | 4 Tage |

### Commits pro Tag

| Datum | Commits |
|---|---|
| 2026-04-23 | 3 |
| 2026-04-24 | 15 |
| 2026-04-25 | 22 |
| 2026-04-26 | 32 |
| 2026-04-27 | 21 |
| **Gesamt** | **93** |

---

## Datei-Statistik

### Script-Dateien (.gd)

| | |
|---|---|
| **Anzahl .gd Dateien** | 44 |
| **Codezeilen gesamt** | 3.370 |
| **Davon Addon (godot-sqlite)** | 13 |
| **Projekt-eigene Zeilen** | 3.357 |

#### Größte Dateien

| Datei | Zeilen |
|---|---|
| `scripts/world/game_world.gd` | 303 |
| `scripts/autoloads/world_db.gd` | 168 |
| `scripts/entities/buildings/building.gd` | 167 |
| `scripts/entities/living/enemy.gd` | 137 |
| `scripts/ui/command_panel/command_panel.gd` | 141 |
| `scripts/autoloads/data_manager.gd` | 129 |
| `scripts/autoloads/world.gd` | 121 |
| `scripts/ui/context_menu/context_menu.gd` | 136 |
| `scripts/world/mini_map.gd` | 110 |
| `scripts/autoloads/building_manager.gd` | 151 |

#### Autoloads (10 aktiv)

| Datei | Zeilen |
|---|---|
| `audio_manager.gd` | 71 |
| `building_manager.gd` | 151 |
| `config_manager.gd` | 83 |
| `data_manager.gd` | 129 |
| `entity_manager.gd` | 65 |
| `game_manager.gd` | 80 |
| `localization_manager.gd` | 42 |
| `message_bus.gd` | 21 |
| `save_manager.gd` | 74 |
| `world_db.gd` | 168 |
| `world.gd` | 121 |

> `terrain_registry.gd` (44 Zeilen) — noch vorhanden, aber nicht mehr als Autoload registriert

---

### Szenen-Dateien (.tscn)

| | |
|---|---|
| **Anzahl** | 10 |

### Ressourcen-Dateien (.tres)

| | |
|---|---|
| **Anzahl** | 5 |

### Sonstige Dateien

| Typ | Anzahl |
|---|---|
| JSON (Spieldaten) | 65 |
| PNG (Texturen) | 2 |
| .import | 2 |
| **Gesamt (alle Dateien)** | **305** |

---

## Verzeichnisstruktur

```
godot_towns/
├── addons/          (godot-sqlite)
├── data/            (JSON Spieldaten)
├── resources/       (.tres TerrainDefs)
├── scenes/          (10 .tscn)
└── scripts/
    ├── autoloads/   (11 Dateien, 10 aktiv)
    ├── core/        (CellData, Command, Entity, TerrainDef)
    ├── entities/    (Building, Citizen, Enemy + AI/Movement)
    ├── ui/          (HUD, MiniMap, CommandPanel, ContextMenu, …)
    └── world/       (GameWorld, MapGenerator, Renderer, …)
```

---

## Session-Phasen (Überblick)

| Phase | Inhalt |
|---|---|
| Phase 1 | Godot-Projektstruktur, Autoloads, Core-Klassen |
| Phase 2 | World/Terrain-Implementierung, TileMap |
| Phase 3 | Entity-System (Entity, Citizen, Building) |
| Phase 4–5 | Toolset, Daten-Layer, WorldDB (SQLite) |
| Phase 6 | Building & Enemy Entities |
| Phase 7 | UI: HUD, MiniMap, CommandPanel, MessagesPanel, ContextMenu |
| Phase 7b | BuildingBase Refactor (isometrischer Footprint, RMK-Erkennung) |
| Autoload-Refactor | Lazy-Init, TerrainRegistry in DataManager, LocalizationManager-Gerüst |
