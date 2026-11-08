extends Node2D
## Hauptspiel-Logik für Bloxel Tetris.
##
## Verwaltet Spielfeld, Eingabe, Kollision, Punktzahl, Ghost-Piece,
## DAS/ARR, Lock-Delay und Multiplayer-Sync via ENet-RPCs.
## Stück-Definitionen und Board-Serialisierung sind in [PieceData] bzw.
## [BoardCodec] ausgelagert.

#region Enums

## Tetromino-Typen mit den Werten 1–7 (passen zu PieceData-Keys).
enum PieceType {
	I = 1, ## Gerader Viererblock.
	O = 2, ## Quadratblock.
	T = 3, ## T-förmiger Block.
	S = 4, ## S-förmiger Block.
	Z = 5, ## Z-förmiger Block.
	J = 6, ## L-förmiger Block (Spiegelung).
	L = 7, ## L-förmiger Block.
}

#endregion

#region Constants

## Spalten im Spielfeld.
const COLS := BoardLogic.COLS
## Sichtbare Reihen im Spielfeld.
const ROWS := BoardLogic.ROWS
## Versteckte Reihen oberhalb des sichtbaren Bereichs (Spawn-Schutz).
const HIDDEN := BoardLogic.HIDDEN
## Gesamtreihen inklusive verstecktem Bereich.
const TOTAL_ROWS := BoardLogic.TOTAL_ROWS
## Pixelgrösse einer Zelle.
const CELL := 32
## Y-Position des Spielfeld-Origins.
const BOARD_Y := 40
## Y-Position der Vorschau.
const PREVIEW_Y := 196
## Sync-Intervall für Multiplayer (Sekunden).
const SYNC_INTERVAL := 0.1
## Anteil des Viewports für den lokalen Spielbereich (Multiplayer).
const LOCAL_AREA_FACTOR := 0.62
## Skalierungsfaktor für Gegner-Zellen im Multiplayer.
const OPP_CELL_FACTOR := 0.55
## Dicke des Grid-Rands in Pixeln.
const GRID_BORDER := 4
## Horizontaler Offset der UI-Elemente.
const UI_OFFSET_X := 20
## Vertikaler Offset der UI-Elemente.
const UI_OFFSET_Y := 20
## Lock-Delay: Sekunden bis ein aufliegendes Stück einrastet.
const LOCK_DELAY := 0.5
## Maximalanzall Lock-Resets durch Move/Rotate bevor erzwungenes Locken.
const MAX_LOCK_RESETS := 15
## Gnadenfrist (Sekunden) für reliable RPC, bevor Sync-Fallback die Summary zeigt.
const OPP_TOP_GRACE := 1.5

#endregion

#region Node references

## Label für die aktuelle Punktzahl.
@onready var score_label: Label = $UI/ScoreLabel
## Label für die Anzahl gelöschter Linien.
@onready var lines_label: Label = $UI/LinesLabel
## Label für das aktuelle Level.
@onready var level_label: Label = $UI/LevelLabel
## Label für "Nächstes Piece".
@onready var next_label: Label = $UI/NextLabel
## Overlay-Label für "Game Over".
@onready var game_over_label: Label = $UI/GameOverLabel
## Label für die gegnerische Punktzahl (Multiplayer).
@onready var opponent_score_label: Label = $UI/OpponentScoreLabel
## Label für den gegnerischen Namen.
@onready var opponent_label: Label = $UI/OpponentLabel
## Lobby-Overlay (Start/Bereit).
@onready var lobby: Control = $Overlays/Lobby
## Summary-Overlay (Post-Game-Statistiken).
@onready var summary: Control = $Overlays/Summary
## Referenz auf den MultiplayerManager (ENet).
@onready var mp_manager: Node = $MultiplayerManager
## Label für die vergangene Spielzeit.
@onready var time_label: Label = $UI/TimeLabel
## Label für die aktuelle Runde (Multiplayer).
@onready var round_num_label: Label = $UI/RoundLabel

#endregion

#region Game state

