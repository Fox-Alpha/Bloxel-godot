# Code Review: Bloxel — AI-Tetris

**Datum:** 2026-07-10
**Reviewer:** z-ai/glm-5.2 (via OpenCode)
**Projekt:** Bloxel — Godot 4.7 Tetris-Klon mit 2P-Multiplayer (ENet)
**Codebasis:** ~1.360 Zeilen GDScript, 4 Scripts, 3 Szenen
**Quellverzeichnis:** `src/`

---

## Überblick

Bloxel ist ein funktionaler Tetris-Klon mit lokalem Einzelspieler- und ENet-Multiplayer-Modus (2 Spieler). Die Architektur folgt einer klaren Trennung in Spiellogik, UI und Netzwerk:

| Datei | Zeilen | Zweck |
|---|---|---|
| `src/scripts/game.gd` | 1016 | Spiellogik, Input, Kollision, Scoring, Ghost Piece, DAS/ARR, Multiplayer-Sync, Rendering |
| `src/scripts/lobby.gd` | 152 | Lobby-UI: Host/Join, Name-Eingabe, Verbindungsstatus |
| `src/scripts/MultiplayerManager.gd` | 89 | ENet-Peer-Setup/Teardown, Multiplayer-Signale |
| `src/scripts/summary.gd` | 101 | Post-Game-Statistiken, Winner-Anzeige, Rematch |
| `src/main.tscn` | 83 | Root-Szene: Node2D + CanvasLayer (UI + Overlays) |
| `src/ui/lobby.tscn` | 126 | Lobby-Layout |
| `src/ui/summary.tscn` | 102 | Summary-Panel-Layout |

**Gesamtbewertung:** Solide, funktionierende Basis mit korrekten Tetris-Mechaniken (SRS, 7-Bag, DAS/ARR). Ein kritischer Bug in der Board-Initialisierung und mehrere mittelschwere Design-Schwächen verhindern eine höhere Wertung.

### Bewertungszusammenfassung

| Bereich | Note | Kommentar |
|---|---|---|
| **Architektur & Struktur** | 1.7 | Klare Trennung, gute Sektionierung, Signal-basiert |
| **Code-Qualität** | 2.3 | Lesbar, aber Typ-Lücken, Lint-Verstöße, God-Object |
| **Gameplay-Korrektheit** | 2.0 | SRS/7-Bag/DAS korrekt; kein Lock Delay, Board-Bug |
| **Multiplayer** | 2.7 | Funktional, effizient; Race Conditions, fehlende Robustheit |
| **UI/UX** | 2.5 | Puristisch, funktional; kein Feedback, kein Scroll |
| **Wartbarkeit** | 2.3 | 4 Dateien, aber game.gd ist 1016 Zeilen Monolith |

**Gesamt: 2.3 (Befriedigend)** — Funktionsfähiger Prototyp mitVerbesserungspotenzial.

---

## Stärken

### 1. SRS (Super Rotation System) korrekt implementiert
Wall-Kick-Tabellen für J/L/S/T/Z und I-Piece sind vollständig hinterlegt (`game.gd:323-342`). Die Rotation probiert bis zu 5 Offsets pro Richtungswechsel und nutzt die korrekten SRS-Kick-Daten aus der offiziellen Guideline. Die 90°-Rotation `(x,y) → (h-1-y, x)` ist mathematisch korrekt (`game.gd:464-467`).

### 2. 7-Bag Randomizer
`_pop_bag()` (`game.gd:445-450`) implementiert den Standard-7-Bag: Jeder Durchlauf enthält genau einen jedes Piece-Typs (gemischt), verhindert Dürre-Perioden und Streaks. Das Auffüllen bei `bag.size() <= 1` stellt sicher, dass immer ein Stück beim Auffüllen vorausgewählt werden kann.

### 3. DAS/ARR korrekt
`DAS_DELAY = 0.17s` (initialer Delay) und `DAS_RATE = 0.05s` (Wiederholrate) entsprechen Arcade-Standards. Das Reset-Verhalten bei Richtungswechsel (`das_dir = 0` bei Tastenwechsel) und die `while`-Schleife für catch-up sind sauber gelöst (`game.gd:242-251`).

