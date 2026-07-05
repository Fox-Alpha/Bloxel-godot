# Bloxel

A free, open-source Tetris-like block-stacking game built with **Godot 4**, featuring classic mechanics, ghost piece, next-piece preview, speed progression, and 2-player multiplayer over LAN/internet.

## Features

- **Standard Tetris gameplay** – SRS rotation, 7-bag randomizer, lock delay, DAS/ARR
- **Ghost piece** – shows where the current piece will land
- **Next-piece preview**
- **Level & speed-up** – every 10 cleared lines increases the level and drop speed
- **Classic scoring** – 100 / 300 / 500 / 800 per 1–4 lines cleared
- **2-player multiplayer** – Host/Join via IP:port (default 21277)
  - Player name input
  - Round counter (best-of-N style)
  - Shared game-over: first player to top out loses; winner is shown
  - Restart with mutual ready confirmation
  - Graceful disconnect handling

## Controls

| Action | Key |
|--------|-----|
| Move left / right | ← → |
| Soft drop | ↓ |
| Hard drop | Space / Ctrl |
| Rotate clockwise | ↑ |
| Single-player restart (after game over) | Space |

## Multiplayer

1. **Host**: set a port (default 21277), click *Host*
2. **Join**: enter the host's IP and port, click *Join*
3. Both players enter their names – the lobby shows who's who
4. The round starts automatically once the client connects
5. After game-over, each player presses *Ready* to start the next round
6. Use *Back to Menu* or close the opponent's window to return to the lobby

## Development Setup

Dieses Projekt wird mit [OpenCode](https://opencode.ai) und KI-Assistenz entwickelt.
Zwei MCP-Server stellen Werkzeuge für Editor-Automation und Code-Analyse bereit.

Siehe [docs/GUIDE.md](docs/GUIDE.md) für Einrichtung, Konfiguration und Bedienung.
Eine KI-optimierte Kurzbeschreibung findet sich in [docs/AI_CONTEXT.md](docs/AI_CONTEXT.md).

## Tech

| | |
|---|---|
| Engine | Godot 4.7 |
| Language | GDScript |
| Networking | ENet (built-in) |
| UI | Responsive layout, adapts to window size |

### Code Stats

| Component | Lines |
|-----------|-------|
| Game logic (`game.gd`) | 855 |
| Lobby / menu (`lobby.gd`) | 152 |
| Summary screen (`summary.gd`) | 101 |
| Multiplayer manager (`MultiplayerManager.gd`) | 89 |
| **Total GDScript** | **1,197** |
| Scene files (`*.tscn`) | 308 |
| **Total project** | **~1,500 lines** |

## License

MIT License – see [LICENSE](LICENSE) for details.

## Credits

Developed by **Fox-Alpha** with AI assistance via [opencode](https://opencode.ai).
