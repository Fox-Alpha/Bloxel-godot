class_name BoardCodec
extends RefCounted
## Kodiert/Dekodiert das Spielfeld als kompaktes PackedByteArray für Multiplayer-Sync.
##
## Trennt die Serialisierungslogik vom Spielcode, um Netzwerk-Übertragung
## isoliert testen zu können.

#region Public API

## Kodiert das Board als kompaktes PackedByteArray.
## [param b] — Das Board-Array (rows × cols).
## [param rows] — Anzahl Reihen.
## [param cols] — Anzahl Spalten.
## [return] — Bytepuffer (rows × cols Bytes).
static func encode(b: Array, rows: int, cols: int) -> PackedByteArray:
	var pba := PackedByteArray()
	pba.resize(rows * cols)
	var idx := 0
	for row in range(rows):
		for col in range(cols):
			pba[idx] = b[row][col]
			idx += 1
	return pba


## Dekodiert ein kompaktes PackedByteArray zurück ins Board-Format.
## [param data] — Bytepuffer (rows × cols Bytes).
## [param rows] — Anzahl Reihen.
## [param cols] — Anzahl Spalten.
## [return] — Rekonstruiertes Board-Array (rows × cols).
static func decode(data: PackedByteArray, rows: int, cols: int) -> Array:
	var b: Array = []
	for i in range(rows):
		var r: Array = []
		r.resize(cols)
		r.fill(0)
		b.append(r)
	var idx := 0
	for row in range(rows):
		for col in range(cols):
			b[row][col] = data[idx]
			idx += 1
	return b

#endregion