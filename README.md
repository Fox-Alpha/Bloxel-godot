# Bloxel<img width="1284" height="807" alt="Bildschirmfoto_Bloxel  PID: 8373 _06-Juli-2026_1805_01" src="https://github.com/user-attachments/assets/b0fb6a7b-75d4-49f5-8c4e-01d68b626c8b" />

A free, open-source Tetris-like block-stacking game built with **Godot 4**, featuring classic mechanics, ghost piece, next-piece preview, speed progression, and 2-player multiplayer over LAN/internet.

## Features

- **Standard Tetris gameplay** – SRS rotation, 7-bag randomizer, lock delay, DAS/ARR
- **Ghost piece** – shows where the current piece will land
- **Next-piece preview**
- **Level & speed-up** – every 10 cleared lines increases the level and drop speed
- **Classic scoring** – 100 / 300 / 500 / 800 per 1–4 lines cleared
- **Single player** – *Play Again* after game over, *Quit* in the main menu
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

## Multiplayer

1. **Host**: set a port (default 21277), click *Host*
2. **Join**: enter the host's IP and port, click *Join*
3. Both players enter their names – the lobby shows who's who
4. The round starts automatically once the client connects
5. After game-over, each player presses *Ready* to start the next round
6. Use *Back to Menu* or close the opponent's window to return to the lobby

## Development Setup

Addons are not part of the repository. Install them with [gd-plug](https://github.com/Fox-Alpha/fork-gd-plug) before
opening the project (editor closed):

```bash
cd src && godot --headless -s plug.gd install
```

Then open `src/project.godot` with Godot 4.7. The main scene is `res://scenes/main/main.tscn`. See [docs/addons.md](docs/addons.md)
for the addons in use.

Run the unit tests from `src/`:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

## Tech

| | |
|---|---|
| Engine | Godot 4.7 |
| Language | GDScript |
| Networking | ENet (built-in) |
| UI | Responsive layout, adapts to window size |

## License

[MIT License](LICENSE)

## Credits

Developed by **Fox-Alpha** with AI assistance.