## Spielfeld als 2D-Array (TOTAL_ROWS × COLS), 0 = leer, sonst PieceType.
var board: Array = []
## Aktuell fallendes Piece: {type, rot, x, y}.
var current: Dictionary = {}
## PieceType des nächsten Pieces (Vorschau).
var next_type: int = 0
## 7-Bag für zufällige Piece-Reihenfolge.
var bag: Array[int] = []
## Aktuelle Punktzahl.
var score: int = 0
## Insgesamt gelöschte Linien.
var lines_total: int = 0
## Aktuelles Level (beeinflusst Fallgeschwindigkeit).
var level: int = 0
## Ob das Spiel vorbei ist.
var game_over: bool = false

#endregion

#region Stats

## Bisherige Spielzeit in Sekunden (für Statistik).
var play_time: float = 0.0
## Anzahl gelandeter Pieces (für Statistik).
var total_pieces: int = 0

#endregion

#region Timers

## Timer für automatischen Drop (kumuliert delta).
var drop_timer: float = 0.0
## Intervall zwischen Drop-Schritten (abhängig von Level).
var drop_interval: float = 0.8
## Lock-Delay-Timer: zählt hoch, solange das Stück aufliegt.
var lock_timer: float = 0.0
## Anzahl Lock-Resets in der aktuellen Aufliege-Phase.
var lock_reset_count: int = 0
## Soft-Drop-Status, einmal pro Frame erfasst (konsistent im while-Loop).
var _soft_drop_active: bool = false

## Übersetzt Tasten in Spielbefehle und wiederholt gehaltene Seitwärtsbewegungen.
var _game_input := GameInput.new()

#endregion

#region Layout

## X-Position des Spielfeld-Origins.
var board_x: int = 0
## X-Position der Vorschau.
var preview_x: int = 0
## X-Position der UI-Labels.
var ui_x: int = 0

#endregion

#region Multiplayer state

## Ob eine Multiplayer-Sitzung aktiv ist.
var is_multiplayer: bool = false
## Ob dieser Client der Host ist.
var is_host: bool = false
## Timer für periodische Boardsyncs.
var sync_timer: float = 0.0

## Dekodiertes Gegner-Board (für Anzeige).
var opponent_board: Array = []
## Gegnerische Punktzahl.
var opponent_score: int = 0
## Gegnerische Linienanzahl.
var opponent_lines: int = 0
## Gegnerisches Level.
var opponent_level: int = 0
## Ob der Gegner Game Over hat.
var opponent_game_over: bool = false

## Zellengrösse des Gegner-Boards (skaliert).
var opp_cell: int = 0
## X-Position des Gegner-Boards.
var opp_board_x: int = 0
## Y-Position des Gegner-Boards.
var opp_board_y: int = BOARD_Y

## Ob der Host bereit ist für nächste Runde.
var host_ready: bool = false
## Ob der Gegner bereit ist für nächste Runde.
var opponent_ready: bool = false

## Lokaler Spielername.
var player_name: String = ""
## Name des Gegners.
var opponent_name: String = "Opponent"
## Aktuelle Runden-Nummer.
var round_num: int = 0
## Ob der lokale Spieler verloren hat (getoppt).
var i_lost: bool = false
## Ob der Gegner getoppt hat (per RPC/Sync erfahren).
var opponent_topped_out: bool = false
## Gnadenfrist-Timer für reliable RPC, bevor Sync-Fallback greift.
var opp_top_grace: float = 0.0

#endregion

#region Lifecycle

## Initialisiert Layout und verbindet UI-Signale.
func _ready() -> void:
	_init_layout()
	game_over_label.hide()
	opponent_score_label.hide()
	opponent_label.hide()
	time_label.hide()
	round_num_label.hide()
	_set_ui_font_sizes()
	lobby.single_player_requested.connect(_start_single_player)
	lobby.game_started.connect(_start_multiplayer)
	summary.ready_pressed.connect(_on_summary_ready)
	summary.back_pressed.connect(_on_summary_back)
	mp_manager.peer_disconnected.connect(_on_peer_disconnected)
	lobby.visibility_changed.connect(_on_lobby_visibility_changed)
	_game_input.move_requested.connect(_move)
	_game_input.rotate_requested.connect(_rotate_cw)
	_game_input.hard_drop_requested.connect(_hard_drop)
	lobby.show()
	_on_lobby_visibility_changed()
	for c in $UI.get_children():
		if c is Control:
			c.focus_mode = Control.FOCUS_NONE


