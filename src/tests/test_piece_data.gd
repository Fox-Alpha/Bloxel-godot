extends GutTest
## Prüft die Stück-Daten aus [PieceData]: Rotation und SRS-Wall-Kicks.
##
## Wie GUT Tests findet und ausführt, steht in [code]test_board_codec.gd[/code].[br]
## Viele Tests hier laufen in einer Schleife über alle Stücke. Deshalb bekommt jedes
## [code]assert_eq[/code] als dritten Parameter einen Text, der im Fehlerfall das betroffene Stück
## nennt. Ohne ihn wäre in der Ausgabe nicht zu erkennen, welcher Durchlauf gescheitert ist.

#region Constants
## Stück-Typ I.
const TYPE_I: int = 1
## Stück-Typ O.
const TYPE_O: int = 2
## Stück-Typ T.
const TYPE_T: int = 3
## Alle Stück-Typen: I, O, T, S, Z, J, L.
const ALL_TYPES: Array[int] = [1, 2, 3, 4, 5, 6, 7]
## Die Stücke, die sich die Kick-Tabelle [constant PieceData.JLSTZ_KICKS] teilen.
const JLSTZ_TYPES: Array[int] = [3, 4, 5, 6, 7]
## Alle erlaubten Drehungen als (von, nach). Gedreht wird immer um 90 Grad.
const TRANSITIONS: Array[Vector2i] = [
	Vector2i(0, 1),
	Vector2i(1, 0),
	Vector2i(1, 2),
	Vector2i(2, 1),
	Vector2i(2, 3),
	Vector2i(3, 2),
	Vector2i(3, 0),
	Vector2i(0, 3),
]
## Anzahl der Versuche, die SRS pro Drehung vorsieht.
const KICKS_PER_TRANSITION: int = 5
#endregion


#region Public Funcs

## Ein Tetromino besteht in jeder Drehung aus genau 4 verschiedenen Zellen. Doppelte Zellen würden
## das Stück im Spiel kleiner aussehen lassen.
func test_every_rotation_has_four_distinct_cells() -> void:
	for typ in ALL_TYPES:
		for rot in range(4):
			var unique := { }
			for cell in PieceData.get_cells(typ, rot):
				unique[cell] = true

			assert_eq(unique.size(), 4, "Typ %d, Rotation %d" % [typ, rot])


## Alle Zellen müssen in der Bounding-Box des Stücks liegen. Die Drehformel verwendet deren Größe,
## ein falscher Wert in [constant PieceData.PIECE_SIZES] schöbe das Stück hier hinaus.
func test_every_rotation_stays_inside_bounding_box() -> void:
	for typ in ALL_TYPES:
		var size: Vector2i = PieceData.PIECE_SIZES[typ]
		var box := Rect2(Vector2.ZERO, Vector2(size))
		for rot in range(4):
			for cell in PieceData.get_cells(typ, rot):
				assert_true(box.has_point(cell), "Typ %d, Rotation %d, Zelle %s" % [typ, rot, cell])


## Rotation 0 ist die Grundstellung und muss unverändert aus der Tabelle kommen.
func test_rotation_zero_returns_base_cells() -> void:
	for typ in ALL_TYPES:
		assert_eq(PieceData.get_cells(typ, 0), PieceData.PIECE_CELLS[typ], "Typ %d" % typ)


## Vier Vierteldrehungen ergeben wieder die Ausgangslage. Das fällt auf, sobald die Drehformel an
## irgendeiner Stelle falsch rechnet.
func test_four_rotations_return_to_start() -> void:
	for typ in ALL_TYPES:
		var start := _sorted(PieceData.get_cells(typ, 0))

		assert_eq(_sorted(PieceData.get_cells(typ, 4)), start, "Typ %d" % typ)


## Das O-Stück füllt seine 2×2-Box aus und sieht deshalb in jeder Drehung gleich aus.
func test_o_piece_looks_the_same_in_every_rotation() -> void:
	var start := _sorted(PieceData.get_cells(TYPE_O, 0))
	for rot in range(1, 4):
		assert_eq(_sorted(PieceData.get_cells(TYPE_O, rot)), start, "Rotation %d" % rot)