### 4. Effiziente Multiplayer-Board-Sync
Das Board wird als `PackedByteArray` (190 Bytes = 21×10) übertragen (`game.gd:852-860`), was deutlich effizienter als JSON oder Arrays ist. Die Trennung von **unreliable** Sync (Live-Board, `game.gd:906`) und **reliable** RPCs (Game-Over, Ready, Start, Restart) ist architektonisch korrekt.

### 5. Signal-basierte Kommunikation
Lobby ↔ Game ↔ MultiplayerManager kommunizieren über Signale (`single_player_requested`, `game_started`, `peer_disconnected`, `ready_pressed`, `back_pressed`). Das reduziert Kopplung und macht die Komponenten unabhängig testbar. Keine zirkulären Signal-Abhängigkeiten.

### 6. Klare Code-Sektionierung
`game.gd` nutzt ASCII-Sektionsmarker (`═══`) mit Kommentaren, die den Aufbau klar gliedern (Lifecycle, Initialization, Game Start, Piece Generation, Spawn/Movement, Drop/Lock/Clear, etc.). Doc-Kommentare (`##`) mit `[param]`-Tags sind durchgängig vorhanden.

---

## Kritikpunkte

### KRITISCH — Board-Initialisierungs-Bug

**Datei:** `src/scripts/game.gd:414-419`

```gdscript
func _new_game() -> void:
    board = []
    for _i in range(TOTAL_ROWS):
        var r: Array = []
        for _j in range(COLS):
            r.append(0)
            board.append(r)      # ← BUG: innerhalb des inneren Loops!
```

**Problem:** `board.append(r)` steht **innerhalb** des inneren `for _j`-Loops. Das bedeutet:
- Pro Iteration von `_i` wird dieselbe Array-Referenz `r` **10-mal** an `board` angehängt (einmal pro `_j`).
- Das Board hat somit `TOTAL_ROWS × COLS = 21 × 10 = 210` Einträge statt 21.
- `board[0]` bis `board[9]` sind **dieselbe Array-Referenz** — ein Schreibzugriff auf `board[0][c]` verändert auch `board[1..9][c]`.

**Auswirkung:** Die ersten 10 "Zeilen" des Boards sind Aliase derselben Zeile. Das `_is_valid()` prüft zwar `cy >= TOTAL_ROWS` (21), sodass nur Indizes 0-20 angesprochen werden — aber diese 21 Indizes referenzieren nur **3** echte Arrays (0-9 → 1. Array, 10-19 → 2. Array, 20 → 3. Array), da 21/10 = 2,1 Iterationen der äußeren Schleife.

Konkret: `board[0]` bis `board[9]` teilen sich ein Array. Wenn ein Piece in die versteckte Reihe 0 gespawnt und gesperrt wird, wird der Block gleichzeitig in `board[1..9]` geschrieben. Dies kann zu Geister-Blöcken und falschen Kollisionen führen, bevor die erste Line-Clear die Referenzen durch `.duplicate()` auflöst.

**Fix:**
```gdscript
func _new_game() -> void:
    board = []
    for _i in range(TOTAL_ROWS):
        var r: Array = []
        for _j in range(COLS):
            r.append(0)
        board.append(r)   # ← eine Ebene nach außen
```

---

### MITTEL — Input-Verarbeitung inkonsistent

**Datei:** `src/scripts/game.gd:210-269`

**Problem:** Die Input-Verarbeitung ist auf zwei Pfade aufgeteilt:

| Aktion | Pfad | Methode |
|---|---|---|
| `move_left`, `move_right`, `soft_drop` | `_process()` | `Input.is_action_just_pressed()` |
| `hard_drop`, `rotate` | `_unhandled_input()` | `event.is_action_pressed()` |

`Input.is_action_just_pressed()` in `_process()` kann bei niedriger Framerate (< 30 FPS) oder nach Lag-Spikes Tastendrücke verschlucken, da der "just pressed"-Zustand nur für den Frame gilt, in dem das Input-System ihn registriert. Wenn `_process` wegen `while drop_timer >= interval` mehrere Iterationen durchläuft oder eine frame übersprungen wird, geht der Tastendruck verloren.

**Empfehlung:** Komplette Input-Verarbeitung nach `_unhandled_input()` verschieben. DAS/ARR-Timer dort mit `delta` akkumulieren. `_process()` nur noch für Drop-Timer und Sync verwenden.

---

### MITTEL — Kein Lock Delay

**Datei:** `src/scripts/game.gd:575-579`

