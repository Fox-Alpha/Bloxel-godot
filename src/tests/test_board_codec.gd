extends GutTest
## Prüft, dass [BoardCodec] das Spielfeld verlustfrei kodiert und dekodiert.
##
## So arbeitet GUT: Es sucht in [code]res://tests[/code] alle Dateien, die mit [code]test_[/code]
## beginnen, und führt darin jede Funktion aus, deren Name ebenfalls mit [code]test_[/code] beginnt.
## Andere Funktionen wie [method _make_board] sind nur Helfer und laufen nicht von selbst.[br]
## Die Basisklasse [code]GutTest[/code] liefert die Prüfungen. [code]assert_eq(ist, soll)[/code]
## vergleicht zwei Werte. Stimmen sie nicht überein, gilt dieser eine Test als fehlgeschlagen, die
## übrigen Tests laufen trotzdem weiter.[br]
## Die Tests sind meist dreiteilig und durch Leerzeilen gegliedert: Daten vorbereiten, die
## geprüfte Funktion aufrufen, Ergebnis prüfen.

#region Constants
## Reihen eines Spielfelds in Originalgröße.
const ROWS: int = 20
## Spalten eines Spielfelds in Originalgröße.
const COLS: int = 10
## Größter Wert, den ein Byte im Puffer aufnehmen kann.
const MAX_BYTE: int = 255
#endregion


#region Public Funcs

## Jede Zelle belegt genau ein Byte. Wäre der Puffer kürzer, liefe das Dekodieren beim Gegenspieler
## über das Ende hinaus.
func test_encode_buffer_has_one_byte_per_cell() -> void:
	var encoded := BoardCodec.encode(_make_board(ROWS, COLS, 0), ROWS, COLS)

	assert_eq(encoded.size(), ROWS * COLS)


## Legt die Reihenfolge im Puffer fest: erst Reihe 0 von links nach rechts, dann Reihe 1.
## Der Roundtrip allein würde eine vertauschte Reihenfolge nicht bemerken, solange beide Richtungen
## denselben Fehler machen.
func test_encode_writes_row_by_row() -> void:
	var board: Array = [[1, 2, 3], [4, 5, 6]]

	var encoded := BoardCodec.encode(board, 2, 3)

	assert_eq(encoded, PackedByteArray([1, 2, 3, 4, 5, 6]))


## Gegenstück zum Test oben: Die Bytes kommen wieder in den richtigen Reihen und Spalten an.
func test_decode_reads_row_by_row() -> void:
	var data := PackedByteArray([1, 2, 3, 4, 5, 6])

	var decoded := BoardCodec.decode(data, 2, 3)

	assert_eq(decoded, [[1, 2, 3], [4, 5, 6]])


## Roundtrip heißt: Kodieren und danach Dekodieren muss das Ausgangsboard ergeben.
## Randfall leeres Spielfeld, so wie zu Beginn einer Runde.
func test_roundtrip_keeps_empty_board() -> void:
	var board := _make_board(ROWS, COLS, 0)

	assert_eq(_roundtrip(board, ROWS, COLS), board)


## Roundtrip mit allen Zellwerten, die im Spiel vorkommen: 0 (leer) und die Stücke 1 bis 7.
func test_roundtrip_keeps_all_piece_types() -> void:
	var board := _make_board(ROWS, COLS, 0)
	for row in range(ROWS):
		for col in range(COLS):
			# Die Summe verteilt alle Werte von 0 bis 7 gleichmäßig über das Feld.
			board[row][col] = (row + col) % 8

	assert_eq(_roundtrip(board, ROWS, COLS), board)


## Randfall größter Wert: 255 passt gerade noch in ein Byte und darf nicht verfälscht werden.
func test_roundtrip_keeps_maximum_value() -> void:
	var board := _make_board(ROWS, COLS, MAX_BYTE)

	assert_eq(_roundtrip(board, ROWS, COLS), board)


## Bei gleich vielen Reihen und Spalten fiele es nicht auf, wenn der Code beide verwechselt.
## Deshalb ein Board mit 3 Reihen und 2 Spalten.
func test_roundtrip_keeps_non_square_board() -> void:
	var board: Array = [[1, 0], [0, 2], [3, 0]]

	assert_eq(_roundtrip(board, 3, 2), board)


## Randfall ohne Zellen: Beide Richtungen liefern ein leeres Ergebnis statt eines Fehlers.
func test_zero_sized_board_stays_empty() -> void:
	assert_eq(BoardCodec.encode([], 0, 0).size(), 0)
	assert_eq(BoardCodec.decode(PackedByteArray(), 0, 0), [])


## Arrays werden in GDScript per Referenz weitergegeben. Hingen alle Reihen am selben Array, würde
## ein Stein in Reihe 0 auch in Reihe 1 auftauchen. Der dritte Parameter von [code]assert_eq[/code]
## ist der Text, den GUT beim Fehlschlag ausgibt.
func test_decoded_rows_are_independent() -> void:
	var decoded := BoardCodec.decode(PackedByteArray([0, 0, 0, 0]), 2, 2)

	decoded[0][0] = 7

	assert_eq(decoded[1][0], 0, "Reihen dürfen sich keinen Speicher teilen.")

#endregion


#region Private Funcs

## Erzeugt ein Board, dessen Zellen alle denselben Wert haben.
func _make_board(rows: int, cols: int, value: int) -> Array:
	var board: Array = []
	for row in range(rows):
		var cells: Array = []
		cells.resize(cols)
		cells.fill(value)
		board.append(cells)
	return board


## Schickt ein Board einmal durch Kodieren und Dekodieren.
func _roundtrip(board: Array, rows: int, cols: int) -> Array:
	return BoardCodec.decode(BoardCodec.encode(board, rows, cols), rows, cols)

#endregion