## Hauptspiel-Schleife: Drop-Timer, Lock-Delay, DAS-Repeat und Multiplayer-Sync.
## Diskrete Eingaben werden in [_unhandled_input] verarbeitet.
func _process(delta: float) -> void:
	if lobby.visible or summary.visible:
		return
	if game_over:
		play_time += delta
		_update_ui()
		return
	play_time += delta
	# Gegner-Top-Out: warte kurz auf reliable RPC, dann Sync-Fallback.
	if opponent_topped_out and not game_over:
		opp_top_grace -= delta
		if opp_top_grace <= 0.0:
			_on_opponent_topped_out()
			return
	# Soft-Drop-Status einmal pro Frame erfassen (konsistent im while-Loop).
	_soft_drop_active = Input.is_action_pressed("soft_drop")
	var interval := drop_interval / 10.0 if _soft_drop_active else drop_interval
	drop_timer += delta
	while drop_timer >= interval:
		drop_timer -= interval
		_drop()
		if game_over:
			break
	# Lock-Delay: aufliegendes Stück einrasten lassen, sonst Timer zurücksetzen.
	if not game_over and not current.is_empty():
		if _is_resting():
			lock_timer += delta
			if lock_timer >= LOCK_DELAY:
				_lock()
		else:
			lock_timer = 0.0
			lock_reset_count = 0
	# DAS-Repeat: gehaltene Taste ist in _process sicher auswertbar.
	var left_pressed := Input.is_action_pressed("move_left")
	var right_pressed := Input.is_action_pressed("move_right")
	_game_input.update(delta, left_pressed, right_pressed)
	if is_multiplayer:
		sync_timer += delta
		if sync_timer >= SYNC_INTERVAL:
			sync_timer -= SYNC_INTERVAL
			_send_sync()
	_update_ui()


## Verarbeitet alle diskreten Eingaben (Move, Rotate, Hard/Soft-Drop, Restart).
func _unhandled_input(event: InputEvent) -> void:
	# Einzelspieler-Neustart über Hard-Drop bei Game Over.
	if game_over and not is_multiplayer and not lobby.visible and not summary.visible:
		if event.is_action_pressed("hard_drop"):
			_start_single_player()
			get_viewport().set_input_as_handled()
		return
	if lobby.visible or summary.visible or game_over:
		return
	if _game_input.handle_event(event):
		get_viewport().set_input_as_handled()


## Zeichnet Spielfeld, Gegner-Board, Vorschau und Overlays.
func _draw() -> void:
	if lobby.visible:
		var vs := get_viewport().get_visible_rect().size
		draw_rect(Rect2(Vector2(), vs), Color(0.05, 0.05, 0.08))
		return
	var origin := Vector2i(board_x, BOARD_Y)
	GameRenderer.draw_board(self, board, origin, CELL)
	_draw_active_piece(origin)
	if is_multiplayer and not opponent_board.is_empty():
		var opp_origin := Vector2i(opp_board_x, opp_board_y)
		GameRenderer.draw_board(
				self, opponent_board, opp_origin, opp_cell, GameRenderer.OPPONENT_ALPHA,
		)
	preview_x = board_x + COLS * CELL + GRID_BORDER * 2 + UI_OFFSET_X
	GameRenderer.draw_preview(self, next_type, Vector2(preview_x, PREVIEW_Y - 4), CELL)
	if game_over or summary.visible:
		var vs := get_viewport().get_visible_rect().size
		draw_rect(Rect2(Vector2(), vs), Color(0, 0, 0, 0.55))
	_draw_ui_labels()

#endregion

#region Initialization

## Berechnet Board- und UI-Positionen basierend auf Viewport-Grösse.
func _init_layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	if is_multiplayer:
		var local_area_w := vp.x * LOCAL_AREA_FACTOR
		board_x = int((local_area_w - COLS * CELL) / 2)
		opp_cell = int(CELL * OPP_CELL_FACTOR)
		var opp_area_w := vp.x - local_area_w - GRID_BORDER * 2
		opp_board_x = int(local_area_w + GRID_BORDER * 2 + (opp_area_w - COLS * opp_cell) / 2)
		opp_board_y = int((vp.y - ROWS * opp_cell) / 2)
	else:
		board_x = int((vp.x - COLS * CELL) / 2)
	preview_x = board_x + COLS * CELL + GRID_BORDER * 2 + UI_OFFSET_X
	ui_x = preview_x


