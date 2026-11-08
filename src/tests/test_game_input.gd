extends GutTest
## Prüft die Übersetzung von Tasten und das Tempo der Wiederholung in [GameInput].
##
## Wie GUT Tests findet und ausführt, steht in [code]test_board_codec.gd[/code].[br]
## Neu in dieser Datei: [method before_each] läuft vor jedem Test, jeder Test startet also mit einem
## frischen Objekt. [code]watch_signals[/code] lässt GUT die Signale des Objekts mitzählen, die
## Prüfungen [code]assert_signal_…[/code] werten das anschließend aus.[br]
## Eine echte Tastatur ist nicht nötig: [InputEventAction] stellt einen Tastendruck nach, und bei
## [method GameInput.update] sagt der Test selbst, welche Taste gerade gehalten wird.

#region Constants
## Sicherheitsabstand für Zeitvergleiche, weil sich Kommazahlen beim Rechnen leicht verschieben.
const TIME_MARGIN: float = 0.001
## Haltedauer bis zur ersten automatischen Wiederholung.
const FIRST_REPEAT: float = GameInput.DAS_DELAY + GameInput.DAS_RATE
#endregion

#region Private Vars
## Das geprüfte Objekt, vor jedem Test neu erzeugt.
var _game_input: GameInput
#endregion


#region Public Funcs

## Wird von GUT vor jedem einzelnen Test aufgerufen.
func before_each() -> void:
	_game_input = GameInput.new()
	watch_signals(_game_input)


## Hard Drop löst genau seinen Befehl aus. Die Rückgabe sagt dem Spiel: Ereignis verarbeitet.
func test_hard_drop_key_sends_command() -> void:
	assert_true(_press("hard_drop"))
	assert_signal_emit_count(_game_input, "hard_drop_requested", 1)


## Auch die Drehtaste löst genau einen Befehl aus.
func test_rotate_key_sends_command() -> void:
	assert_true(_press("rotate"))
	assert_signal_emit_count(_game_input, "rotate_requested", 1)


## Der erste Schritt passiert sofort beim Drücken, nicht erst nach der Wartezeit.
func test_move_keys_move_immediately() -> void:
	assert_true(_press("move_left"))
	assert_signal_emitted_with_parameters(_game_input, "move_requested", [-1, 0])

	assert_true(_press("move_right"))
	assert_signal_emitted_with_parameters(_game_input, "move_requested", [1, 0])


## Soft Drop ist ein einzelner Schritt nach unten.
func test_soft_drop_key_moves_down() -> void:
	assert_true(_press("soft_drop"))
	assert_signal_emitted_with_parameters(_game_input, "move_requested", [0, 1])


## Tasten, die kein Spielbefehl sind, muss das Spiel an andere weiterreichen können.
func test_other_events_are_not_handled() -> void:
	assert_false(_game_input.handle_event(InputEventMouseMotion.new()))
	assert_signal_not_emitted(_game_input, "move_requested")


## Ohne gedrückte Seitwärtstaste passiert nichts, auch wenn viel Zeit vergeht.
func test_update_does_nothing_without_a_pressed_key() -> void:
	_game_input.update(1.0, false, false)

	assert_signal_not_emitted(_game_input, "move_requested")


## Innerhalb der Wartezeit bleibt es beim ersten Schritt. Sonst rutschen Steine bei kurzem Antippen
## mehrere Spalten weit.
func test_no_repeat_before_delay_has_passed() -> void:
	_press("move_left")

	_game_input.update(FIRST_REPEAT - TIME_MARGIN, true, false)

	assert_signal_emit_count(_game_input, "move_requested", 1)


## Genau nach Wartezeit plus einem Abstand kommt die erste Wiederholung.
func test_first_repeat_arrives_after_delay() -> void:
	_press("move_left")

	_game_input.update(FIRST_REPEAT, true, false)

	assert_signal_emit_count(_game_input, "move_requested", 2)
	assert_signal_emitted_with_parameters(_game_input, "move_requested", [-1, 0])


## Ein langer Frame darf keine Schritte verschlucken: 3 Abstände ergeben 3 Wiederholungen.
func test_long_frame_catches_up_all_repeats() -> void:
	_press("move_right")

	_game_input.update(GameInput.DAS_DELAY + GameInput.DAS_RATE * 3 + TIME_MARGIN, false, true)

	assert_signal_emit_count(_game_input, "move_requested", 4)


## Viele kurze Frames ergeben dasselbe Tempo wie ein langer. So hängt das Spielgefühl nicht von der
## Bildrate ab. 60 Frames sind eine Sekunde: (1,0 - 0,17) / 0,05 = 16 Wiederholungen plus Druck.
func test_repeat_rate_does_not_depend_on_frame_rate() -> void:
	_press("move_left")

	for frame in range(60):
		_game_input.update(1.0 / 60.0, true, false)

	assert_signal_emit_count(_game_input, "move_requested", 17)


## Nach dem Loslassen hört die Wiederholung auf.
func test_releasing_key_stops_repeat() -> void:
	_press("move_left")

	assert_true(_release("move_left"))
	_game_input.update(1.0, true, false)

	assert_signal_emit_count(_game_input, "move_requested", 1)


## Beim schnellen Richtungswechsel liegt der neue Finger schon, bevor der alte loslässt. Das spätere
## Loslassen der alten Taste darf die neue Richtung nicht abbrechen.
func test_releasing_old_direction_keeps_new_direction() -> void:
	_press("move_left")
	_press("move_right")

	assert_false(_release("move_left"))
	_game_input.update(FIRST_REPEAT, false, true)

	assert_signal_emit_count(_game_input, "move_requested", 3)
	assert_signal_emitted_with_parameters(_game_input, "move_requested", [1, 0])


## Ein Richtungswechsel startet die Wartezeit neu, die Zeit der alten Taste zählt nicht mit.
func test_changing_direction_restarts_delay() -> void:
	_press("move_left")
	_game_input.update(GameInput.DAS_DELAY, true, false)

	_press("move_right")
	_game_input.update(GameInput.DAS_RATE, false, true)

	assert_signal_emit_count(_game_input, "move_requested", 2)


## Geht das Loslassen verloren, etwa hinter der Lobby, stoppt die Abfrage des Tastenzustands die
## Wiederholung. Auch ein erneutes Halten setzt sie danach nicht von selbst fort.
func test_lost_release_stops_repeat() -> void:
	_press("move_left")

	_game_input.update(0.0, false, false)
	_game_input.update(1.0, true, false)

	assert_signal_emit_count(_game_input, "move_requested", 1)

#endregion


#region Private Funcs

## Stellt das Drücken einer Taste nach.
## [return] — Rückgabe von [method GameInput.handle_event].
func _press(action: String) -> bool:
	return _send(action, true)


## Stellt das Loslassen einer Taste nach.
## [return] — Rückgabe von [method GameInput.handle_event].
func _release(action: String) -> bool:
	return _send(action, false)


## Baut das Ereignis für eine Aktion und reicht es an das geprüfte Objekt weiter.
func _send(action: String, pressed: bool) -> bool:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return _game_input.handle_event(event)

#endregion
