# Bloxel Code Review - qwen3.7-plus

**Review Date:** 2026-07-10  
**Reviewer:** qwen3.7-plus  
**Project:** Bloxel - Godot 4.7 Tetris Clone with Multiplayer  
**Scope:** Main game scripts and scenes

---

## Executive Summary

Bloxel is a well-structured Tetris clone with ENet multiplayer support. The codebase demonstrates solid understanding of Godot's architecture, with proper use of signals, RPCs, and the scene tree. However, several areas need improvement to meet production standards and follow GDScript best practices.

**Overall Rating:** 7/10 - Functional but needs refinement

---

## Critical Issues

### 1. Missing `class_name` Declarations (All Scripts)
**Severity:** HIGH  
**Files:** `game.gd`, `lobby.gd`, `MultiplayerManager.gd`, `summary.gd`

**Issue:** No script declares a `class_name`, which violates the project's style guide and prevents type safety.

**Impact:**
- No type checking for script references
- Poorer IDE support and autocomplete
- Cannot use scripts as type hints

**Recommendation:**
```gdscript
# game.gd
class_name Game extends Node2D

# lobby.gd
class_name Lobby extends Control

# MultiplayerManager.gd
class_name MultiplayerManager extends Node

# summary.gd
class_name Summary extends Control
```

---

### 2. Godot 4.7 API Compatibility Concerns
**Severity:** MEDIUM  
**Files:** All scripts

**Issue:** The project targets Godot 4.7, but some API usage may be outdated or incorrect.

**Specific Concerns:**
- `multiplayer.multiplayer_peer` access pattern needs verification
- RPC annotations syntax should be validated for 4.7
- ENetMultiplayerPeer API stability

**Recommendation:** Run `godot-api-audit` agent to verify all API calls against Godot 4.4-4.7 changelogs.

---

### 3. Untyped Node References
**Severity:** MEDIUM  
**Files:** `game.gd:78`, `lobby.gd:15`

**Issue:** Node references lack type annotations.

```gdscript
# game.gd:78
@onready var mp_manager = $MultiplayerManager  # Missing type

# lobby.gd:15
@onready var mp_manager = get_node("/root/Main/MultiplayerManager")  # Hardcoded path + no type
```

**Impact:** No compile-time type checking, potential runtime errors.

**Recommendation:**
```gdscript
# game.gd
@onready var mp_manager: MultiplayerManager = $MultiplayerManager

# lobby.gd - use @onready with relative path
@onready var mp_manager: MultiplayerManager = $/root/Main/MultiplayerManager
# Or better: pass as parameter or use autoload
```

---

## Code Quality Issues

### 4. game.gd - Excessive File Size (1016 lines)
**Severity:** HIGH  
**File:** `game.gd`

**Issue:** Single script handles too many responsibilities:
- Game state management
- Input handling
- Rendering
- Multiplayer synchronization
- UI updates
- Piece generation
- Collision detection

**Impact:**
- Hard to maintain and test
- Difficult to understand code flow
- High cognitive load

**Recommendation:** Split into multiple scripts:
```
scripts/
  game.gd              — Main coordinator (200-300 lines)
  board.gd             — Board state and collision (class_name: Board)
  piece_controller.gd  — Piece movement/rotation (class_name: PieceController)
  piece_renderer.gd    — Drawing logic (class_name: PieceRenderer)
  multiplayer_sync.gd  — MP sync logic (class_name: MultiplayerSync)
  scoring.gd           — Score calculation (class_name: Scoring)
```

---

### 5. Magic Numbers Throughout Code
**Severity:** MEDIUM  
**Files:** Multiple

**Examples:**
```gdscript
# game.gd:427
drop_interval = 0.8  # Why 0.8?

# game.gd:631
drop_interval = max(0.05, 0.8 - level * 0.05)  # Multiple magic numbers

# game.gd:569
score += (gy - current.y) * 2  # Why 2 points per row?

# game.gd:626
var points_per_line: Array[int] = [0, 100, 300, 500, 800]  # Should be constants
```

**Recommendation:** Define named constants:
```gdscript
const INITIAL_DROP_INTERVAL: float = 0.8
const MIN_DROP_INTERVAL: float = 0.05
const DROP_INTERVAL_DECREASE_PER_LEVEL: float = 0.05
const HARD_DROP_BONUS_PER_ROW: int = 2
const SOFT_DROP_BONUS: int = 1

const LINE_CLEAR_POINTS: Array[int] = [
    0,    # 0 lines
    100,  # 1 line (single)
    300,  # 2 lines (double)
    500,  # 3 lines (triple)
    800,  # 4 lines (tetris)
]
```