## Setzt konsistente Schriftgrössen für alle UI-Labels.
func _set_ui_font_sizes() -> void:
	var fs := 20
	score_label.add_theme_font_size_override("font_size", fs)
	lines_label.add_theme_font_size_override("font_size", fs)
	level_label.add_theme_font_size_override("font_size", fs)
	next_label.add_theme_font_size_override("font_size", fs)
	game_over_label.add_theme_font_size_override("font_size", 48)
	opponent_score_label.add_theme_font_size_override("font_size", fs)
	opponent_label.add_theme_font_size_override("font_size", fs)
	time_label.add_theme_font_size_override("font_size", fs)

#endregion

#region Game start

## Startet ein Einzelspieler-Spiel.
func _start_single_player() -> void:
	is_multiplayer = false
	is_host = false
	_init_layout()
	_new_game()


## Startet eine Multiplayer-Runde mit Sync-Vorbereitung.
func _start_multiplayer() -> void:
	is_multiplayer = true
	is_host = mp_manager.is_host
	player_name = lobby.player_name
	i_lost = false
	opponent_topped_out = false
	if round_num == 0:
		round_num = 1
	_init_layout()
	opponent_score_label.show()
	opponent_label.show()
	round_num_label.show()
	_update_opponent_label()
	sync_timer = 0.0
	opponent_board = []
	opponent_score = 0
	opponent_lines = 0
	opponent_level = 0
	opponent_game_over = false
	host_ready = false
	opponent_ready = false
	if is_host and mp_manager.opponent_id > 0:
		_rpc_start_game.rpc_id(mp_manager.opponent_id, player_name)
	_new_game()


## Initialisiert Board, Bag und Zustand für ein neues Spiel.
func _new_game() -> void:
	board = BoardLogic.create_empty()
	bag = []
	score = 0
	lines_total = 0
	level = 0
	game_over = false
	play_time = 0.0
	total_pieces = 0
	drop_interval = 0.8
	drop_timer = 0.0
	lock_timer = 0.0
	lock_reset_count = 0
	opponent_topped_out = false
	opp_top_grace = 0.0
	next_type = _pop_bag()
	_spawn()
	_update_ui()
	game_over_label.hide()
	summary.hide()
	time_label.show()
	queue_redraw()

#endregion

#region Piece generation

## Zieht den nächsten Piece-Typ aus dem 7-Bag.
## Füllt den Bag mit einer neuen Shuffle-Runde, wenn er zur Neige geht.
## [return] — PieceType-Wert des nächsten Pieces.
func _pop_bag() -> int:
	if bag.size() <= 1:
		var p: Array[int] = [1, 2, 3, 4, 5, 6, 7]
		p.shuffle()
		bag += p
	return bag.pop_front()


## Berechnet die Zell-Positionen eines Pieces in einer gegebenen Rotation.
## [param typ] — Der PieceType.
## [param rot] — Anzahl der 90°-Drehungen im Uhrzeigersinn (0–3).
## [return] — Array von Vector2-Zellkoordinaten.
func _get_cells(typ: int, rot: int) -> Array:
	return PieceData.get_cells(typ, rot)

#endregion

#region Spawn / movement / rotation

## Spawnt das nächste Piece und prüft auf Game Over (Block-Out).
func _spawn() -> void:
	current = {type = next_type, rot = 0, x = 3, y = HIDDEN - 2}
	if next_type == PieceType.O:
		current.x = 4
	next_type = _pop_bag()
	if not _is_valid(_get_cells(current.type, current.rot), current.x, current.y):
		game_over = true
		_trigger_game_over()
	drop_timer = 0.0
	lock_timer = 0.0
	lock_reset_count = 0
	queue_redraw()


## Prüft Kollision eines Pieces mit Board-Grenzen und gefüllten Zellen.
## [param cels] — Zell-Positionen relativ zum Piece.
## [param px] — X-Position des Piece-Origins.
## [param py] — Y-Position des Piece-Origins.
## [return] — true wenn die Position gültig ist.
func _is_valid(cels: Array, px: int, py: int) -> bool:
	return BoardLogic.is_valid(board, cels, px, py)


