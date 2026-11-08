class_name BoardLogic
extends RefCounted
## Regeln des Spielfelds: Erzeugen, Kollision, Festsetzen und Löschen voller Reihen.
##
## Rein statisch und ohne Nodes, damit die Regeln isoliert getestet werden können.
## Punkte und Level gehören nicht hierher, die berechnet das Spiel aus der Anzahl gelöschter Reihen.
## Ein Board ist ein 2D-Array (TOTAL_ROWS × COLS), 0 = leer, sonst Stück-Typ.

#region Constants
## Spalten des Spielfelds.
const COLS: int = 10
## Sichtbare Reihen des Spielfelds.
const ROWS: int = 20
## Versteckte Reihen oberhalb des sichtbaren Bereichs.
const HIDDEN: int = 2
## Reihen insgesamt, sichtbar und versteckt.
const TOTAL_ROWS: int = ROWS + HIDDEN
#endregion


#region Static Funcs

## Erzeugt ein leeres Board mit unabhängigen Reihen.
## [b]return[/b] [Array] — Board mit TOTAL_ROWS Reihen à COLS Zellen, alle 0.
static func create_empty() -> Array:
	var board: Array = []
	for row in range(TOTAL_ROWS):
		board.append(_create_empty_row())
	return board


## Prüft ein Stück auf Kollision mit den Rändern und mit gefüllten Zellen.
## [param board] — Das Spielfeld.
## [param cells] — Zell-Positionen relativ zum Ursprung des Stücks.
## [param px] — X-Position des Ursprungs.
## [param py] — Y-Position des Ursprungs.
## [b]return[/b] [bool] — [code]true[/code], wenn die Position gültig ist.
## Zellen oberhalb des Boards gelten als frei.
static func is_valid(board: Array, cells: Array, px: int, py: int) -> bool:
	for cell in cells:
		var cx := px + int(cell.x)
		var cy := py + int(cell.y)
		if cx < 0 or cx >= COLS or cy >= TOTAL_ROWS:
			return false
		if cy < 0:
			continue
		if board[cy][cx] != 0:
			return false
	return true


## Ermittelt die unterste gültige Y-Position, die ein Stück von seiner Position aus erreicht.
## [param board] — Das Spielfeld.
## [param cells] — Zell-Positionen relativ zum Ursprung des Stücks.
## [param px] — X-Position des Ursprungs.
## [param py] — Startwert der Y-Position des Ursprungs.
## [b]return[/b] [int] — Y-Position des Aufsetzpunkts.
static func drop_y(board: Array, cells: Array, px: int, py: int) -> int:
	var y := py
	while is_valid(board, cells, px, y + 1):
		y += 1
	return y


## Schreibt ein Stück ins Board. Zellen außerhalb des Boards werden ignoriert.
## [param board] — Das Spielfeld, wird direkt verändert.
## [param cells] — Zell-Positionen relativ zum Ursprung des Stücks.
## [param px] — X-Position des Ursprungs.
## [param py] — Y-Position des Ursprungs.
## [param typ] — Stück-Typ, der in die Zellen geschrieben wird.
static func lock_piece(board: Array, cells: Array, px: int, py: int, typ: int) -> void:
	for cell in cells:
		var cx := px + int(cell.x)
		var cy := py + int(cell.y)
		if cy >= 0 and cy < TOTAL_ROWS and cx >= 0 and cx < COLS:
			board[cy][cx] = typ


## Entfernt alle vollen Reihen und lässt die Reihen darüber nachrutschen.
## [param board] — Das Spielfeld, wird direkt verändert.
## [b]return[/b] [int] — Anzahl der gelöschten Reihen.
static func clear_full_lines(board: Array) -> int:
	var cleared := 0
	# Von unten nach oben: Nach dem Nachrutschen wird dieselbe Reihe erneut geprüft.
	var row := TOTAL_ROWS - 1
	while row >= 0:
		if _is_row_full(board[row]):
			for upper in range(row, 0, -1):
				board[upper] = board[upper - 1].duplicate()
			board[0] = _create_empty_row()
			cleared += 1
		else:
			row -= 1
	return cleared


## Erzeugt eine leere Reihe.
## [b]return[/b] [Array] — Reihe mit COLS Zellen, alle 0.
static func _create_empty_row() -> Array:
	var row: Array = []
	row.resize(COLS)
	row.fill(0)
	return row


## Prüft, ob eine Reihe keine leere Zelle mehr enthält.
## [param row] — Die zu prüfende Reihe.
static func _is_row_full(row: Array) -> bool:
	return not row.has(0)

#endregion
