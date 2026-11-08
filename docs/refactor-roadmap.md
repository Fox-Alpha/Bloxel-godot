# Refactoring Roadmap

Abgeschlossen am 2026-11-08, erster Stand danach ist `v0.20.0-rc1`. Die Details stehen in den Issues und Merge-Commits.

## Ergebnis

Reihenfolge wie umgesetzt:

| Issue | Thema | Ergebnis | Merge |
|---|---|---|---|
| #17 | Unit-Tests | GUT eingebunden, Tests in `src/tests/` | `5556e12` |
| #20 | `game.gd` aufteilen | `BoardLogic`, `GameRenderer` und `GameInput` ausgelagert | `8b8c7ba` |
| #15 | `class_name` | `BloxelGame`, `Lobby`, `GameSummary`, `MultiplayerManager`, typisierte Node-Referenzen | `34cd677` |
| #29 | Styleguide-Konventionen | Szenen unter `src/scenes/<feature>/`, `game.gd` heißt `main.gd`, feste Regionen, `.editorconfig` | `477d8b3` |
| #13 | Docstrings | Jede Funktion und jedes Signal dokumentiert, Rückgabe im Godot-Format | `313105e` |
| #14 | `show_summary()` | Data-Klasse `SummaryContext`, Gewinner-Bestimmung getestet | `693eab9` |
| #18 | Fester Pfad in der Lobby | `MultiplayerManager` per `@export` aus `main.tscn` | `690b116` |
| #16 | Magic Numbers der UI | Benannte Konstanten in `main.gd` | `c992ec3` |

## Bewusste Abweichungen von der Planung

- `main.gd` hat nach dem Split rund 880 Zeilen statt der geschätzten ~300. Übrig sind vor allem Zustandsvariablen,
  Multiplayer mit RPCs und Game Over. Ein eigenes `game_multiplayer.gd` wäre der größte weitere Hebel.
- Lock Delay und UI-Labels bleiben in `main.gd`: Der Lock Delay ist eine Spielregel, die Labels brauchen die Nodes.
- `GameRenderer` ist eine statische Hilfsklasse und zeichnet in das `_draw()` von `main.gd`, kein eigener Node.
- Die Tests für die Board-Logik kamen mit #20, nicht mit #17.

## Offen

Nicht Teil der Refactorings, die Planung steht in den Issues:

- #19 Lokalisierung
- #25 Tests in GitHub Actions, vorerst nicht geplant
- #30 Eigener Spielcharakter
