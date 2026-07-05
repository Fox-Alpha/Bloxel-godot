extends Node2D

# ── Enums ──────────────────────────────────────────

enum PieceType {
	I = 1,
	O = 2,
	T = 3,
	S = 4,
	Z = 5,
	J = 6,
	L = 7,
}

# ── Constants ──────────────────────────────────────

const COLS := 10
const ROWS := 19
const HIDDEN := 2
const TOTAL_ROWS := ROWS + HIDDEN
const CELL := 32
const BOARD_Y := 40
const PREVIEW_Y := 196
const GHOST_ALPHA := 0.25
const DAS_DELAY := 0.17
const DAS_RATE := 0.05
const SYNC_INTERVAL := 0.1
const LOCAL_AREA_FACTOR := 0.62
const OPP_CELL_FACTOR := 0.55
const GRID_BORDER := 4
const UI_OFFSET_X := 20
const UI_OFFSET_Y := 20

# ── Node references ────────────────────────────────

@onready var score_label: Label = $UI/ScoreLabel
@onready var lines_label: Label = $UI/LinesLabel
@onready var level_label: Label = $UI/LevelLabel
@onready var next_label: Label = $UI/NextLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var opponent_score_label: Label = $UI/OpponentScoreLabel
@onready var opponent_label: Label = $UI/OpponentLabel
@onready var lobby: Control = $Overlays/Lobby
@onready var summary: Control = $Overlays/Summary
@onready var mp_manager = $MultiplayerManager
@onready var time_label: Label = $UI/TimeLabel
@onready var round_num_label: Label = $UI/RoundLabel

# ── Piece data (initialized in _init_data) ─────────

var colors: Dictionary = {}
var piece_cells: Dictionary = {}
var piece_size: Dictionary = {}
var jlstz_kicks: Dictionary = {}
var i_kicks: Dictionary = {}

# ── Game state ─────────────────────────────────────

var board: Array = []
var current: Dictionary = {}
var next_type: int = 0
var bag: Array[int] = []
var score: int = 0
var lines_total: int = 0
var level: int = 0
var game_over: bool = false

# ── Stats (for summary) ────────────────────────────

var play_time: float = 0.0
var total_pieces: int = 0

# ── Timers ─────────────────────────────────────────

var drop_timer: float = 0.0
var drop_interval: float = 0.8
var das_timer: float = 0.0
var das_dir: int = 0

# ── Layout ─────────────────────────────────────────

var board_x: int = 0
var preview_x: int = 0
var ui_x: int = 0

# ── Multiplayer state ──────────────────────────────

var is_multiplayer: bool = false
var is_host: bool = false
var sync_timer: float = 0.0

var opponent_board: Array = []
var opponent_score: int = 0
var opponent_lines: int = 0
var opponent_level: int = 0
var opponent_game_over: bool = false

var opp_cell: int = 0
var opp_board_x: int = 0
var opp_board_y: int = BOARD_Y

var host_ready: bool = false
var opponent_ready: bool = false

var player_name: String = ""
var opponent_name: String = "Opponent"
var round_num: int = 0
var i_lost: bool = false

# ══════════════════════════════════════════════════
#  Lifecycle
# ══════════════════════════════════════════════════

func _ready() -> void:
	_init_data()
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
	lobby.show()
	for c in $UI.get_children():
		if c is Control:
			c.focus_mode = Control.FOCUS_NONE


