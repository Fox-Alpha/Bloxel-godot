class_name GameInput
extends RefCounted
## Übersetzt Tasten in Spielbefehle und wiederholt gehaltene Seitwärtsbewegungen (DAS/ARR).
##
## Kennt weder Board noch Stück und sendet nur Signale. Der Tastenzustand kommt als Parameter
## herein, damit das Tempo der Wiederholung ohne echte Tastatur getestet werden kann.

#region Signals
## Das aktuelle Stück soll sich bewegen.
## [param dx] — Spalten nach rechts (negativ: nach links).
## [param dy] — Reihen nach unten.
signal move_requested(dx: int, dy: int)
## Das aktuelle Stück soll sich im Uhrzeigersinn drehen.
signal rotate_requested
## Das aktuelle Stück soll sofort fallen.
signal hard_drop_requested
#endregion

#region Constants
## Haltedauer in Sekunden, bis die automatische Wiederholung beginnt (DAS).
const DAS_DELAY: float = 0.17
## Abstand der automatischen Wiederholungen in Sekunden (ARR).
const DAS_RATE: float = 0.05
#endregion

#region Private Vars
## Richtung der gehaltenen Seitwärtstaste: -1 links, 1 rechts, 0 keine.
var _das_dir: int = 0
## Laufzeit der gehaltenen Seitwärtstaste in Sekunden.
var _das_timer: float = 0.0
#endregion


#region Public Funcs

## Verarbeitet ein Eingabe-Ereignis.
## [param event] — Das Ereignis aus [code]_unhandled_input[/code].
## [b]return[/b] [bool] — [code]true[/code], wenn das Ereignis ein Spielbefehl war.
func handle_event(event: InputEvent) -> bool:
	if event.is_action_pressed("hard_drop"):
		hard_drop_requested.emit()
	elif event.is_action_pressed("rotate"):
		rotate_requested.emit()
	elif event.is_action_pressed("move_left"):
		_start_move(-1)
	elif event.is_action_pressed("move_right"):
		_start_move(1)
	elif event.is_action_pressed("soft_drop"):
		move_requested.emit(0, 1)
	elif event.is_action_released("move_left") and _das_dir == -1:
		_das_dir = 0
	elif event.is_action_released("move_right") and _das_dir == 1:
		_das_dir = 0
	else:
		return false
	return true


## Wiederholt die Seitwärtsbewegung, solange die zugehörige Taste gehalten wird.
## [param delta] — Vergangene Zeit in Sekunden.
## [param left_pressed] — Ob die Taste für links gerade gedrückt ist.
## [param right_pressed] — Ob die Taste für rechts gerade gedrückt ist.
func update(delta: float, left_pressed: bool, right_pressed: bool) -> void:
	if _das_dir == 0:
		return
	var held := left_pressed if _das_dir == -1 else right_pressed
	if not held:
		# Das Loslassen kann unbemerkt bleiben, z. B. während die Lobby offen war.
		_das_dir = 0
		return
	_das_timer += delta
	while _das_timer >= DAS_DELAY + DAS_RATE:
		_das_timer -= DAS_RATE
		move_requested.emit(_das_dir, 0)

#endregion


#region Private Funcs

## Führt den ersten Schritt einer Seitwärtsbewegung aus und startet die Wiederholung neu.
## [param direction] — -1 für links, 1 für rechts.
func _start_move(direction: int) -> void:
	move_requested.emit(direction, 0)
	_das_dir = direction
	_das_timer = 0.0

#endregion