## Prüft, ob das aktuelle Stück nicht weiter nach unten kann (aufliegt).
func _is_resting() -> bool:
	if current.is_empty():
		return false
	return not _is_valid(_get_cells(current.type, current.rot), current.x, current.y + 1)


## Setzt Lock-Timer/Reset-Counter zurück, wenn das Stück aufliegt und das
## Reset-Limit noch nicht erreicht ist (Infinite-Spin-Schutz).
func _try_reset_lock() -> void:
	if lock_reset_count < MAX_LOCK_RESETS and _is_resting():
		lock_timer = 0.0
		lock_reset_count += 1


## Bewegt das aktuelle Piece um (dx, dy), wenn möglich.
## [return] — true wenn die Bewegung ausgeführt wurde.
func _move(dx: int, dy: int) -> bool:
	if game_over:
		return false
	if _is_valid(_get_cells(current.type, current.rot), current.x + dx, current.y + dy):
		current.x += dx
		current.y += dy
		# Horizontale Bewegung darf Lock-Delay zurücksetzen (Infinite Spin begrenzt).
		if dy == 0:
			_try_reset_lock()
		queue_redraw()
		return true
	return false


## Rotiert das Piece 90° im Uhrzeigersinn mit SRS Wall-Kicks.
func _rotate_cw() -> void:
	if game_over:
		return
	var nr: int = (current.rot + 1) % 4
	var cels: Array = _get_cells(current.type, nr)
	# O-Stück rotiert an Ort und Stelle (keine Wall-Kicks).
	if current.type == PieceType.O:
		if _is_valid(cels, current.x, current.y):
			current.rot = nr
			_try_reset_lock()
			queue_redraw()
		return
	# Wall-Kick-Tabelle: probiere Offsets der Reihe nach.
	var kicks: Array = PieceData.get_kicks(current.type, current.rot, nr)
	for k in kicks:
		if _is_valid(cels, current.x + k.x, current.y + k.y):
			current.rot = nr
			current.x += k.x
			current.y += k.y
			_try_reset_lock()
			queue_redraw()
			return

#endregion

#region Drop / lock / clear

## Lässt das Piece sofort auf die unterste gültige Position fallen.
## Bonus-Punkte: 2 pro zurückgelegter Reihe.
func _hard_drop() -> void:
	if game_over:
		return
	var gy := _ghost_y()
	# 2 Punkte pro zurückgelegter Reihe (Hard-Drop-Bonus).
	score += (gy - current.y) * 2
	current.y = gy
	_lock()


## Führt einen Drop-Schritt aus. Lockt NICHT mehr sofort — das übernimmt
## das Lock-Delay in [_process]. Soft-Drop-Scoring nutzt den pro Frame
## erfassten [_soft_drop_active]-Status.
func _drop() -> void:
	if game_over:
		return
	if _move(0, 1):
		if _soft_drop_active:
			score += 1
			_update_ui()


## Schreibt das aktuelle Piece ins Board, löscht volle Linien und spawnt nächstes.
func _lock() -> void:
	var cels: Array = _get_cells(current.type, current.rot)
	BoardLogic.lock_piece(board, cels, current.x, current.y, current.type)
	total_pieces += 1
	lock_timer = 0.0
	lock_reset_count = 0
	_clear_lines()
	_spawn()
	_update_ui()
	queue_redraw()


## Entfernt volle Reihen, aktualisiert Punktzahl und Level.
## Punkte-Skala: 1/2/3/4 Lines → 100/300/500/800 × (level + 1).
func _clear_lines() -> void:
	var cleared := BoardLogic.clear_full_lines(board)
	if cleared > 0:
		var points_per_line: Array[int] = [0, 100, 300, 500, 800]
		score += points_per_line[cleared] * (level + 1)
		lines_total += cleared
		var new_level := int(lines_total * 0.1)
		if new_level > level:
			level = new_level
			drop_interval = max(0.05, 0.8 - level * 0.05)

#endregion

#region Game over

## Zeigt Game-Over-Label, benachrichtigt Gegner (MP) und zeigt Summary (SP).
func _trigger_game_over() -> void:
	i_lost = true
	game_over_label.show()
	_send_game_over_to_opponent()
	_show_summary_with_synced_opponent_data()


