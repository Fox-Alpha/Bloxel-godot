extends GutTest
## Prüft die Regeln des Spielfelds in [BoardLogic].
##
## Wie GUT Tests findet und ausführt, steht in [code]test_board_codec.gd[/code].[br]
## Die meisten Tests nutzen [constant SINGLE_CELL], ein Stück aus nur einer Zelle. So ist auf einen
## Blick klar, welche Position geprüft wird, ohne die Form eines echten Stücks mitzudenken.

#region Constants
## Ein Stück aus genau einer Zelle am Ursprung.
const SINGLE_CELL: Array = [Vector2(0, 0)]
## Ein 2×2-Block, wie das O-Stück in Rotation 0.
const BLOCK: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
## Letzte gültige Spalte.
const LAST_COL: int = BoardLogic.COLS - 1
## Unterste Reihe des Boards.
const LAST_ROW: int = BoardLogic.TOTAL_ROWS - 1
## Beliebiger Stück-Typ für gefüllte Zellen.
const FILLED: int = 3
#endregion


#region Public Funcs

## Das Board muss so groß sein, wie alle anderen Funktionen und der Netzwerk-Sync es erwarten.
func test_create_empty_has_expected_size_and_is_empty() -> void:
	var board := BoardLogic.create_empty()

	assert_eq(board.size(), BoardLogic.TOTAL_ROWS)
	for row in board:
		assert_eq(row.count(0), BoardLogic.COLS, "Jede Reihe besteht nur aus leeren Zellen.")


## Arrays sind Referenzen. Teilten sich die Reihen ein Array, stünde jeder Stein in jeder Reihe.
func test_create_empty_rows_are_independent() -> void:
	var board := BoardLogic.create_empty()

	board[0][0] = FILLED

	assert_eq(board[1][0], 0)


## Grundfall: Mitten im leeren Feld ist jede Position erlaubt.
func test_is_valid_accepts_free_position() -> void:
	assert_true(BoardLogic.is_valid(BoardLogic.create_empty(), BLOCK, 4, 10))


## Die äußersten erlaubten Positionen gehören noch zum Feld. Hier fallen Fehler um eins auf.
func test_is_valid_accepts_positions_on_the_edge() -> void:
	var board := BoardLogic.create_empty()

	assert_true(BoardLogic.is_valid(board, SINGLE_CELL, 0, 0), "linke obere Ecke")
	assert_true(BoardLogic.is_valid(board, SINGLE_CELL, LAST_COL, LAST_ROW), "rechte untere Ecke")


## Eine Spalte weiter außen ist links und rechts Schluss, eine Reihe tiefer ebenfalls.
func test_is_valid_rejects_positions_outside_the_board() -> void:
	var board := BoardLogic.create_empty()

	assert_false(BoardLogic.is_valid(board, SINGLE_CELL, -1, 5), "links")
	assert_false(BoardLogic.is_valid(board, SINGLE_CELL, LAST_COL + 1, 5), "rechts")
	assert_false(BoardLogic.is_valid(board, SINGLE_CELL, 5, LAST_ROW + 1), "unten")


## Ein Stück darf nicht in einen liegenden Stein hineinragen, auch nicht mit nur einer Zelle.
func test_is_valid_rejects_occupied_cells() -> void:
	var board := BoardLogic.create_empty()
	board[11][5] = FILLED

	assert_false(BoardLogic.is_valid(board, BLOCK, 4, 10))


## Über dem Board ist noch Platz: Beim Drehen ganz oben dürfen Zellen kurz darüber liegen.
## Ohne das [code]continue[/code] in [method BoardLogic.is_valid] gäbe es hier einen Indexfehler.
func test_is_valid_allows_cells_above_the_board() -> void:
	assert_true(BoardLogic.is_valid(BoardLogic.create_empty(), SINGLE_CELL, 5, -1))


## Auch oberhalb des Boards gelten die Seitenwände.
func test_is_valid_checks_walls_above_the_board() -> void:
	assert_false(BoardLogic.is_valid(BoardLogic.create_empty(), SINGLE_CELL, -1, -1))


## Der Block ist 2 Zellen hoch, sein Ursprung landet also auf der vorletzten Reihe.
func test_drop_y_lands_on_the_floor() -> void:
	var landing := BoardLogic.drop_y(BoardLogic.create_empty(), BLOCK, 4, 0)

	assert_eq(landing, BoardLogic.TOTAL_ROWS - 2)


## Mit einem Stein in Reihe 10 endet der Fall direkt darüber. Das nutzen Hard Drop und Ghost Piece.
func test_drop_y_stops_on_top_of_a_piece() -> void:
	var board := BoardLogic.create_empty()
	board[10][5] = FILLED

	assert_eq(BoardLogic.drop_y(board, SINGLE_CELL, 5, 0), 9)