```gdscript
func _drop() -> void:
    if game_over:
        return
    if not _move(0, 1):
        _lock()   # ← sofortiges Locken bei Aufsetzen
```

**Problem:** Das Piece lockt sofort, sobald es nicht weiter nach unten kann. Die moderne Tetris-Guideline spezifiziert ein **Lock Delay** von 0,5 Sekunden, das bei jeder erfolgreichen Bewegung (Move/Rotate) zurückgesetzt wird — bis zu einem Maximum von 15 Resets.

**Auswirkung:** Ab Level 5+ wird das Spiel unfair hart. Seitliches Manövrieren in enge Lücken ist kaum möglich, da das Piece sofort einrastet.

**Empfehlung:** Lock-Delay-Timer (0,5s) + `lock_reset_count` (max 15) in `_drop()` und `_move()` implementieren.

---

### MITTEL — Winner-Ermittlung fehlerhaft

**Datei:** `src/scripts/summary.gd:67-73`

```gdscript
func _determine_winner(_local: Dictionary, opponent: Dictionary, local_lost: bool = false, ...) -> String:
    if opponent.is_empty():
        return ""
    if local_lost:
        return opp_name + " WINS!"
    else:
        return local_name + " WINS!"
```

**Problem 1:** `_determine_winner` prüft ausschließlich den `local_lost`-Boolean. Wenn beide Spieler gleichzeitig verlieren (selten, aber bei Sync-Timing möglich), wird der lokale Spieler fälschlich zum Sieger erklärt (`i_lost = false` setzt der RPC-Empfänger in `game.gd:924`).

**Problem 2:** Der Parameter `_local` ist mit `_`-Prefix markiert (Konvention für "unused"), wird aber nicht verwendet — die Score-Daten beider Spieler werden ignoriert. Die Winner-Bestimmung basiert rein auf "Wer hat zuerst den Game-Over-RPC gesendet?".

**Empfehlung:** Punkte vergleichen: Wer mehr Score hat, gewinnt. Bei Gleichstand → "DRAW!". Der `local_lost`-Flag kann als Tiebreaker dienen.

---

### MITTEL — Race Condition in `MultiplayerManager.stop()`

**Datei:** `src/scripts/MultiplayerManager.gd:61-68`

```gdscript
func stop() -> void:
    is_host = false
    opponent_id = 0
    multiplayer.multiplayer_peer = null     # ← zuerst null
    if enet_peer != null:
        enet_peer.close()                   # ← dann close
        enet_peer = null
```

**Problem:** `multiplayer.multiplayer_peer = null` wird **vor** `enet_peer.close()` gesetzt. Ein dazwischen feuernder Callback (`peer_disconnected`, `connection_failed`) kann auf einem inkonsistenten Zustand operieren — der MultiplayerPeer ist weg, aber `enet_peer` ist noch nicht geschlossen.

Zudem widerspricht dies der Reihenfolge in `_cleanup()` (Zeile 54-58), die erst `close()` und dann `null` setzt.

**Empfehlung:** Einheitliche Reihenfolge — erst `enet_peer.close()`, dann `multiplayer.multiplayer_peer = null`:
```gdscript
func stop() -> void:
    is_host = false
    opponent_id = 0
    if enet_peer != null:
        enet_peer.close()
        enet_peer = null
    multiplayer.multiplayer_peer = null
```

---

### MITTEL — `_cleanup` call_deferred vs. `stop()` Inkonsistenz

**Datei:** `src/scripts/MultiplayerManager.gd:75-79`

```gdscript
func _on_peer_disconnected(_id: int = 0) -> void:
    opponent_id = 0
    is_host = false
    peer_disconnected.emit()
    _cleanup.call_deferred()   # ← deferred
```

**Problem:** `_cleanup` läuft deferred, während `stop()` (aufgerufen von `game.gd:_on_summary_back()`) sofort ausführt. Wenn `stop()` zwischen dem Disconnect-Event und dem deferred Cleanup aufgerufen wird, kann ein Peer in einem halboffenen Zustand verbleiben. Zudem ruft `stop()` `multiplayer.multiplayer_peer = null` auf, aber `_cleanup` tut dasselbe — Doppelbereinigung ohne Guard.

**Empfehlung:** Guard-Variable `_is_cleaning` einführen oder `stop()` mit `_cleanup()` verschmelzen.