---

### 6. Inconsistent Type Annotations
**Severity:** MEDIUM  
**Files:** All scripts

**Issue:** Some variables are typed, others are not.

**Examples:**
```gdscript
# Good
var score: int = 0
var game_over: bool = false

# Bad
var board: Array = []  # Should be Array[Array[int]]
var current: Dictionary = {}  # Should be more specific
var colors: Dictionary = {}  # Should be Dictionary[PieceType, Color]
```

**Recommendation:** Use strict typing everywhere:
```gdscript
var board: Array[Array[int]] = []
var current: Dictionary = {}  # Consider a custom class: class_name Piece { var type, rot, x, y }
var colors: Dictionary[PieceType, Color] = {}
```

---

### 7. Debug Print Statements
**Severity:** LOW  
**Files:** `lobby.gd`, `MultiplayerManager.gd`

**Issue:** Debug prints with PID should be removed or made conditional.

```gdscript
# lobby.gd:42
print("[PID:", pid, "] lobby _ready")

# MultiplayerManager.gd:26
print("[PID:", OS.get_process_id(), "] MultiplayerManager.host(port=", port, ")")
```

**Recommendation:** Use a debug logging system or remove before release:
```gdscript
# Option 1: Conditional debug
const DEBUG := false

func _log(msg: String) -> void:
    if DEBUG:
        print("[", OS.get_process_id(), "] ", msg)

# Option 2: Use push_warning/push_error for actual issues
```

---

## Architecture Issues

### 8. Hardcoded Node Path in lobby.gd
**Severity:** MEDIUM  
**File:** `lobby.gd:15`

**Issue:** Uses absolute path to access MultiplayerManager.

```gdscript
@onready var mp_manager = get_node("/root/Main/MultiplayerManager")
```

**Impact:**
- Breaks if scene structure changes
- Not reusable in other contexts
- Violates encapsulation

**Recommendation:** Use autoload or pass reference:
```gdscript
# Option 1: Autoload (if truly global)
# project.godot: [autoload] MultiplayerManager="*res://scripts/MultiplayerManager.gd"
# lobby.gd:
@onready var mp_manager: MultiplayerManager = $/root/MultiplayerManager

# Option 2: Pass from parent
# game.gd:
func _ready() -> void:
    lobby.mp_manager = mp_manager
```

---

### 9. Multiplayer Sync Inefficiency
**Severity:** MEDIUM  
**File:** `game.gd:838-846`

**Issue:** Sends full board state every 100ms via RPC.

```gdscript
const SYNC_INTERVAL := 0.1

func _send_sync() -> void:
    var data := _encode_board(board)  # 21 * 10 = 210 bytes
    _rpc_sync_state.rpc_id(mp_manager.opponent_id, data, score, lines_total, level, game_over)
```

**Impact:**
- 210 bytes × 10 times/sec = 2.1 KB/s per player
- Unnecessary bandwidth for slow-changing board
- Could cause lag on poor connections

**Recommendation:**
1. Increase sync interval to 200-250ms
2. Send only on state changes (dirty flag)
3. Use delta compression (send only changed rows)
4. Consider unreliable RPC for board state (already using unreliable, good)

```gdscript
const SYNC_INTERVAL := 0.2  # 200ms instead of 100ms

var _last_synced_board: Array = []

func _send_sync() -> void:
    if not _board_has_changed():
        return
    # ... send sync
    _last_synced_board = board.duplicate(true)

func _board_has_changed() -> bool:
    if _last_synced_board.is_empty():
        return true
    for row in range(TOTAL_ROWS):
        for col in range(COLS):
            if board[row][col] != _last_synced_board[row][col]:
                return true
    return false
```

---

### 10. RPC Security Concerns
**Severity:** LOW  
**File:** `game.gd:906-968`

**Issue:** All RPCs use `"any_peer"` transfer mode.

```gdscript
@rpc("any_peer", "unreliable", "call_local")
func _rpc_sync_state(...) -> void:
```

**Impact:** In a public multiplayer setting, malicious clients could send invalid data.

**Recommendation:** For production:
1. Validate all RPC input
2. Use `"authority"` mode where appropriate
3. Add rate limiting
4. Implement anti-cheat checks

```gdscript
@rpc("any_peer", "reliable")
func _rpc_send_game_over(opp_score: int, opp_lines: int, ...) -> void:
    # Validate input
    if opp_score < 0 or opp_lines < 0:
        return  # Reject invalid data
    # ... rest of function
```

---

## Gameplay Issues