## Sendet eigene End-Statistiken per RPC an den Gegner.
func _send_game_over_to_opponent() -> void:
	if not is_multiplayer:
		return
	Log.info("[PID:%d] Game Over gesendet:" % OS.get_process_id(), _build_local_stats())
	_rpc_send_game_over.rpc_id(
		mp_manager.opponent_id,
		score, lines_total, level, play_time, total_pieces,
	)


## Sendet als Gewinner die eigenen End-Statistiken an den Verlierer.
## Dessen Summary kennt sonst nur die Sync-Daten, in denen Zeit und Steine fehlen.
func _send_final_stats_to_opponent() -> void:
	if not is_multiplayer:
		return
	Log.info("[PID:%d] Endwerte gesendet:" % OS.get_process_id(), _build_local_stats())
	_rpc_send_final_stats.rpc_id(
		mp_manager.opponent_id,
		score, lines_total, level, play_time, total_pieces,
	)


## Baut das lokale Statistik-Dictionary für die Summary.
func _build_local_stats() -> Dictionary:
	return {
		score = score,
		lines = lines_total,
		level = level,
		play_time = play_time,
		pieces = total_pieces,
	}


## Zeigt die Summary mit den bereits bekannten Gegner-Daten.
func _show_summary_with_synced_opponent_data() -> void:
	var local_stats := _build_local_stats()
	if is_multiplayer:
		var os := {
			score = opponent_score,
			lines = opponent_lines,
			level = opponent_level,
			play_time = 0.0,
			pieces = 0,
		}
		summary.show_summary(
			local_stats, os, true, round_num,
			player_name, opponent_name,
			i_lost, opponent_topped_out,
		)
	else:
		summary.show_summary(local_stats, {}, false)
	queue_redraw()


## Zeigt die Summary mit per RPC empfangenen Gegner-Daten.
## [param opponent_stats] — Vom Gegner erhaltene End-Statistiken.
func _show_summary_with_received_data(opponent_stats: Dictionary) -> void:
	var local_stats := _build_local_stats()
	summary.show_summary(
		local_stats, opponent_stats, true, round_num,
		player_name, opponent_name,
		i_lost, opponent_topped_out,
	)
	queue_redraw()


## Sync-Fallback: Gegner hat getoppt, reliable RPC blieb aus.
## Zeigt die Summary mit den aus Sync bekannten (ggf. unvollständigen) Daten.
func _on_opponent_topped_out() -> void:
	if game_over:
		return
	i_lost = false
	opponent_topped_out = true
	game_over = true
	game_over_label.show()
	var local_stats := _build_local_stats()
	var os := {
		score = opponent_score,
		lines = opponent_lines,
		level = opponent_level,
		play_time = 0.0,
		pieces = 0,
	}
	summary.show_summary(
		local_stats, os, true, round_num,
		player_name, opponent_name,
		i_lost, opponent_topped_out,
	)
	queue_redraw()

#endregion

#region Ghost

## Ermittelt die Y-Position des Ghost-Pieces (weichster Drop).
## [return] — Y-Position des Aufsetzpunkts.
func _ghost_y() -> int:
	var cels: Array = _get_cells(current.type, current.rot)
	return BoardLogic.drop_y(board, cels, current.x, current.y)

#endregion

#region UI

## Aktualisiert das Label mit dem gegnerischen Namen und Host-Status.
func _update_opponent_label() -> void:
	if not is_multiplayer:
		return
	var label: String = opponent_name
	if is_host:
		label += " (Joined)"
	else:
		label += " (Host)"
	opponent_label.text = label


## Aktualisiert alle UI-Labels mit aktuellem Spielstand.
func _update_ui() -> void:
	score_label.text = "SCORE: " + str(score)
	lines_label.text = "LINES: " + str(lines_total)
	level_label.text = "LEVEL: " + str(level)
	var mins := int(play_time / 60.0)
	var secs := int(play_time) % 60
	time_label.text = "TIME: %02d:%02d" % [mins, secs]
	if is_multiplayer:
		round_num_label.text = "ROUND: " + str(round_num)
		opponent_score_label.text = opponent_name + " SCORE: " + str(opponent_score)
	else:
		round_num_label.text = ""