---

### NIEDRIG — Soft-Drop-Scoring an Input-Status gekoppelt

**Datei:** `src/scripts/game.gd:575-582`

```gdscript
func _drop() -> void:
    if game_over:
        return
    if not _move(0, 1):
        _lock()
    elif Input.is_action_pressed("soft_drop"):   # ← Scoring abhängig von Input-State
        score += 1
        _update_ui()
```

**Problem:** In der `while drop_timer >= interval`-Schleife in `_process()` kann `_drop()` mehrfach pro Frame aufgerufen werden. Wenn der Spieler Soft-Drop zwischen zwei Iterationen loslässt, erhält er für die bereits ausgeführten Drops keine Punkte — die Bewegung passierte, aber die Scoring-Bedingung (`is_action_pressed`) ist in der aktuellen Iteration falsch.

**Empfehlung:** Soft-Drop-Flag separat setzen (`_soft_drop_active`) und in `_drop()` auswerten, nicht `Input.is_action_pressed` direkt.

---

### NIEDRIG — `opponent_game_over`-Flag wird nicht für UI genutzt

**Datei:** `src/scripts/game.gd:908-916`

```gdscript
@rpc("any_peer", "unreliable", "call_local")
func _rpc_sync_state(data: PackedByteArray, opp_score: int, opp_lines: int, opp_level: int, opp_game_over: bool) -> void:
    if not is_multiplayer:
        return
    opponent_board = _decode_board(data)
    opponent_score = opp_score
    opponent_lines = opp_lines
    opponent_level = opp_level
    opponent_game_over = opp_game_over   # ← gespeichert, aber nie für UI/Logik verwendet
    queue_redraw()
```

**Problem:** Das `opponent_game_over`-Flag wird im unreliable Sync übertragen und gespeichert, aber nie ausgewertet. Die Summary wird ausschließlich durch den reliable RPC `_rpc_send_game_over` ausgelöst. Wenn der unreliable Sync ankommt, aber der reliable RPC verloren geht (extrem unwahrscheinlich bei reliable, aber möglich bei schweren Netzwerkproblemen), wird der Gegner-GameOver nie angezeigt.

**Empfehlung:** Bei Empfang von `opp_game_over == true` und lokalem `game_over == false` die Summary mit den zuletzt bekannten Gegner-Daten anzeigen.

---

### NIEDRIG — `game.gd` ist ein 1016-Zeilen-Monolith (God Object)

**Datei:** `src/scripts/game.gd`

**Problem:** `game.gd` übernimmt 8+ Verantwortlichkeiten: Input-Handling, Spiellogik, Board-Rendering ( `_draw`), Piece-Definitionen, Scoring, Multiplayer-Sync, RPC-Verwaltung und Summary-Triggering. 1016 Zeilen in einer Datei erschweren Übersicht und Testbarkeit.

**Empfehlung:** Verantwortlichkeiten aufteilen:
- `BoardRenderer` (Zeichnen, `_draw_board`, `_draw_piece`, `_draw_preview`)
- `PieceFactory` (Definitionen, Rotation, SRS-Kicks)
- `TetrisGame` (Logik: spawn, move, lock, clear, scoring)
- `MultiplayerSync` (RPCs, encode/decode, sync-state)

---

### NIEDRIG — Typisierungs-Lücken

**Datei:** `src/scripts/game.gd:78`, `src/scripts/MultiplayerManager.gd:11`

```gdscript
# game.gd:78
@onready var mp_manager = $MultiplayerManager        # ← kein Typ

# MultiplayerManager.gd:11
var enet_peer: ENetMultiplayerPeer                   # ← ok, aber...
var local_player_name: String = "Player 1"           # ← gesetzt, nie verwendet
```

**Problem:** `mp_manager` ist untypisiert — der Styleguide fordert statische Typisierung für alle Variablen. Zudem ist `local_player_name` in `MultiplayerManager` deklariert, aber nie verwendet (tot Code).

**Empfehlung:**
```gdscript
@onready var mp_manager: Node = $MultiplayerManager
```
Und `local_player_name` entfernen oder nutzen.

---

### NIEDRIG — Board-Größe nicht Guideline-konform

**Datei:** `src/scripts/game.gd:27-31`

