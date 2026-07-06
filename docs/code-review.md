# Code Review: Bloxel

**Datum:** 2026-07-06  
**Projekt:** Bloxel — Godot 4.7 Tetris-Klon mit 2P-Multiplayer  
**Codebasis:** ~1.200 Zeilen GDScript, 4 Scripts, 3 Scenes

---

## Überblick

Bloxel ist ein funktionaler Tetris-Klon in Godot 4.7 mit ENet-basiertem 2-Spieler-Multiplayer.
Die Architektur ist klar aufgeteilt:

| Datei | Zweck |
|---|---|
| `scripts/game.gd` | Spiellogik, Input, Kollision, Scoring, Ghost Piece, DAS/ARR |
| `scripts/lobby.gd` | Lobby-UI, Host/Join, Name-Eingabe, Ready |
| `scripts/summary.gd` | Post-Game-Summary, Rematch, Winner-Bestimmung |
| `scripts/MultiplayerManager.gd` | ENet Peer Setup/Teardown, RPC-Signale |

---

## Stärken

### SRS (Super Rotation System)
- Wall-Kicks für J/L/S/T/Z und I-Piece sind korrekt als Kick-Tabellen hinterlegt.
- Rotation versucht bis zu 5 Offsets pro Richtungswechsel.

### Bag-Randomizer
- Standard 7-Bag: Jeder Durchlauf enthält genau einen von jedem Piece-Typ.
- Verhindert lange Dürre-Perioden bei einem Piece-Typ.

### DAS/ARR
- DAS_DELAY 170ms, DAS_RATE 50ms — fühlt sich arcade-typisch an.
- Korrektes Reset-Verhalten bei Richtungswechsel.

### Multiplayer
- Board-Sync per PackedByteArray (190 Bytes) — effizienter als JSON.
- Unreliable-Sync für Live-Board, Reliable-RPCs für Game-Over/Ready.
- Round-System mit Rematch-Unterstützung.
- Signal-basierte Kommunikation zwischen Lobby, Game und MultiplayerManager.

### Code-Qualität
- Saubere Trennung von Spiellogik, UI und Netzwerk.
- Konstanten klar am Dateikopf definiert.
- Einheitliche Kommentar-Sektionen (`═══`).

---

## Kritikpunkte

### 1. Input-Verarbeitung inkonsistent (mittel)

**Datei:** `scripts/game.gd:134-190`  
**Problem:** Hard Drop und Rotation laufen über `_unhandled_input`, horizontale Bewegung und Soft Drop über `_process`. `is_action_just_pressed` in `_process` kann bei niedriger Framerate Tastendrücke verschlucken.  
**Empfehlung:** Komplette Input-Verarbeitung nach `_unhandled_input` (oder `_input`) verschieben, DAS/ARR dort mit einer `delta`-Akkumulation timen.

### 2. Kein Lock Delay (mittel)

**Datei:** `scripts/game.gd:477-488`  
**Problem:** Das Piece lockt sofort beim Auftreffen. Modernes Tetris gewährt 500ms Lock Delay, das bei jeder erfolgreichen Bewegung (Move/Rotate) zurückgesetzt wird (bis zu einem Maximum, z.B. 15 Resets).  
**Effekt:** Auf Level 5+ wird das Spiel unfair hart — seitliches Manövrieren in enge Lücken ist kaum möglich.  
**Empfehlung:** Lock Delay (0.5s) + `lock_reset`-Counter implementieren.

### 3. Winner-Ermittlung fehlerhaft (mittel)

**Datei:** `scripts/summary.gd:67-73`  
**Problem:** `_determine_winner` prüft nur den bool `local_lost`. Verlieren beide Spieler gleichzeitig (selten, aber bei Sync-Timing möglich), wird fälschlich der lokale Spieler zum Sieger erklärt.  
**Empfehlung:** Immer Punkte vergleichen. Wer mehr Punkte hat, gewinnt. Bei Gleichstand → Unentschieden.

### 4. MultiplayerManager.stop() — Race Condition (mittel)

**Datei:** `scripts/MultiplayerManager.gd:61-68`  
**Problem:** `multiplayer.multiplayer_peer = null` wird vor `enet_peer.close()` gesetzt. Ein dazwischen feuernder Callback (`peer_disconnected`, `connection_failed`) kann abstürzen.  
**Empfehlung:** Erst `close()`, dann `null`.

### 5. `_cleanup` call_deferred (minor)

**Datei:** `scripts/MultiplayerManager.gd:79`  
**Problem:** `_cleanup` läuft deferred, während `stop()` sofort ausführt. Ein Aufruf von `stop()` zwischen Disconnect und Cleanup hinterlässt einen offenen Peer.  
**Empfehlung:** Guard-Variable oder `stop()` vor dem deferred-Aufruf.

### 6. Ungewöhnliche Board-Größe (minor)

**Datei:** `scripts/game.gd:18-20`  
**Aktuell:** `ROWS = 19`, `HIDDEN = 2`, `TOTAL_ROWS = 21`. Standard-Tetris (Guideline) hat 20 sichtbare Reihen + 2 hidden = 22.  
**Effekt:** 1 Reihe weniger Spielfläche — minimal, aber spürbar.  
**Empfehlung:** Auf `ROWS = 20`, `TOTAL_ROWS = 22` umstellen.

### 7. Kein visuelles Feedback (minor)

**Problem:** Line-Clears, Locking, Level-Up haben keine Animation/Partikel/Screen-Shake. Alles ist statisch.  
**Empfehlung:** Optional: Line-Clear kurz aufblinken lassen (Timer + draw_rect), Level-Up kurz Screen-Shake.

### 8. Lobby-Layout ohne Scroll-Container (minor)

**Datei:** `ui/lobby.tscn`  
**Problem:** Auf kleinen Auflösungen (800×600) läuft der untere Teil der Lobby aus dem Bildschirm.  
**Empfehlung:** VBox in einen ScrollContainer legen oder Layout responsiver machen.

### 9. Fehlende T-Spin / Advanced Clear Detection (Info)

**Problem:** Das Spiel erkennt nur Full-Line-Clears, keine T-Spin-, Tetris- oder Back-to-Back-Boni.  
**Bewertung:** Für einen Klon akzeptabel.

---

## Zusammenfassung

| Bereich | Bewertung |
|---|---|
| **Code-Qualität** | Gut — konsistentes GDScript, klare Trennung, lesbar |
| **Gameplay** | Solide Basis — Lock-Delay fehlt, sonst rund |
| **Multiplayer** | Funktional — Race-Condition in `stop()` beachten |
| **SRS/Kicks** | Korrekt implementiert |
| **UI/UX** | Puristisch, funktional |
| **Wartbarkeit** | Hoch — 4 Dateien, klare Struktur, kommentiert |

### Priority:

1. **Hoch:** Lock Delay (Gameplay) + Input-Vereinheitlichung
2. **Hoch:** Winner-Detektion fixen
3. **Mittel:** `MultiplayerManager.stop()` Race Condition
4. **Niedrig:** Board-Größe anpassen, visuelles Feedback, Lobby-Layout
