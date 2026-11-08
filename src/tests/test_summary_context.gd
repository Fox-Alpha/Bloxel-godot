extends GutTest
## Prüft in [SummaryContext], wer am Ende einer Runde als Gewinner angezeigt wird.
##
## Wie GUT Tests findet und ausführt, steht in [code]test_board_codec.gd[/code].[br]
## Beide Spieler berechnen den Gewinner getrennt auf ihrem eigenen Rechner. Deshalb prüfen die Tests
## auch, dass beide Seiten zum selben Ergebnis kommen.

#region Constants
## Anzeigename des lokalen Spielers in den Tests.
const ALICE: String = "Alice"
## Anzeigename des Gegners in den Tests.
const BOB: String = "Bob"
#endregion


#region Public Funcs

## Im Einzelspiel gibt es keinen Gewinner, auch wenn der Spieler getoppt hat.
func test_single_player_has_no_winner() -> void:
	var context := SummaryContext.new()
	context.local_lost = true

	assert_eq(context.determine_winner(), "")


## Solange die Werte des Gegners fehlen, lässt sich noch nichts sagen. Sie kommen per RPC oft erst
## kurz nach dem eigenen Game Over an.
func test_missing_opponent_data_has_no_winner() -> void:
	var context := _make_context(100, 50, true, true)
	context.opponent_data = { }

	assert_eq(context.determine_winner(), "")


## Hat noch keiner getoppt, steht auch noch kein Gewinner fest.
func test_nobody_lost_has_no_winner() -> void:
	assert_eq(_make_context(100, 50, false, false).determine_winner(), "")


## Wer zuerst oben ankommt, verliert, auch mit mehr Punkten.
func test_local_top_out_lets_opponent_win_despite_score() -> void:
	assert_eq(_make_context(900, 10, true, false).determine_winner(), BOB + " WINS!")


## Gegenstück: Hat der Gegner getoppt, gewinnt der lokale Spieler auch mit weniger Punkten.
func test_opponent_top_out_lets_local_player_win_despite_score() -> void:
	assert_eq(_make_context(10, 900, false, true).determine_winner(), ALICE + " WINS!")


## Haben beide fast gleichzeitig getoppt, entscheiden die Punkte.
func test_both_lost_higher_score_wins() -> void:
	assert_eq(_make_context(200, 100, true, true).determine_winner(), ALICE + " WINS!")
	assert_eq(_make_context(100, 200, true, true).determine_winner(), BOB + " WINS!")


## Gleiche Punkte bei beiderseitigem Top-Out sind unentschieden.
func test_both_lost_equal_score_is_a_draw() -> void:
	assert_eq(_make_context(100, 100, true, true).determine_winner(), "DRAW!")


## Fehlt der Punktestand, zählt er als 0, statt einen Fehler auszulösen.
func test_missing_score_counts_as_zero() -> void:
	var context := _make_context(0, 50, true, true)
	context.local_data = { }

	assert_eq(context.determine_winner(), BOB + " WINS!")


## Der wichtigste Fall aus Sicht der Spieler: Beide Rechner müssen denselben Gewinner anzeigen.
## Der zweite Kontext ist der erste aus der Sicht des Gegners, mit getauschten Seiten.
func test_both_sides_show_the_same_winner() -> void:
	var alice_view := _make_context(300, 100, true, true)
	var bob_view := _make_context(100, 300, true, true)
	bob_view.local_name = BOB
	bob_view.opp_name = ALICE

	assert_eq(alice_view.determine_winner(), bob_view.determine_winner())

#endregion


#region Private Funcs

## Baut einen Multiplayer-Kontext aus Sicht von Alice.
## [param own_score] — Punkte des lokalen Spielers.
## [param other_score] — Punkte des Gegners.
## [param local_lost] — Ob der lokale Spieler getoppt hat.
## [param opponent_lost] — Ob der Gegner getoppt hat.
func _make_context(own_score: int, other_score: int, local_lost: bool, opponent_lost: bool) -> SummaryContext:
	var context := SummaryContext.new()
	context.is_multiplayer = true
	context.local_name = ALICE
	context.opp_name = BOB
	context.local_data = { score = own_score }
	context.opponent_data = { score = other_score }
	context.local_lost = local_lost
	context.opponent_lost = opponent_lost
	return context

#endregion