```gdscript
const ROWS := 19        # ← Standard: 20 sichtbare Reihen
const HIDDEN := 2
const TOTAL_ROWS := 21  # ← Standard: 22
```

**Problem:** Die Tetris-Guideline spezifiziert 20 sichtbare Reihen + 2 versteckte = 22 total. Bloxel hat 19 sichtbare + 2 versteckte = 21. Eine Reihe weniger Spielfläche — minimal, aber spürbar für erfahrene Spieler.

**Empfehlung:** `ROWS = 20`, `TOTAL_ROWS = 22`.

---

### NIEDRIG — Kein visuelles Feedback

**Problem:** Line-Clears, Lock-Events, Level-Ups haben keine Animation, keine Partikel, keinen Screen-Shake. Alles ist statisch — Blöcke verschwinden sofort, ohne Aufblinken oder Übergang.

**Empfehlung:** Optional: Line-Clear kurz aufblinken (Timer + `draw_rect` mit Alpha), Level-Up mit Screen-Shake, Lock-Event mit Mini-Pulse.

---

### NIEDRIG — Lobby-Layout ohne Scroll-Container

**Datei:** `src/ui/lobby.tscn`

**Problem:** Die VBox enthält 15+ Elemente (Titel, Name, Single-Button, Separator, Host-Label, Port, Host-Button, Separator, Join-Label, IP, Port, Join-Button, Status). Auf kleinen Auflösungen (800×600) läuft der untere Teil aus dem Bildschirm. VBox ist zentriert (`anchor_left=0.5`, `grow_vertical=2`), aber ohne Scroll-Container.

**Empfehlung:** VBox in `ScrollContainer` legen oder Layout responsiver machen.

---

## Lint-Ergebnisse (LSP)

Automatisches Linting via `godot-lsp_gdscript_lint` lieferte folgende Verletzungen:

### `src/scripts/game.gd` — 6 Errors, 10 Warnings

| Zeile | Severity | Regel | Beschreibung |
|---|---|---|---|
| 329 | WARN | `max-line-length` | 101 Zeichen (max 100) |
| 415 | ERROR | `loop-variable-name` | `_i` sollte snake_case sein |
| 417 | ERROR | `loop-variable-name` | `_j` sollte snake_case sein |
| 464 | ERROR | `loop-variable-name` | `_r` sollte snake_case sein |
| 618 | ERROR | `loop-variable-name` | `_c` sollte snake_case sein |
| 689 | WARN | `max-line-length` | 106 Zeichen |
| 781 | WARN | `max-line-length` | 106 Zeichen |
| 783 | WARN | `max-line-length` | **138 Zeichen** (Draw-Rect-Zeile) |
| 788 | WARN | `max-line-length` | 104 Zeichen |
| 789 | WARN | `max-line-length` | 104 Zeichen |
| 808 | WARN | `max-line-length` | 123 Zeichen (Draw-Piece-Signatur) |
| 817 | WARN | `max-line-length` | 132 Zeichen (Draw-Piece-Rect) |
| 868 | ERROR | `loop-variable-name` | `_i` sollte snake_case sein |
| 870 | ERROR | `loop-variable-name` | `_j` sollte snake_case sein |
| 908 | WARN | `max-line-length` | 121 Zeichen (RPC-Signatur) |
| 921 | WARN | `max-line-length` | 115 Zeichen |
| 938 | WARN | `max-line-length` | 101 Zeichen |

### `src/scripts/lobby.gd` — 1 Warning

| Zeile | Severity | Regel | Beschreibung |
|---|---|---|---|
| 31 | WARN | `no-else-return` | Überflüssiges `else` nach `return` |

### `src/scripts/summary.gd` — 3 Warnings

| Zeile | Severity | Regel | Beschreibung |
|---|---|---|---|
| 23 | WARN | `max-line-length` | **212 Zeichen** (`show_summary`-Signatur) |
| 44 | WARN | `max-line-length` | 123 Zeichen |
| 67 | WARN | `max-line-length` | 160 Zeichen (`_determine_winner`-Signatur) |
| 72 | WARN | `no-else-return` | Überflüssiges `else` nach `return` |

### `src/scripts/MultiplayerManager.gd` — Keine Verletzungen

