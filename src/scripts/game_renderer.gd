class_name GameRenderer
extends RefCounted
## Zeichnet Spielfeld, Stücke und Vorschau auf ein übergebenes [CanvasItem].
##
## Godot erlaubt Zeichenbefehle nur während des [code]_draw()[/code] eines Nodes. Alle Funktionen
## hier dürfen deshalb nur aus dem [code]_draw()[/code] des übergebenen Nodes aufgerufen werden.

#region Constants
## Transparenz des Ghost Pieces.
const GHOST_ALPHA: float = 0.25
## Transparenz der Blöcke auf dem Spielfeld des Gegners.
const OPPONENT_ALPHA: float = 0.7
## Farbe des Rahmens um das Spielfeld.
const BORDER_COLOR := Color(0.3, 0.3, 0.4)
## Hintergrundfarbe des Spielfelds.
const BACKGROUND_COLOR := Color(0.05, 0.05, 0.08)
## Farbe der Gitterlinien.
const GRID_COLOR := Color(0.2, 0.2, 0.25)
## Hintergrundfarbe der Vorschau.
const PREVIEW_BACKGROUND_COLOR := Color(0.1, 0.1, 0.12)
## Größe der Vorschau-Zellen im Verhältnis zu einer Spielfeld-Zelle.
const PREVIEW_CELL_FACTOR: float = 0.8
## Kantenlänge des Vorschau-Hintergrunds in Vorschau-Zellen.
const PREVIEW_BOX_CELLS: int = 5
## Abstand des Vorschau-Hintergrunds links von den Zellen.
const PREVIEW_PADDING: int = 4
#endregion


#region Static Funcs

## Zeichnet ein Spielfeld mit Rahmen, Gitter und festgesetzten Blöcken.
## [param canvas] — Node, dessen [code]_draw()[/code] gerade läuft.
## [param board] — Das Spielfeld, siehe [BoardLogic].
## [param origin] — Pixelposition der linken oberen Ecke.
## [param cell_size] — Pixelgröße einer Zelle.
## [param block_alpha] — Transparenz der Blöcke.
static func draw_board(
	canvas: CanvasItem,
	board: Array,
	origin: Vector2i,
	cell_size: int,
	block_alpha: float = 1.0,
) -> void:
	var width := BoardLogic.COLS * cell_size
	var height := BoardLogic.ROWS * cell_size
	canvas.draw_rect(Rect2(origin.x - 2, origin.y - 2, width + 4, height + 4), BORDER_COLOR)
	canvas.draw_rect(Rect2(origin.x, origin.y, width, height), BACKGROUND_COLOR)
	for col in range(BoardLogic.COLS + 1):
		var x := origin.x + col * cell_size
		canvas.draw_line(Vector2(x, origin.y), Vector2(x, origin.y + height), GRID_COLOR)
	for row in range(BoardLogic.ROWS + 1):
		var y := origin.y + row * cell_size
		canvas.draw_line(Vector2(origin.x, y), Vector2(origin.x + width, y), GRID_COLOR)
	# Vor der ersten Runde ist das Board noch leer, dann läuft die Schleife nicht.
	for row in range(BoardLogic.HIDDEN, mini(BoardLogic.TOTAL_ROWS, board.size())):
		for col in range(BoardLogic.COLS):
			var typ: int = board[row][col]
			if typ != 0:
				var color := PieceData.get_color(typ)
				color.a = block_alpha
				canvas.draw_rect(_cell_rect(origin, col, row, cell_size), color)


## Zeichnet ein einzelnes Stück auf dem Spielfeld. Zellen im versteckten Bereich entfallen.
## [param canvas] — Node, dessen [code]_draw()[/code] gerade läuft.
## [param typ] — Stück-Typ.
## [param rot] — Rotation (0–3).
## [param cell_pos] — Position des Stücks in Zellen.
## [param alpha] — Transparenz des Stücks.
## [param origin] — Pixelposition des Spielfelds.
## [param cell_size] — Pixelgröße einer Zelle.
static func draw_piece(
	canvas: CanvasItem,
	typ: int,
	rot: int,
	cell_pos: Vector2i,
	alpha: float,
	origin: Vector2i,
	cell_size: int,
) -> void:
	var color := PieceData.get_color(typ)
	color.a = alpha
	for cell in PieceData.get_cells(typ, rot):
		var col := cell_pos.x + int(cell.x)
		var row := cell_pos.y + int(cell.y)
		if row >= BoardLogic.HIDDEN and row < BoardLogic.TOTAL_ROWS:
			canvas.draw_rect(_cell_rect(origin, col, row, cell_size), color)


## Zeichnet die Vorschau des nächsten Stücks. Ohne gültigen Typ bleibt sie leer.
## [param canvas] — Node, dessen [code]_draw()[/code] gerade läuft.
## [param typ] — Stück-Typ der Vorschau.
## [param position] — Pixelposition der ersten Vorschau-Zelle.
## [param cell_size] — Pixelgröße einer Spielfeld-Zelle.
static func draw_preview(canvas: CanvasItem, typ: int, position: Vector2, cell_size: int) -> void:
	if not PieceData.PIECE_CELLS.has(typ):
		return
	var preview_cell := cell_size * PREVIEW_CELL_FACTOR
	var box := Vector2.ONE * PREVIEW_BOX_CELLS * preview_cell
	var box_position := position - Vector2(PREVIEW_PADDING, 0)
	canvas.draw_rect(Rect2(box_position, box), PREVIEW_BACKGROUND_COLOR)
	var color := PieceData.get_color(typ)
	for cell in PieceData.PIECE_CELLS[typ]:
		var cell_position: Vector2 = position + cell * preview_cell
		canvas.draw_rect(Rect2(cell_position, Vector2.ONE * (preview_cell - 2)), color)


## Berechnet das Pixel-Rechteck einer Zelle. Die versteckten Reihen liegen oberhalb des Ursprungs.
## [param origin] — Pixelposition der linken oberen Ecke des Spielfelds.
## [param col] — Spalte der Zelle.
## [param row] — Reihe der Zelle, einschließlich der versteckten Reihen.
## [param cell_size] — Pixelgröße einer Zelle.
## [b]return[/b] [Rect2] — Rechteck der Zelle, rundum 1 Pixel eingerückt für den Gitterabstand.
static func _cell_rect(origin: Vector2i, col: int, row: int, cell_size: int) -> Rect2:
	return Rect2(
		origin.x + col * cell_size + 1,
		origin.y + (row - BoardLogic.HIDDEN) * cell_size + 1,
		cell_size - 2,
		cell_size - 2,
	)

#endregion