### 11. DAS (Delayed Auto Shift) Implementation
**Severity:** LOW  
**File:** `game.gd:230-251`

**Issue:** DAS logic is complex and could be simplified.

```gdscript
if Input.is_action_just_pressed("move_left"):
    _move(-1, 0)
    das_dir = -1
    das_timer = 0.0
# ... many lines of DAS handling
```

**Impact:** Hard to maintain, potential edge cases.

**Recommendation:** Extract to dedicated function or use Godot's built-in input buffering:
```gdscript
func _handle_das_input() -> void:
    if Input.is_action_just_pressed("move_left"):
        _move(-1, 0)
        _start_das(-1)
    elif Input.is_action_just_pressed("move_right"):
        _move(1, 0)
        _start_das(1)
    # ... etc

func _start_das(direction: int) -> void:
    das_dir = direction
    das_timer = 0.0
```

---

### 12. Board Initialization Inefficiency
**Severity:** LOW  
**File:** `game.gd:413-419`

**Issue:** Uses nested loops to initialize board.

```gdscript
board = []
for _i in range(TOTAL_ROWS):
    var r: Array = []
    for _j in range(COLS):
        r.append(0)
        board.append(r)  # BUG: This appends 'r' multiple times!
```

**Impact:** 
- **BUG:** The inner loop appends `r` to `board` on every iteration, creating 210 references to the same array instead of 21 separate arrays.
- Performance impact is minimal for this size, but logic is wrong.

**Recommendation:**
```gdscript
board = []
for _i in range(TOTAL_ROWS):
    var r: Array[int] = []
    r.resize(COLS)  # Creates array of 21 zeros
    r.fill(0)
    board.append(r)

# Or even simpler:
board.resize(TOTAL_ROWS)
for i in range(TOTAL_ROWS):
    board[i] = []
    board[i].resize(COLS)
    board[i].fill(0)
```

**Wait, let me re-read the code...**

Actually, looking more carefully:
```gdscript
for _i in range(TOTAL_ROWS):
    var r: Array = []
    for _j in range(COLS):
        r.append(0)
        board.append(r)  # This is inside the inner loop!
```

This creates `TOTAL_ROWS * COLS = 210` entries in `board`, each being a reference to the same array `r`. This is definitely a **CRITICAL BUG**.

**Severity:** CRITICAL  
**Impact:** Board operations will corrupt data because all rows reference the same array.

**Fix:**
```gdscript
board = []
for _i in range(TOTAL_ROWS):
    var r: Array[int] = []
    for _j in range(COLS):
        r.append(0)
    board.append(r)  # Move this outside the inner loop
```

---

### 13. Missing Hold Piece Feature
**Severity:** LOW  
**File:** `game.gd`

**Issue:** Modern Tetris implementations include a "hold" piece feature (swap current piece with held piece).

**Impact:** Missing feature compared to standard Tetris games.

**Recommendation:** Add hold piece functionality for better gameplay experience.

---

### 14. No T-Spin Detection
**Severity:** LOW  
**File:** `game.gd:603-631`

**Issue:** Line clearing doesn't detect T-spins, which are important in modern Tetris.

**Impact:** Missing scoring opportunity, less authentic gameplay.

**Recommendation:** Implement T-spin detection for advanced players.

---

## UI/UX Issues

### 15. Lobby UI Layout Issues
**Severity:** LOW  
**File:** `ui/lobby.tscn:117-125`

**Issue:** Logo icon has hardcoded absolute positioning.

```
[node name="LogoIcon" type="TextureRect" parent="." unique_id=2015978560]
custom_minimum_size = Vector2(250, 250)
offset_left = 180.0
offset_top = 200.0
```

**Impact:** May not scale well to different resolutions.

**Recommendation:** Use anchors and containers for responsive layout.

---

### 16. No Visual Feedback for Soft Drop
**Severity:** LOW  
**File:** `game.gd:220-223`

**Issue:** Soft drop doesn't provide visual feedback beyond faster falling.

**Recommendation:** Add subtle visual indicator (e.g., trail effect, color tint) when soft dropping.

---

### 17. Game Over Screen Timing
**Severity:** LOW  
**File:** `game.gd:213-218`

**Issue:** After game over, play_time continues to increment.

```gdscript
if game_over:
    play_time += delta  # Should stop counting
    _update_ui()
```

**Recommendation:** Stop play_time when game_over is true.

---

## Documentation Issues

### 18. Inconsistent Documentation
**Severity:** LOW  
**Files:** All scripts

**Issue:** `game.gd` has excellent docstrings, but other scripts lack them.