## Von Hand nachgerechneter Sollwert: Der T-Stein zeigt nach einer Drehung nach rechts, seine Mitte
## bleibt auf (1, 1). Die Tests oben zeigen nur, dass die Drehung in sich stimmig ist, erst ein
## fester Wert beweist auch die Drehrichtung.
func test_t_piece_rotates_clockwise() -> void:
	var expected: Array = [Vector2(1, 0), Vector2(1, 1), Vector2(2, 1), Vector2(1, 2)]

	assert_eq(_sorted(PieceData.get_cells(TYPE_T, 1)), _sorted(expected))


## Von Hand nachgerechneter Sollwert: Der I-Stein steht nach einer Drehung senkrecht in Spalte 2.
func test_i_piece_stands_upright_after_one_rotation() -> void:
	var expected: Array = [Vector2(2, 0), Vector2(2, 1), Vector2(2, 2), Vector2(2, 3)]

	assert_eq(_sorted(PieceData.get_cells(TYPE_I, 1)), _sorted(expected))


## Der I-Stein hat eine eigene Kick-Tabelle. Geprüft wird gegen ausgeschriebene Werte, weil ein
## Vergleich mit [constant PieceData.I_KICKS] einen Tippfehler in der Tabelle nicht fände.
func test_i_piece_uses_its_own_kicks() -> void:
	var expected: Array = [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)]

	assert_eq(PieceData.get_kicks(TYPE_I, 0, 1), expected)


## J, L, S, T und Z teilen sich eine Tabelle. Die Werte stehen hier wieder ausgeschrieben.
func test_jlstz_pieces_share_their_kicks() -> void:
	var expected: Array = [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)]
	for typ in JLSTZ_TYPES:
		assert_eq(PieceData.get_kicks(typ, 0, 1), expected, "Typ %d" % typ)


## Das O-Stück ändert beim Drehen nichts und braucht deshalb keine Kicks.
func test_o_piece_has_no_kicks() -> void:
	for transition in TRANSITIONS:
		assert_eq(PieceData.get_kicks(TYPE_O, transition.x, transition.y), [], str(transition))


## Das Spiel probiert die Offsets der Reihe nach durch. Der erste Versuch muss „nicht verschieben“
## sein, sonst würde ein Stück springen, obwohl es an Ort und Stelle Platz hätte.
func test_every_transition_has_five_kicks_starting_at_zero() -> void:
	for typ in [TYPE_I, TYPE_T]:
		for transition in TRANSITIONS:
			var kicks := PieceData.get_kicks(typ, transition.x, transition.y)
			var label := "Typ %d, Drehung %s" % [typ, transition]

			assert_eq(kicks.size(), KICKS_PER_TRANSITION, label)
			assert_eq(kicks[0], Vector2i.ZERO, label)


## In SRS ist die Rückdrehung genau das Gegenteil der Hindrehung. Dadurch fällt ein Tippfehler in
## einer der 16 Tabellenzeilen auf, ohne dass jede Zeile hier ausgeschrieben werden muss.
func test_reverse_transition_mirrors_kicks() -> void:
	for typ in [TYPE_I, TYPE_T]:
		for transition in TRANSITIONS:
			var forward := PieceData.get_kicks(typ, transition.x, transition.y)
			var backward := PieceData.get_kicks(typ, transition.y, transition.x)
			for i in range(forward.size()):
				assert_eq(backward[i], -forward[i], "Typ %d, Drehung %s" % [typ, transition])


## Eine 180-Grad-Drehung gibt es nicht. Eine leere Liste bedeutet: keine Kicks, nichts zu versuchen.
func test_unknown_transition_has_no_kicks() -> void:
	assert_eq(PieceData.get_kicks(TYPE_T, 0, 2), [])
	assert_eq(PieceData.get_kicks(TYPE_I, 0, 2), [])

#endregion


#region Private Funcs

## Sortiert Zellen, damit Vergleiche nicht von der Reihenfolge abhängen. Nach einer Drehung liegen
## dieselben Zellen in anderer Reihenfolge im Array, für das Spiel spielt das keine Rolle.
func _sorted(cells: Array) -> Array:
	var result: Array = cells.duplicate()
	result.sort()
	return result

#endregion