## Liegt das Stück schon auf, bleibt es, wo es ist. Ein Hard Drop gibt dann keine Bonuspunkte.
func test_drop_y_keeps_position_when_already_resting() -> void:
	var landing := BoardLogic.drop_y(BoardLogic.create_empty(), SINGLE_CELL, 5, LAST_ROW)

	assert_eq(landing, LAST_ROW)


## Alle 4 Zellen kommen an der richtigen Stelle an, mit dem Typ als Wert.
func test_lock_piece_writes_all_cells() -> void:
	var board := BoardLogic.create_empty()

	BoardLogic.lock_piece(board, BLOCK, 4, 10, FILLED)

	assert_eq(board[10][4], FILLED)
	assert_eq(board[10][5], FILLED)
	assert_eq(board[11][4], FILLED)
	assert_eq(board[11][5], FILLED)


## Ragt ein Stück beim Festsetzen über den oberen Rand, darf nur der Teil im Board ankommen.
## Ein negativer Index würde in GDScript sonst die unterste Reihe treffen, ohne Fehlermeldung.
func test_lock_piece_ignores_cells_above_the_board() -> void:
	var board := BoardLogic.create_empty()

	BoardLogic.lock_piece(board, BLOCK, 4, -1, FILLED)

	assert_eq(board[0][4], FILLED, "untere Hälfte des Blocks liegt in Reihe 0")
	assert_eq(board[LAST_ROW][4], 0, "die oberste Hälfte darf nicht unten auftauchen")


## Ohne volle Reihe passiert nichts. Eine fast volle Reihe zählt nicht.
func test_clear_full_lines_keeps_incomplete_rows() -> void:
	var board := BoardLogic.create_empty()
	_fill_row(board, LAST_ROW)
	board[LAST_ROW][0] = 0
	var before := board.duplicate(true)

	assert_eq(BoardLogic.clear_full_lines(board), 0)
	assert_eq(board, before)


## Eine volle Reihe verschwindet, die Steine darüber rutschen genau eine Reihe nach unten.
func test_clear_full_lines_moves_rows_above_down() -> void:
	var board := BoardLogic.create_empty()
	_fill_row(board, LAST_ROW)
	board[LAST_ROW - 1][2] = FILLED

	assert_eq(BoardLogic.clear_full_lines(board), 1)
	assert_eq(board[LAST_ROW][2], FILLED, "der Stein ist nach unten gerutscht")
	assert_eq(board[LAST_ROW - 1][2], 0, "seine alte Position ist frei")


## Vier volle Reihen übereinander, der Fall mit den meisten Punkten. Das Nachrutschen darf keine
## davon überspringen, deshalb prüft der Code dieselbe Reihe nach dem Löschen noch einmal.
func test_clear_full_lines_removes_four_adjacent_rows() -> void:
	var board := BoardLogic.create_empty()
	for row in range(LAST_ROW - 3, LAST_ROW + 1):
		_fill_row(board, row)

	assert_eq(BoardLogic.clear_full_lines(board), 4)
	assert_eq(board, BoardLogic.create_empty())


## Zwischen zwei vollen Reihen liegt eine unvollständige, sie muss erhalten bleiben.
func test_clear_full_lines_handles_gaps_between_full_rows() -> void:
	var board := BoardLogic.create_empty()
	_fill_row(board, LAST_ROW)
	board[LAST_ROW - 1][7] = FILLED
	_fill_row(board, LAST_ROW - 2)

	assert_eq(BoardLogic.clear_full_lines(board), 2)
	assert_eq(board[LAST_ROW][7], FILLED)


## Auch die oberste Reihe wird gelöscht, obwohl keine Reihe mehr nachrücken kann.
func test_clear_full_lines_handles_top_row() -> void:
	var board := BoardLogic.create_empty()
	_fill_row(board, 0)

	assert_eq(BoardLogic.clear_full_lines(board), 1)
	assert_eq(board[0][0], 0)


## Die nachrückenden Reihen und die neue oberste Reihe dürfen sich kein Array teilen. Sonst würde
## der nächste festgesetzte Stein in mehreren Reihen gleichzeitig erscheinen.
func test_clear_full_lines_leaves_independent_rows() -> void:
	var board := BoardLogic.create_empty()
	_fill_row(board, LAST_ROW)

	BoardLogic.clear_full_lines(board)
	board[0][0] = FILLED

	assert_eq(board[1][0], 0)

#endregion


#region Private Funcs

## Füllt eine ganze Reihe mit Steinen.
func _fill_row(board: Array, row: int) -> void:
	for col in range(BoardLogic.COLS):
		board[row][col] = FILLED

#endregion
