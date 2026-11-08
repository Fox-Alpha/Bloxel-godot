class_name SummaryContext
extends RefCounted
## Alle Angaben, die die Auswertung am Spielende braucht.
##
## Ersetzt die lange Parameterliste von [method GameSummary.show_summary] und bestimmt den Gewinner.
## Bei gleichzeitigem Top-Out vergleicht [method determine_winner] die Punkte, sodass beide
## Bildschirme denselben Gewinner zeigen.

#region Public Vars
## Lokale End-Statistiken (score, lines, level, play_time, pieces).
var local_data: Dictionary = { }
## Gegnerische End-Statistiken, leer im Einzelspiel.
var opponent_data: Dictionary = { }
## Ob die Auswertung zu einer Multiplayer-Runde gehört.
var is_multiplayer: bool = false
## Rundennummer, 0 im Einzelspiel.
var round_num: int = 0
## Anzeigename des lokalen Spielers.
var local_name: String = "YOU"
## Anzeigename des Gegners.
var opp_name: String = "OPPONENT"
## Ob der lokale Spieler getoppt hat.
var local_lost: bool = false
## Ob der Gegner getoppt hat.
var opponent_lost: bool = false
#endregion


#region Public Funcs

## Bestimmt den Gewinner aus den Top-Out-Flags und bei beiderseitigem Top-Out aus den Punkten.
## [b]return[/b] [String] — Gewinner-Text oder leer, solange noch keiner feststeht.
func determine_winner() -> String:
	if not is_multiplayer or opponent_data.is_empty():
		return ""
	# Beide getoppt: Der Punktevergleich sorgt für denselben Gewinner auf beiden Seiten.
	if local_lost and opponent_lost:
		var own_score := int(local_data.get("score", 0))
		var other_score := int(opponent_data.get("score", 0))
		if own_score > other_score:
			return local_name + " WINS!"
		if other_score > own_score:
			return opp_name + " WINS!"
		return "DRAW!"
	if local_lost:
		return opp_name + " WINS!"
	if opponent_lost:
		return local_name + " WINS!"
	return ""

#endregion