func _process(delta: float) -> void:
	if lobby.visible or summary.visible:
		return
	if game_over:
		play_time += delta
		_update_ui()
		if Input.is_action_just_pressed("hard_drop") and not is_multiplayer:
			_start_single_player()
		return
	play_time += delta
	if Input.is_action_just_pressed("soft_drop"):
		_move(0, 1)
	var interval := drop_interval / 10.0 if Input.is_action_pressed("soft_drop") else drop_interval
	drop_timer += delta
	while drop_timer >= interval:
		drop_timer -= interval
		_drop()
		if game_over:
			break
	if Input.is_action_just_pressed("move_left"):
		_move(-1, 0)
		das_dir = -1
		das_timer = 0.0
	elif Input.is_action_just_pressed("move_right"):
		_move(1, 0)
		das_dir = 1
		das_timer = 0.0
	if Input.is_action_just_released("move_left") and das_dir == -1:
		das_dir = 0
	if Input.is_action_just_released("move_right") and das_dir == 1:
		das_dir = 0
	if das_dir != 0:
		var action_name := "move_left" if das_dir == -1 else "move_right"
		if Input.is_action_pressed(action_name):
			das_timer += delta
			while das_timer >= DAS_DELAY + DAS_RATE:
				das_timer -= DAS_RATE
				_move(das_dir, 0)
		else:
			das_dir = 0
	if is_multiplayer:
		sync_timer += delta
		if sync_timer >= SYNC_INTERVAL:
			sync_timer -= SYNC_INTERVAL
			_send_sync()
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if lobby.visible or summary.visible or game_over:
		return
	if event.is_action_pressed("hard_drop"):
		_hard_drop()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("rotate"):
		_rotate_cw()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if lobby.visible:
		var vs := get_viewport().get_visible_rect().size
		draw_rect(Rect2(Vector2(), vs), Color(0.05, 0.05, 0.08))
		return
	_draw_board(board_x, BOARD_Y, CELL, false)
	if is_multiplayer and not opponent_board.is_empty():
		_draw_board(opp_board_x, opp_board_y, opp_cell, true)
	preview_x = board_x + COLS * CELL + GRID_BORDER * 2 + UI_OFFSET_X
	_draw_preview()
	if game_over or summary.visible:
		var vs := get_viewport().get_visible_rect().size
		draw_rect(Rect2(Vector2(), vs), Color(0, 0, 0, 0.55))
	_draw_ui_labels()


# ══════════════════════════════════════════════════
#  Initialization
# ══════════════════════════════════════════════════