**Recommendation:** Add docstrings to all public functions:
```gdscript
# lobby.gd
## Handles the host button press. Validates port and initiates hosting.
func _on_host_button_pressed() -> void:
    # ...
```

---

## Testing & Quality Assurance

### 19. No Visible Test Suite
**Severity:** MEDIUM  
**Files:** Project root

**Issue:** No test files found in the project.

**Recommendation:** Add unit tests for:
- Board collision detection
- Line clearing logic
- Piece rotation with wall kicks
- Scoring calculations
- Multiplayer sync encoding/decoding

---

### 20. No Input Validation
**Severity:** MEDIUM  
**Files:** `lobby.gd`

**Issue:** Minimal validation of user input.

```gdscript
# lobby.gd:84
var port := int(port_edit.text)
if port <= 0 or port > 65535:
    # Basic validation exists
```

**Recommendation:** Add validation for:
- IP address format
- Player name length/characters
- Port number (already done)

---

## Positive Aspects

### Strengths
1. **Excellent documentation in game.gd** - Comprehensive docstrings with parameter descriptions
2. **Proper use of SRS rotation system** - Wall kick tables correctly implemented
3. **7-bag randomizer** - Correct implementation for fair piece distribution
4. **Ghost piece** - Nice visual feedback for piece landing position
5. **Signal-based architecture** - Good use of signals for loose coupling
6. **Proper RPC usage** - Correct use of reliable/unreliable transfer modes
7. **Clean scene structure** - Well-organized scene tree
8. **UID usage** - Proper use of UIDs instead of file paths
9. **Input handling** - Correct separation of continuous (_process) and discrete (_unhandled_input) input
10. **Performance considerations** - Uses queue_redraw() appropriately

---

## Recommendations Priority List

### Immediate (Before Release)
1. **Fix critical board initialization bug** (Issue #12)
2. **Add class_name declarations** (Issue #1)
3. **Add type annotations** (Issue #6)
4. **Remove debug prints** (Issue #7)
5. **Verify Godot 4.7 API compatibility** (Issue #2)

### Short-term (Next Sprint)
6. **Refactor game.gd** into smaller scripts (Issue #4)
7. **Extract magic numbers to constants** (Issue #5)
8. **Fix hardcoded node paths** (Issue #8)
9. **Add input validation** (Issue #20)
10. **Optimize multiplayer sync** (Issue #9)

### Long-term (Future Updates)
11. **Add hold piece feature** (Issue #13)
12. **Implement T-spin detection** (Issue #14)
13. **Add unit tests** (Issue #19)
14. **Improve UI responsiveness** (Issue #15)
15. **Add RPC security** (Issue #10)

---

## Conclusion

Bloxel demonstrates solid fundamentals in Godot game development. The core Tetris mechanics are well-implemented with proper SRS rotation, 7-bag randomization, and ghost pieces. The multiplayer architecture using ENet is sound.

However, several critical issues need immediate attention:
- The board initialization bug (#12) will cause data corruption
- Missing class_name declarations violate the project's own style guide
- The game.gd file is too large and needs refactoring

With these fixes and the recommended improvements, Bloxel has the potential to be a polished, production-ready Tetris clone.

**Final Grade:** B- (70/100)
- Functionality: 85/100
- Code Quality: 65/100
- Architecture: 60/100
- Documentation: 80/100
- Testing: 40/100

---

## Appendix: Code Examples

### Fixed Board Initialization
```gdscript
## Corrected version of _new_game() board initialization
func _new_game() -> void:
    board = []
    for _i in range(TOTAL_ROWS):
        var row: Array[int] = []
        for _j in range(COLS):
            row.append(0)
        board.append(row)  # Fixed: moved outside inner loop
    # ... rest of function
```

### Example Refactored Structure
```gdscript
# scripts/board.gd
class_name Board extends RefCounted

const COLS := 10
const TOTAL_ROWS := 21

var cells: Array[Array[int]] = []

func _init() -> void:
    clear()

func clear() -> void:
    cells = []
    for _i in range(TOTAL_ROWS):
        var row: Array[int] = []
        row.resize(COLS)
        row.fill(0)
        cells.append(row)

func is_valid_position(piece_cells: Array, px: int, py: int) -> bool:
    for cell in piece_cells:
        var cx := px + int(cell.x)
        var cy := py + int(cell.y)
        if cx < 0 or cx >= COLS or cy >= TOTAL_ROWS:
            return false
        if cy >= 0 and cells[cy][cx] != 0:
            return false
    return true

# ... more board methods
```

---

*Review generated by qwen3.7-plus on 2026-07-10*
