extends Control

signal ready_pressed()
signal back_pressed()

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var round_label: Label = $Panel/Margin/VBox/RoundLabel
@onready var local_stats: Label = $Panel/Margin/VBox/HBox/LocalStats
@onready var opponent_stats: Label = $Panel/Margin/VBox/HBox/OpponentStats
@onready var ready_button: Button = $Panel/Margin/VBox/ButtonHBox/ReadyButton
@onready var opponent_ready_label: Label = $Panel/Margin/VBox/ButtonHBox/OpponentReadyLabel
@onready var back_button: Button = $Panel/Margin/VBox/ButtonHBox/BackButton
@onready var winner_label: Label = $Panel/Margin/VBox/WinnerLabel


func _ready() -> void:
	hide()
	ready_button.pressed.connect(_on_ready_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)


func show_summary(local_data: Dictionary, opponent: Dictionary = {}, is_multiplayer: bool = false, round_num: int = 0, local_name: String = "YOU", opp_name: String = "OPPONENT", local_lost: bool = false) -> void:
	if round_num > 0:
		title_label.text = "GAME OVER - Round " + str(round_num)
		round_label.text = ""
	else:
		title_label.text = "GAME OVER"
		round_label.text = ""
	_update_stats(local_data, opponent, local_name, opp_name)
	if is_multiplayer:
		var w: String = _determine_winner(local_data, opponent, local_lost, local_name, opp_name)
		winner_label.text = w
		winner_label.show()
		ready_button.show()
		_show_ready_button()
	else:
		winner_label.hide()
		ready_button.hide()
	back_button.show()
	show()


func _update_stats(d: Dictionary, opponent: Dictionary, local_name: String = "YOU", opp_name: String = "OPPONENT") -> void:
	var fmt := local_name + "\nScore: %d\nLines: %d\nLevel: %d\nTime: %s\nPieces: %d"
	local_stats.text = fmt % [
		d.get("score", 0),
		d.get("lines", 0),
		d.get("level", 0),
		_format_time(d.get("play_time", 0.0)),
		d.get("pieces", 0),
	]
	if not opponent.is_empty():
		var ofmt := opp_name + "\nScore: %d\nLines: %d\nLevel: %d\nTime: %s\nPieces: %d"
		opponent_stats.text = ofmt % [
			opponent.get("score", 0),
			opponent.get("lines", 0),
			opponent.get("level", 0),
			_format_time(opponent.get("play_time", 0.0)),
			opponent.get("pieces", 0),
		]
		opponent_stats.show()
	else:
		opponent_stats.hide()


func _determine_winner(_local: Dictionary, opponent: Dictionary, local_lost: bool = false, local_name: String = "YOU", opp_name: String = "OPPONENT") -> String:
	if opponent.is_empty():
		return ""
	if local_lost:
		return opp_name + " WINS!"
	else:
		return local_name + " WINS!"


static func _format_time(t: float) -> String:
	var minutes := int(t / 60.0)
	var seconds := int(t) % 60
	return "%02d:%02d" % [minutes, seconds]


func set_opponent_ready() -> void:
	opponent_ready_label.show()


func _show_ready_button() -> void:
	ready_button.disabled = false
	ready_button.text = "Ready"
	opponent_ready_label.hide()


func _on_ready_button_pressed() -> void:
	ready_button.disabled = true
	ready_button.text = "Waiting..."
	ready_pressed.emit()


func _on_back_button_pressed() -> void:
	opponent_ready_label.hide()
	hide()
	back_pressed.emit()
