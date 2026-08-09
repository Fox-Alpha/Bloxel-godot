class_name PieceData
extends RefCounted
## Statische Tetromino-Daten: Farben, Zell-Layouts, Grössen und SRS-Kick-Tabellen.
##
## Hält die reinen Stück-Definitionen vom Spielcode getrennt, sodass
## Rotationslogik und Wall-Kicks isoliert getestet werden können.
##
## PieceType-Werte: 1=I, 2=O, 3=T, 4=S, 5=Z, 6=J, 7=L. Key 0 = leere Zelle.

#region Constants

## Farben pro Stück-Typ (Key 0 = leere Zelle / Hintergrund).
const COLORS := {
	0: Color(0.15, 0.15, 0.18),
	1: Color(0.0, 0.95, 0.95),
	2: Color(0.95, 0.95, 0.0),
	3: Color(0.6, 0.1, 0.95),
	4: Color(0.0, 0.95, 0.1),
	5: Color(0.95, 0.0, 0.1),
	6: Color(0.1, 0.5, 0.95),
	7: Color(0.95, 0.5, 0.0),
}

## Zell-Positionen pro Stück-Typ (Basis-Rotation 0).
const PIECE_CELLS := {
	1: [Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1)],
	2: [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
	3: [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
	4: [Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1)],
	5: [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)],
	6: [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
	7: [Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
}

## Bounding-Box-Grösse pro Stück-Typ.
const PIECE_SIZES := {
	1: Vector2i(4, 4),
	2: Vector2i(2, 2),
	3: Vector2i(3, 3),
	4: Vector2i(3, 3),
	5: Vector2i(3, 3),
	6: Vector2i(3, 3),
	7: Vector2i(3, 3),
}

## SRS Wall-Kick-Tabelle für J, L, S, T, Z.
const JLSTZ_KICKS := {
	"0>1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"1>0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"1>2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"2>1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"2>3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	"3>2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"3>0": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"0>3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
}

## SRS Wall-Kick-Tabelle für I-Piece.
const I_KICKS := {
	"0>1": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"1>0": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"1>2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
	"2>1": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"2>3": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"3>2": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"3>0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"0>3": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
}

#endregion

#region Public API

## Berechnet die Zell-Positionen eines Stücks in einer gegebenen Rotation.
## [param typ] — Stück-Typ-Wert (1–7).
## [param rot] — Anzahl der 90°-Drehungen im Uhrzeigersinn (0–3).
## [return] — Array von Vector2-Zellkoordinaten.
static func get_cells(typ: int, rot: int) -> Array:
	var base: Array = PIECE_CELLS[typ]
	var size: Vector2i = PIECE_SIZES[typ]
	var c: Array = base.duplicate()
	var w: int = size.x
	var h: int = size.y
	# 90°-Rotation im Uhrzeigersinn: (x, y) -> (h-1-y, x)
	for r in range(rot):
		var n: Array = []
		for cell in c:
			n.append(Vector2(h - 1 - cell.y, cell.x))
		c = n
		var t := w
		w = h
		h = t
	return c


## Liefert die Farbe eines Stück-Typs.
## [param typ] — Stück-Typ-Wert (0–7); 0 = leere Zelle.
## [return] — Farbe des Stücks.
static func get_color(typ: int) -> Color:
	return COLORS[typ]


## Liefert die zur Rotation passenden Wall-Kick-Offsets.
## [param typ] — Stück-Typ-Wert (1–7).
## [param from_rot] — Aktuelle Rotation (0–3).
## [param to_rot] — Ziel-Rotation (0–3).
## [return] — Array der Kick-Offset-Vektoren; leer bei O-Stück.
static func get_kicks(typ: int, from_rot: int, to_rot: int) -> Array:
	var key := str(from_rot) + ">" + str(to_rot)
	match typ:
		1: # I
			return I_KICKS.get(key, [])
		2: # O — keine Wall-Kicks
			return []
		_:
			return JLSTZ_KICKS.get(key, [])

#endregion