**Anmerkung zu `loop-variable-name`:** Die GDScript-Konvention erlaubt `_`-Prefix für *unused* Loop-Variablen, der LSP-Checker meldet dies jedoch fälschlich als Formatierungsfehler. Dies ist ein bekannter Linter-Over-Report und kann mit `@warning_ignore("loop-variable-name")` oder Umbenennung zu `i`, `j` etc. behandelt werden.

---

## Architektur-Analyse

### Signal-Fluss (korrekt)

```
Lobby ──single_player_requested──→ Game._start_single_player
Lobby ──game_started──────────────→ Game._start_multiplayer
MultiplayerManager ──peer_disconnected──→ Game._on_peer_disconnected
MultiplayerManager ──game_start_requested──→ Lobby._on_game_start_requested → game_started
Summary ──ready_pressed──→ Game._on_summary_ready
Summary ──back_pressed──→ Game._on_summary_back
```

Die Signal-Kommunikation ist **akzyklisch** und gut entkoppelt. Keine zirkulären Abhängigkeiten.

### RPC-Struktur

| RPC | Transfer | Reliability | Caller |
|---|---|---|---|
| `_rpc_sync_state` | Board + Score | unreliable, call_local | Periodisch (`_send_sync`) |
| `_rpc_send_game_over` | End-Stats | reliable | Verlierer → Gewinner |
| `_rpc_opponent_ready` | — | reliable | Rematch-Ready |
| `_rpc_restart` | Rundennummer | reliable, call_local | Host → beide |
| `_rpc_start_game` | Host-Name | reliable | Host → Client |
| `_rpc_send_my_name` | Name | reliable | Beide → Gegner |

Die Trennlinie von unreliable/reliable ist architektonisch korrekt. **`call_local`** auf `_rpc_sync_state` und `_rpc_restart` ist sinnvoll, da beide Peers den Zustand aktualisieren müssen.

### Kritik am Abhängigkeitsgraph

`game.gd` hängt direkt ab von:
- `lobby` (Control) — Signal-Empfänger
- `summary` (Control) — Signal-Empfänger
- `mp_manager` (Node) — Funktionsaufrufe + Signal-Empfänger
- 8 UI-Labels (CanvasLayer)

`game.gd` referenziert Lobby und Summary direkt über `@onready`. Das ist für eine kleine Codebase akzeptabel, erschwert aber Unit-Testing der Spiellogik ohne UI.

---

## Szenen-Analyse

### `src/main.tscn` — Root-Szene

Struktur:
```
Main (Node2D, script: game.gd)
├── MultiplayerManager (Node, script: MultiplayerManager.gd)
├── UI (CanvasLayer)
│   ├── ScoreLabel, LinesLabel, LevelLabel, GameOverLabel
│   ├── NextLabel, OpponentScoreLabel, OpponentLabel
│   └── TimeLabel, RoundLabel
└── Overlays (CanvasLayer)
    ├── Lobby (Instanz von lobby.tscn)
    └── Summary (Instanz von summary.tscn)
```

**Positiv:** Saubere Trennung von UI (CanvasLayer) und Overlays (CanvasLayer über UI). MultiplayerManager als direktes Child von Main ist korrekt.

**Kritik:**
- `RoundLabel` und `TimeLabel` haben identische Offset-Positionen (`offset_top = 388`). `_draw_ui_labels()` (`game.gd:745-746`) überschreibt die Positionierung zwar zur Laufzeit, aber im Editor sehen sie überlappend aus — das kann beim Bearbeiten verwirren.
- Labels haben minimale `offset_right - offset_left` (1 Pixel) — das ist Absicht, da die Größe zur Laufzeit durch `_draw_ui_labels()` gesetzt wird. Nichtsdestotrotz ist das Layout in der Editor-Vorschau unbrauchbar.

### `src/ui/lobby.tscn` — Lobby

**Positiv:** Klare VBox-Struktur, zentriert, mit Logo-Icon (`TextureRect`).

**Kritik:**
- Kein `ScrollContainer` — siehe oben ("Lobby-Layout ohne Scroll-Container").
- `LogoIcon` ist absolut positioniert (`offset_left = 180`, `offset_top = 200`) — bei unterschiedlicher Auflösung wandert das Logo aus der Mitte. Sollte relativ zur VBox oder zu Ankerpunkten positioniert werden.

### `src/ui/summary.tscn` — Summary

**Positiv:** Panel mit MarginContainer, klare Struktur, Winner-Label und Ready-Button.