## Positioniert UI-Labels im _draw()-Kontext.
func _draw_ui_labels() -> void:
	var go_y := BOARD_Y + int(ROWS * CELL * 0.5) - 24
	var ly := BOARD_Y + 4
	score_label.position = Vector2(ui_x, ly)
	lines_label.position = Vector2(ui_x, ly + 26)
	level_label.position = Vector2(ui_x, ly + 52)
	time_label.position = Vector2(ui_x, ly + 78)
	round_num_label.position = Vector2(ui_x, ly + 104)
	game_over_label.position = Vector2(board_x, go_y)
	next_label.position = Vector2(preview_x, PREVIEW_Y - 28)
	if is_multiplayer:
		opponent_score_label.position = Vector2(opp_board_x, opp_board_y + ROWS * opp_cell + 8)
		opponent_label.position = Vector2(opp_board_x, opp_board_y - 24)

#endregion

#region Drawing

## Zeichnet Ghost Piece und aktives Stück auf das eigene Spielfeld.
## [param origin] — Pixelposition des Spielfelds.
func _draw_active_piece(origin: Vector2i) -> void:
	if game_over or current.is_empty():
		return
	var ghost_pos := Vector2i(current.x, _ghost_y())
	var piece_pos := Vector2i(current.x, current.y)
	GameRenderer.draw_piece(
			self, current.type, current.rot, ghost_pos, GameRenderer.GHOST_ALPHA, origin, CELL,
	)
	GameRenderer.draw_piece(self, current.type, current.rot, piece_pos, 1.0, origin, CELL)

#endregion

#region Multiplayer sync

## Sendet Board-Zustand und Score per RPC an den Gegner (periodisch).
func _send_sync() -> void:
	# Nur senden wenn Verbindung aktiv und Peer-ID gültig.
	if not is_instance_valid(mp_manager) or mp_manager.opponent_id <= 0:
		return
	if multiplayer.multiplayer_peer == null:
		return
	# Board als kompaktes Byte-Array übertragen (sparsamer als Array[Array]).
	var data := BoardCodec.encode(board, TOTAL_ROWS, COLS)
	_rpc_sync_state.rpc_id(mp_manager.opponent_id, data, score, lines_total, level, game_over)


## Setzt das Spiel zurück und zeigt die Lobby bei Verbindungsabbruch.
func _on_peer_disconnected() -> void:
	opponent_board = []
	opponent_score = 0
	opponent_game_over = true
	opponent_topped_out = false
	game_over = true
	round_num = 0
	i_lost = false
	opponent_name = "Opponent"
	summary.hide()
	game_over_label.hide()
	time_label.hide()
	round_num_label.hide()
	opponent_score_label.hide()
	opponent_label.hide()
	lobby.reset()
	lobby.show()
	lobby.set_status("Opponent disconnected")
	queue_redraw()

#endregion

#region RPCs

@rpc("any_peer", "unreliable", "call_local")
## [rpc("any_peer", "unreliable", "call_local")] Synchronisiert Board und Score vom Gegner.
func _rpc_sync_state(
		data: PackedByteArray,
		opp_score: int,
		opp_lines: int,
		opp_level: int,
		opp_game_over: bool,
) -> void:
	if not is_multiplayer:
		return
	opponent_board = BoardCodec.decode(data, TOTAL_ROWS, COLS)
	opponent_score = opp_score
	opponent_lines = opp_lines
	opponent_level = opp_level
	opponent_game_over = opp_game_over
	# Gegner-Top-Out: Gnadenfrist starten, damit reliable RPC die vollen Stats liefern kann.
	if opp_game_over and not game_over and not opponent_topped_out:
		opponent_topped_out = true
		opp_top_grace = OPP_TOP_GRACE
	queue_redraw()


