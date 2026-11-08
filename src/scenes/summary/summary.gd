class_name GameSummary
extends Control
## Post-Game-Summary mit Statistiken, Winner-Anzeige und Rematch-Flow.
##
## Daten und Gewinner-Bestimmung liegen in [SummaryContext].

#region Signals
## Wird emittiert, wenn der Bereit- bzw. Nochmal-Button gedrückt wurde.
signal ready_pressed()
## Wird emittiert, wenn der Zurück-Button gedrückt wurde.
signal back_pressed()
#endregion

#region Private Vars
## Gespeicherte Daten der Auswertung, auch für die Neuberechnung bei verspäteten Werten.
var _context := SummaryContext.new()
#endregion

#region OnReady Vars
## Hintergrund-Panel der Summary.
@onready var panel: Panel = $Panel
## Titel ("GAME OVER", ggf. mit Rundennummer).
@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
## Label für die Runde, wird derzeit nur geleert.
@onready var round_label: Label = $Panel/Margin/VBox/RoundLabel
## Statistik-Label des lokalen Spielers.
@onready var local_stats: Label = $Panel/Margin/VBox/HBox/LocalStats
## Statistik-Label des Gegners.
@onready var opponent_stats: Label = $Panel/Margin/VBox/HBox/OpponentStats
## Button für Bereit bzw. Nochmal spielen.
@onready var ready_button: Button = $Panel/Margin/VBox/ButtonHBox/ReadyButton
## Anzeige, dass der Gegner bereit ist.
@onready var opponent_ready_label: Label = $Panel/Margin/VBox/ButtonHBox/OpponentReadyLabel
## Button zurück zur Lobby.
@onready var back_button: Button = $Panel/Margin/VBox/ButtonHBox/BackButton
## Label für den Gewinner.
@onready var winner_label: Label = $Panel/Margin/VBox/WinnerLabel
#endregion


#region Static Funcs
## Formatiert Sekunden als MM:SS.
## [param t] — Zeit in Sekunden.
## [b]return[/b] [String] — Formatierter Zeit-String.
static func _format_time(t: float) -> String:
	var minutes := int(t / 60.0)
	var seconds := int(t) % 60
	return "%02d:%02d" % [minutes, seconds]
#endregion


#region Lifecycle
## Blendet die Summary aus und verbindet die Buttons.
func _ready() -> void:
	hide()
	ready_button.pressed.connect(_on_ready_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
#endregion


#region Public Funcs
## Zeigt die Auswertung an.
## [param context] — Daten der beendeten Runde.
func show_summary(context: SummaryContext) -> void:
	_context = context
	if _context.round_num > 0:
		title_label.text = "GAME OVER - Round " + str(_context.round_num)
	else:
		title_label.text = "GAME OVER"
	round_label.text = ""
	_render_stats()
	if _context.is_multiplayer:
		winner_label.text = _context.determine_winner()
		winner_label.visible = not winner_label.text.is_empty()
	else:
		winner_label.hide()
	ready_button.show()
	_show_ready_button()
	back_button.show()
	show()


## Aktualisiert die gegnerischen Statistiken nachträglich (z. B. wenn der
## reliable Game-Over-RPC verspätet eintrifft) und bestimmt den Winner neu.
## [param opponent] — Neu erhaltene Gegner-Statistiken.
## [param opponent_lost] — Ob der Gegner getoppt hat.
func update_opponent_stats(opponent: Dictionary, opponent_lost: bool) -> void:
	_context.opponent_data = opponent
	_context.opponent_lost = opponent_lost
	_render_stats()
	winner_label.text = _context.determine_winner()
	winner_label.visible = not winner_label.text.is_empty()


## Zeigt an, dass der Gegner bereit für die nächste Runde ist.
func set_opponent_ready() -> void:
	opponent_ready_label.show()
#endregion


#region Private Funcs
## Rendert die Statistik-Labels aus den gespeicherten Daten.
func _render_stats() -> void:
	var fmt := _context.local_name + "\nScore: %d\nLines: %d\nLevel: %d\nTime: %s\nPieces: %d"
	local_stats.text = fmt % [
		_context.local_data.get("score", 0),
		_context.local_data.get("lines", 0),
		_context.local_data.get("level", 0),
		_format_time(_context.local_data.get("play_time", 0.0)),
		_context.local_data.get("pieces", 0),
	]
	if not _context.opponent_data.is_empty():
		var ofmt := _context.opp_name + "\nScore: %d\nLines: %d\nLevel: %d\nTime: %s\nPieces: %d"
		opponent_stats.text = ofmt % [
			_context.opponent_data.get("score", 0),
			_context.opponent_data.get("lines", 0),
			_context.opponent_data.get("level", 0),
			_format_time(_context.opponent_data.get("play_time", 0.0)),
			_context.opponent_data.get("pieces", 0),
		]
		opponent_stats.show()
	else:
		opponent_stats.hide()


## Aktiviert den Bereit-Button ("Ready" im Multiplayer, sonst "Play Again").
## Blendet außerdem die Gegner-Bereit-Anzeige aus.
func _show_ready_button() -> void:
	ready_button.disabled = false
	ready_button.text = "Ready" if _context.is_multiplayer else "Play Again"
	opponent_ready_label.hide()
#endregion


#region Signal Callbacks
## Sperrt den Button bis zur nächsten Runde und meldet [signal ready_pressed].
func _on_ready_button_pressed() -> void:
	ready_button.disabled = true
	ready_button.text = "Waiting..."
	ready_pressed.emit()


## Blendet die Summary aus und meldet [signal back_pressed].
func _on_back_button_pressed() -> void:
	opponent_ready_label.hide()
	hide()
	back_pressed.emit()
#endregion