**Kritik:**
- `OpponentStats` hat `horizontal_alignment = 2` (right), `LocalStats` default (left). Das ist bei ungleicher String-Länge optisch unsauber — ein tabellenartiges Layout (GridContainer) wäre gleichmäßiger.

---

## Empfehlungen — Priorisierung

### Priorität 1 (Hoch — Bug-Fixes)

1. **Board-Initialisierungs-Bug** — `board.append(r)` aus innerem Loop herausziehen (`game.gd:419`). Eine Zeile Verschiebung, sofortige Wirkung.
2. **Winner-Detektion** — Score vergleichen statt nur `local_lost` (`summary.gd:67-73`).
3. **`stop()`-Race-Condition** — Reihenfolge `close()` → `null` vereinheitlichen (`MultiplayerManager.gd:61-68`).

### Priorität 2 (Mittel — Gameplay)

4. **Lock Delay** implementieren (0,5s, max 15 Resets) — macht das Spiel fair auf höheren Levels.
5. **Input-Vereinheitlichung** — alle Diskret-Eingaben in `_unhandled_input`, DAS-Timer via `delta` akkumulieren.

### Priorität 3 (Niedrig — Code-Qualität)

6. **`game.gd` aufteilen** — BoardRenderer, PieceFactory, TetrisGame, MultiplayerSync separieren.
7. **Typisierungen vervollständigen** — `mp_manager: Node`, `enet_peer`-Typ prüfen.
8. **Lint-Verletzungen beheben** — 6 Errors (loop-variable-name), 14 Warnings (max-line-length), 2 no-else-return. Lange `draw_rect`- und `show_summary`-Zeilen umbrechen.
9. **Toten Code entfernen** — `MultiplayerManager.local_player_name` wird nie verwendet.
10. **`opponent_game_over`-Flag** für Fallback-UI-Trigger nutzen.

### Priorität 4 (Optional — UX)

11. **Visuelles Feedback** — Line-Clear aufblinken, Level-Up Screen-Shake.
12. **Board-Größe** auf 20 sichtbare Reihen anpassen.
13. **Lobby-Scroll-Container** für kleine Auflösungen.

---

## Anhang — Datei-Bewertungen im Detail

### `src/scripts/game.gd` — Note 2.0

**Positiv:** Vollständige SRS-Implementierung, 7-Bag, DAS/ARR, Ghost-Piece, Multiplayer-Sync mit PackedByteArray, durchgängige Doc-Kommentare, klare Sektionierung.

**Negativ:** Board-Bug, Input-Split, fehlendes Lock Delay, 1016 Zeilen Monolith, 17 Lint-Verstöße, `_update_ui()` jeden Frame ohne Dirty-Flag, Ghost-Y wird jeden Frame neu berechnet.

### `src/scripts/lobby.gd` — Note 1.7

**Positiv:** Klar strukturiert, Signal-basiert, Form-Deaktivierung während Connect, PID im Titel für Multi-Instance-Testing, Port-Validierung.

**Negativ:** 1 Lint-Warning (`no-else-return`), keine Scroll-Unterstützung in der Szene.

### `src/scripts/MultiplayerManager.gd` — Note 2.7

**Positiv:** Kompakt, klare Signal-Schnittstelle, saubere Host/Join-Logik, korrekte Error-Handling für Server-Erstellung.

**Negativ:** Race Condition in `stop()`, `_cleanup`-vs-`stop()`-Inkonsistenz, ungenutzte `local_player_name`-Variable, `opponent_id = 1` für Client hardkodiert (Server-Unique-ID in Godot 4).

### `src/scripts/summary.gd` — Note 2.3

**Positiv:** Saubere Trennung von Anzeige und Logik, statische Zeit-Formatierung, Ready/Back-Signale.

**Negativ:** Winner-Detektion fehlerhaft, 4 Lint-Verstöße (davon 212-Zeichen-Signatur), `_determine_winner`-Parameter `_local` fälschlich als unused markiert.

### Szenen — Note 2.0

**Positiv:** Saubere Instanziierung von Lobby/Summary in `main.tscn`, UID-basierte Referenzen.

**Negativ:** Überlappende Default-Offsets (RoundLabel/TimeLabel), kein Scroll in Lobby, absolute Logo-Positionierung.

---

**Review erstellt von:** z-ai/glm-5.2 via OpenCode
**Datum:** 2026-07-10