func _init_data() -> void:
	colors = {
		PieceType.I: Color(0.0, 0.95, 0.95),
		PieceType.O: Color(0.95, 0.95, 0.0),
		PieceType.T: Color(0.6, 0.1, 0.95),
		PieceType.S: Color(0.0, 0.95, 0.1),
		PieceType.Z: Color(0.95, 0.0, 0.1),
		PieceType.J: Color(0.1, 0.5, 0.95),
		PieceType.L: Color(0.95, 0.5, 0.0),
	}
	colors[0] = Color(0.15, 0.15, 0.18)
	piece_cells = {
		PieceType.I: [Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1)],
		PieceType.O: [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
		PieceType.T: [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
		PieceType.S: [Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1)],
		PieceType.Z: [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)],
		PieceType.J: [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
		PieceType.L: [Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
	}
	piece_size = {
		PieceType.I: Vector2i(4, 4),
		PieceType.O: Vector2i(2, 2),
		PieceType.T: Vector2i(3, 3),
		PieceType.S: Vector2i(3, 3),
		PieceType.Z: Vector2i(3, 3),
		PieceType.J: Vector2i(3, 3),
		PieceType.L: Vector2i(3, 3),
	}
	jlstz_kicks = {
		"0>1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
		"1>0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
		"1>2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
		"2>1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
		"2>3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
		"3>2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
		"3>0": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
		"0>3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	}
	i_kicks = {
		"0>1": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
		"1>0": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
		"1>2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
		"2>1": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
		"2>3": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
		"3>2": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
		"3>0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
		"0>3": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
	}


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


# ══════════════════════════════════════════════════
#  Game start
# ══════════════════════════════════════════════════

func _start_single_player() -> void:
	is_multiplayer = false
	is_host = false
	_init_layout()
	_new_game()


func _start_multiplayer() -> void:
	is_multiplayer = true
	is_host = mp_manager.is_host
	player_name = lobby.player_name
	i_lost = false
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


func _new_game() -> void:
	board = []
	for _i in range(TOTAL_ROWS):
		var r: Array = []
		for _j in range(COLS):
			r.append(0)
		board.append(r)
	bag = []
	score = 0
	lines_total = 0
	level = 0
	game_over = false
	play_time = 0.0
	total_pieces = 0
	drop_interval = 0.8
	drop_timer = 0.0
	next_type = _pop_bag()
	_spawn()
	_update_ui()
	game_over_label.hide()
	summary.hide()
	time_label.show()
	queue_redraw()


# ══════════════════════════════════════════════════
#  Piece generation
# ══════════════════════════════════════════════════

func _pop_bag() -> int:
	if bag.size() <= 1:
		var p: Array[int] = [1, 2, 3, 4, 5, 6, 7]
		p.shuffle()
		bag += p
	return bag.pop_front()


func _get_cells(typ: int, rot: int) -> Array:
	var base: Array = piece_cells[typ]
	var size: Vector2i = piece_size[typ]
	var c: Array = base.duplicate()
	var w: int = size.x
	var h: int = size.y
	for _r in range(rot):
		var n: Array = []
		for cell in c:
			n.append(Vector2(h - 1 - cell.y, cell.x))
		c = n
		var t := w
		w = h
		h = t
	return c


# ══════════════════════════════════════════════════
#  Spawn / movement / rotation
# ══════════════════════════════════════════════════

func _spawn() -> void:
	current = {type = next_type, rot = 0, x = 3, y = HIDDEN - 2}
	if next_type == PieceType.O:
		current.x = 4
	next_type = _pop_bag()
	if not _is_valid(_get_cells(current.type, current.rot), current.x, current.y):
		game_over = true
		_trigger_game_over()
	drop_timer = 0.0
	queue_redraw()


func _is_valid(cels: Array, px: int, py: int) -> bool:
	for cell in cels:
		var cx := px + int(cell.x)
		var cy := py + int(cell.y)
		if cx < 0 or cx >= COLS or cy >= TOTAL_ROWS:
			return false
		if cy < 0:
			continue
		if board[cy][cx] != 0:
			return false
	return true


func _move(dx: int, dy: int) -> bool:
	if game_over:
		return false
	if _is_valid(_get_cells(current.type, current.rot), current.x + dx, current.y + dy):
		current.x += dx
		current.y += dy
		queue_redraw()
		return true
	return false


func _rotate_cw() -> void:
	if game_over:
		return
	var nr: int = (current.rot + 1) % 4
	var cels: Array = _get_cells(current.type, nr)
	var kicks: Dictionary
	match current.type:
		PieceType.I:
			kicks = i_kicks
		PieceType.O:
			kicks = {}
		_:
			kicks = jlstz_kicks
	if kicks.is_empty():
		if _is_valid(cels, current.x, current.y):
			current.rot = nr
			queue_redraw()
		return
	var key: String = str(current.rot) + ">" + str(nr)
	if not kicks.has(key):
		return
	for k in kicks[key]:
		if _is_valid(cels, current.x + k.x, current.y + k.y):
			current.rot = nr
			current.x += k.x
			current.y += k.y
			queue_redraw()
			return


# ══════════════════════════════════════════════════
#  Drop / lock / clear
# ══════════════════════════════════════════════════

func _hard_drop() -> void:
	if game_over:
		return
	var cels: Array = _get_cells(current.type, current.rot)
	var gy: int = current.y
	while _is_valid(cels, current.x, gy + 1):
		gy += 1
	score += (gy - current.y) * 2
	current.y = gy
	_lock()


func _drop() -> void:
	if game_over:
		return
	if not _move(0, 1):
		_lock()
	elif Input.is_action_pressed("soft_drop"):
		score += 1
		_update_ui()


func _lock() -> void:
	var cels: Array = _get_cells(current.type, current.rot)
	for cell in cels:
		var cx: int = current.x + int(cell.x)
		var cy: int = current.y + int(cell.y)
		if cy >= 0 and cy < TOTAL_ROWS and cx >= 0 and cx < COLS:
			board[cy][cx] = current.type
	total_pieces += 1
	_clear_lines()
	_spawn()
	_update_ui()
	queue_redraw()


func _clear_lines() -> void:
	var cleared := 0
	var r := TOTAL_ROWS - 1
	while r >= 0:
		var full := true
		for c in range(COLS):
			if board[r][c] == 0:
				full = false
				break
		if full:
			for rr in range(r, 0, -1):
				board[rr] = board[rr - 1].duplicate()
			var empty: Array = []
			for _c in range(COLS):
				empty.append(0)
			board[0] = empty
			cleared += 1
		else:
			r -= 1
	if cleared > 0:
		var points_per_line: Array[int] = [0, 100, 300, 500, 800]
		score += points_per_line[cleared] * (level + 1)
		lines_total += cleared
		var new_level := int(lines_total * 0.1)
		if new_level > level:
			level = new_level
			drop_interval = max(0.05, 0.8 - level * 0.05)


# ══════════════════════════════════════════════════
#  Game over
# ══════════════════════════════════════════════════

func _trigger_game_over() -> void:
	i_lost = true
	game_over_label.show()
	_send_game_over_to_opponent()
	_show_summary_with_synced_opponent_data()


func _send_game_over_to_opponent() -> void:
	if not is_multiplayer:
		return
	_rpc_send_game_over.rpc_id(
		mp_manager.opponent_id,
		score, lines_total, level, play_time, total_pieces,
	)


func _show_summary_with_synced_opponent_data() -> void:
	var local_stats := {
		score = score,
		lines = lines_total,
		level = level,
		play_time = play_time,
		pieces = total_pieces,
	}
	if is_multiplayer:
		var os := {
			score = opponent_score,
			lines = opponent_lines,
			level = opponent_level,
			play_time = 0.0,
			pieces = 0,
		}
		summary.show_summary(local_stats, os, true, round_num, player_name, opponent_name, i_lost)
	else:
		summary.show_summary(local_stats, {}, false)
	queue_redraw()


func _show_summary_with_received_data(opponent_stats: Dictionary) -> void:
	var local_stats := {
		score = score,
		lines = lines_total,
		level = level,
		play_time = play_time,
		pieces = total_pieces,
	}
	summary.show_summary(local_stats, opponent_stats, true, round_num, player_name, opponent_name, i_lost)
	queue_redraw()


# ══════════════════════════════════════════════════
#  Ghost
# ══════════════════════════════════════════════════

func _ghost_y() -> int:
	var cels: Array = _get_cells(current.type, current.rot)
	var gy: int = current.y
	while _is_valid(cels, current.x, gy + 1):
		gy += 1
	return gy


# ══════════════════════════════════════════════════
#  UI
# ══════════════════════════════════════════════════

func _update_opponent_label() -> void:
	if not is_multiplayer:
		return
	var label: String = opponent_name
	if is_host:
		label += " (Joined)"
	else:
		label += " (Host)"
	opponent_label.text = label


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


# ══════════════════════════════════════════════════
#  Drawing
# ══════════════════════════════════════════════════

func _draw_board(origin_x: int, origin_y: int, cell_size: int, is_opponent: bool) -> void:
	var border := Color(0.3, 0.3, 0.4)
	var bg := Color(0.05, 0.05, 0.08)
	var grid := Color(0.2, 0.2, 0.25)
	var bw := COLS * cell_size
	var bh := ROWS * cell_size
	draw_rect(Rect2(origin_x - 2, origin_y - 2, bw + 4, bh + 4), border)
	draw_rect(Rect2(origin_x, origin_y, bw, bh), bg)
	for c in range(COLS + 1):
		var x := origin_x + c * cell_size
		draw_line(Vector2(x, origin_y), Vector2(x, origin_y + bh), grid)
	for r in range(ROWS + 1):
		var y := origin_y + r * cell_size
		draw_line(Vector2(origin_x, y), Vector2(origin_x + bw, y), grid)
	var src_board: Array = opponent_board if is_opponent else board
	for row in range(HIDDEN, TOTAL_ROWS):
		for col in range(COLS):
			var t: int = src_board[row][col] if not src_board.is_empty() and row < src_board.size() else 0
			if t != 0:
				var rect := Rect2(origin_x + col * cell_size + 1, origin_y + (row - HIDDEN) * cell_size + 1, cell_size - 2, cell_size - 2)
				draw_rect(rect, _get_opp_color(t) if is_opponent else colors[t])
	if not is_opponent and not game_over and not current.is_empty():
		var g := _ghost_y()
		_draw_piece(current.type, current.rot, current.x, g, GHOST_ALPHA, origin_x, origin_y, cell_size)
		_draw_piece(current.type, current.rot, current.x, current.y, 1.0, origin_x, origin_y, cell_size)


func _get_opp_color(typ: int) -> Color:
	var c: Color = colors[typ]
	c.a = 0.7
	return c


func _draw_piece(typ: int, rot: int, px: int, py: int, alpha: float, origin_x: int, origin_y: int, cell_size: int) -> void:
	var cels: Array = _get_cells(typ, rot)
	var col: Color = colors[typ]
	col.a = alpha
	for cell in cels:
		var cx := px + int(cell.x)
		var cy := py + int(cell.y)
		if cy < HIDDEN or cy >= TOTAL_ROWS:
			continue
		draw_rect(Rect2(origin_x + cx * cell_size + 1, origin_y + (cy - HIDDEN) * cell_size + 1, cell_size - 2, cell_size - 2), col)


func _draw_preview() -> void:
	if not piece_cells.has(next_type):
		return
	var cels: Array = piece_cells[next_type]
	var col: Color = colors[next_type]
	var ps := CELL * 0.8
	var py := PREVIEW_Y - 4
	draw_rect(Rect2(preview_x - 4, py, 5 * ps, 5 * ps), Color(0.1, 0.1, 0.12))
	for cell in cels:
		draw_rect(Rect2(preview_x + cell.x * ps, py + cell.y * ps, ps - 2, ps - 2), col)


# ══════════════════════════════════════════════════
#  Multiplayer sync
# ══════════════════════════════════════════════════

func _send_sync() -> void:
	if not is_instance_valid(mp_manager) or mp_manager.opponent_id <= 0:
		return
	if multiplayer.multiplayer_peer == null:
		return
	var data := _encode_board(board)
	_rpc_sync_state.rpc_id(mp_manager.opponent_id, data, score, lines_total, level, game_over)


func _encode_board(b: Array) -> PackedByteArray:
	var pba := PackedByteArray()
	pba.resize(TOTAL_ROWS * COLS)
	var idx := 0
	for row in range(TOTAL_ROWS):
		for col in range(COLS):
			pba[idx] = b[row][col]
			idx += 1
	return pba


func _decode_board(data: PackedByteArray) -> Array:
	var b: Array = []
	for _i in range(TOTAL_ROWS):
		var r: Array = []
		for _j in range(COLS):
			r.append(0)
		b.append(r)
	var idx := 0
	for row in range(TOTAL_ROWS):
		for col in range(COLS):
			b[row][col] = data[idx]
			idx += 1
	return b


func _on_peer_disconnected() -> void:
	opponent_board = []
	opponent_score = 0
	opponent_game_over = true
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


# ══════════════════════════════════════════════════
#  RPCs
# ══════════════════════════════════════════════════

@rpc("any_peer", "unreliable", "call_local")
func _rpc_sync_state(data: PackedByteArray, opp_score: int, opp_lines: int, opp_level: int, opp_game_over: bool) -> void:
	if not is_multiplayer:
		return
	opponent_board = _decode_board(data)
	opponent_score = opp_score
	opponent_lines = opp_lines
	opponent_level = opp_level
	opponent_game_over = opp_game_over
	queue_redraw()


@rpc("any_peer", "reliable")
func _rpc_send_game_over(opp_score: int, opp_lines: int, opp_level: int, opp_time: float, opp_pieces: int) -> void:
	if game_over:
		return
	i_lost = false
	game_over = true
	game_over_label.show()
	var os := {
		score = opp_score,
		lines = opp_lines,
		level = opp_level,
		play_time = opp_time,
		pieces = opp_pieces,
	}
	_show_summary_with_received_data(os)


@rpc("any_peer", "reliable")
func _rpc_opponent_ready() -> void:
	opponent_ready = true
	summary.set_opponent_ready()
	if is_host and host_ready and opponent_ready:
		_rpc_restart.rpc(round_num + 1)


@rpc("any_peer", "reliable", "call_local")
func _rpc_restart(new_r: int = 0) -> void:
	round_num = new_r
	_reset_multiplayer_state()
	_new_game()


@rpc("any_peer", "reliable")
func _rpc_start_game(host_name: String) -> void:
	opponent_name = host_name
	lobby.hide()
	_start_multiplayer()
	if not is_host and mp_manager.opponent_id > 0:
		_rpc_send_my_name.rpc_id(mp_manager.opponent_id, player_name)


@rpc("any_peer", "reliable")
func _rpc_send_my_name(n: String) -> void:
	opponent_name = n
	_update_opponent_label()


func _reset_multiplayer_state() -> void:
	host_ready = false
	opponent_ready = false
	opponent_board = []
	opponent_score = 0
	opponent_lines = 0
	opponent_level = 0
	opponent_game_over = false
	summary.hide()


# ══════════════════════════════════════════════════
#  Summary callbacks
# ══════════════════════════════════════════════════

func _on_summary_ready() -> void:
	if is_multiplayer:
		host_ready = true
		_rpc_opponent_ready.rpc_id(mp_manager.opponent_id)
		if is_host and host_ready and opponent_ready:
			_rpc_restart.rpc(round_num + 1)
	else:
		_start_single_player()


func _on_summary_back() -> void:
	if is_multiplayer:
		mp_manager.stop()
	game_over = false
	opponent_board = []
	opponent_score = 0
	opponent_game_over = false
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