@rpc("any_peer", "reliable")
## [rpc("any_peer", "reliable")] Empfängt Game-Over-Daten vom Gegner und zeigt Summary.
func _rpc_send_game_over(
		opp_score: int, opp_lines: int, opp_level: int, opp_time: float, opp_pieces: int,
) -> void:
	var os := {
		score = opp_score,
		lines = opp_lines,
		level = opp_level,
		play_time = opp_time,
		pieces = opp_pieces,
	}
	Log.info("[PID:%d] Game Over empfangen:" % OS.get_process_id(), os)
	if game_over:
		# Wir haben bereits getoppt → gleichzeitiges Top-Out: Stats ergänzen
		# und Winner über Score-Vergleich neu bestimmen.
		if is_multiplayer:
			opponent_topped_out = true
			summary.update_opponent_stats(os, true)
		# Beim gleichzeitigen Top-Out haben beide Seiten ihre Werte bereits gesendet.
		if not i_lost:
			_send_final_stats_to_opponent()
		return
	i_lost = false
	opponent_topped_out = true
	game_over = true
	game_over_label.show()
	_show_summary_with_received_data(os)
	_send_final_stats_to_opponent()


@rpc("any_peer", "reliable")
## [rpc("any_peer", "reliable")] Ergänzt die Summary des Verlierers um die Endwerte des Gewinners.
func _rpc_send_final_stats(
		opp_score: int, opp_lines: int, opp_level: int, opp_time: float, opp_pieces: int,
) -> void:
	var os := {
		score = opp_score,
		lines = opp_lines,
		level = opp_level,
		play_time = opp_time,
		pieces = opp_pieces,
	}
	Log.info("[PID:%d] Endwerte empfangen:" % OS.get_process_id(), os)
	summary.update_opponent_stats(os, opponent_topped_out)


@rpc("any_peer", "reliable")
## [rpc("any_peer", "reliable")] Markiert Gegner als bereit;
## startet nächste Runde wenn beide bereit.
func _rpc_opponent_ready() -> void:
	opponent_ready = true
	summary.set_opponent_ready()
	if is_host and host_ready and opponent_ready:
		_rpc_restart.rpc(round_num + 1)


@rpc("any_peer", "reliable", "call_local")
## [rpc("any_peer", "reliable", "call_local")] Startet eine neue Runde mit erhöhter Rundenzahl.
func _rpc_restart(new_r: int = 0) -> void:
	round_num = new_r
	_reset_multiplayer_state()
	_new_game()


@rpc("any_peer", "reliable")
## [rpc("any_peer", "reliable")] Startet das Spiel auf Gegner-Seite; speichert Host-Namen.
func _rpc_start_game(host_name: String) -> void:
	opponent_name = host_name
	lobby.hide()
	_start_multiplayer()
	if not is_host and mp_manager.opponent_id > 0:
		_rpc_send_my_name.rpc_id(mp_manager.opponent_id, player_name)


@rpc("any_peer", "reliable")
## [rpc("any_peer", "reliable")] Empfängt den Namen des Gegners.
func _rpc_send_my_name(n: String) -> void:
	opponent_name = n
	_update_opponent_label()


## Setzt den Multiplayer-Zustand für eine neue Runde zurück.
func _reset_multiplayer_state() -> void:
	host_ready = false
	opponent_ready = false
	opponent_board = []
	opponent_score = 0
	opponent_lines = 0
	opponent_level = 0
	opponent_game_over = false
	opponent_topped_out = false
	opp_top_grace = 0.0
	summary.hide()

#endregion

#region Summary callbacks

## Blendet die Spielanzeige aus, solange die Lobby offen ist.
func _on_lobby_visibility_changed() -> void:
	$UI.visible = not lobby.visible


## Reagiert auf "Bereit"-Button in der Summary — startet nächste Runde.
func _on_summary_ready() -> void:
	if is_multiplayer:
		host_ready = true
		_rpc_opponent_ready.rpc_id(mp_manager.opponent_id)
		if is_host and host_ready and opponent_ready:
			_rpc_restart.rpc(round_num + 1)
	else:
		_start_single_player()


## Reagiert auf "Zurück"-Button — beendet Multiplayer-Session und zeigt Lobby.
func _on_summary_back() -> void:
	if is_multiplayer:
		mp_manager.stop()
	game_over = false
	opponent_board = []
	opponent_score = 0
	opponent_game_over = false
	opponent_topped_out = false
	round_num = 0
	i_lost = false
	opponent_name = "Opponent"
	game_over_label.hide()
	time_label.hide()
	round_num_label.hide()
	opponent_score_label.hide()
	opponent_label.hide()
	lobby.reset()
	lobby.show()
	queue_redraw()

#endregion