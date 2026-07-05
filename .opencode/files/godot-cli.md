---
category: reference
tool: godot
language: gdscript
---

# Godot CLI Reference
here you will find the cli flags for the godot engine.


> Godot Engine v4.6.2 — [godotengine.org](https://godotengine.org)

```bash
gd4 [options] [path to "project.godot" file]
```

## Legend

| Symbol | Availability |
|---|---|
| **R** | Editor builds, debug & release export templates |
| **D** | Editor builds and debug export templates only |
| **X** | Editor builds and export templates with `disable_path_overrides=false` |
| **E** | Editor builds only |

---

## General Options

| Option | Avail. | Description |
|---|---|---|
| `-h`, `--help` | R | Display this help message |
| `--version` | R | Display the version string |
| `-v`, `--verbose` | R | Use verbose stdout mode |
| `--quiet` | R | Quiet mode — silences stdout, errors still shown |
| `--no-header` | R | Do not print engine version/rendering header on startup |

---

## Run Options

| Option | Avail. | Description |
|---|---|---|
| `--`, `++` | R | Separator for user-provided arguments (readable via `OS.get_cmdline_user_args()`) |
| `-e`, `--editor` | E | Start the editor instead of running the scene |
| `-p`, `--project-manager` | E | Start the project manager |
| `--recovery-mode` | E | Start editor with tool scripts, plugins and GDExtensions disabled |
| `--debug-server <uri>` | E | Start editor debug server (`<protocol>://<host>[:<port>]`) |
| `--dap-port <port>` | E | Port for GDScript Debug Adapter Protocol (range: 1024–49151) |
| `--lsp-port <port>` | E | Port for GDScript Language Server Protocol (range: 1024–49151) |
| `--quit` | R | Quit after the first iteration |
| `--quit-after <int>` | R | Quit after N iterations (0 = disabled) |
| `-l`, `--language <locale>` | R | Use a specific locale (two-letter code) |
| `--path <directory>` | X | Path to a project directory (must contain `project.godot`) |
| `--scene <path>` | X | Path or UID of a scene to start |
| `--main-pack <file>` | X | Path to a `.pck` pack file to load |
| `--render-thread <mode>` | R | Render thread mode: `safe`, `separate` *(deprecated: `unsafe`)* |
| `--remote-fs <address>` | D | Remote filesystem (`<host>[:<port>]`) |
| `--remote-fs-password <pw>` | D | Password for remote filesystem |
| `--audio-driver <driver>` | R | Audio driver: `PulseAudio`, `ALSA`, `Dummy` |
| `--display-driver <driver>` | R | Display driver: `x11`, `wayland`, `headless` (each supports sub-drivers) |
| `--audio-output-latency <ms>` | R | Override audio output latency in ms (default: 15 ms) |
| `--rendering-method <renderer>` | R | Renderer name (requires driver support) |
| `--rendering-driver <driver>` | R | Rendering driver (depends on display driver) |
| `--gpu-index <index>` | R | Use a specific GPU (run with `--verbose` to list devices) |
| `--text-driver <driver>` | R | Text driver for font rendering and bidirectional support |
| `--tablet-driver <driver>` | R | Pen tablet input driver |
| `--headless` | R | Enable headless mode (`--display-driver headless --audio-driver Dummy`) — useful for servers and scripting |
| `--log-file <file>` | R | Write log to specified path (absolute or relative to project dir) |
| `--write-movie <file>` | R | Write video to path (`.avi` or `.png`). Use with `--fixed-fps`, `--quit-after` |

---

## Display Options

| Option | Avail. | Description |
|---|---|---|
| `-f`, `--fullscreen` | R | Request fullscreen mode |
| `-m`, `--maximized` | R | Request maximized window |
| `-w`, `--windowed` | R | Request windowed mode |
| `-t`, `--always-on-top` | R | Request always-on-top window |
| `--resolution <W>x<H>` | R | Request window resolution |
| `--position <X>,<Y>` | R | Request window position |
| `--screen <N>` | R | Request window screen |
| `--single-window` | R | Use a single window (no separate subwindows) |
| `--xr-mode <mode>` | R | XR mode: `default`, `off`, `on` |
| `--wid <window_id>` | R | Request window parented to given ID |
| `--accessibility <mode>` | R | Accessibility mode: `auto` (default), `always`, `disabled` |

---

## Debug Options

| Option | Avail. | Description |
|---|---|---|
| `-d`, `--debug` | R | Local stdout debugger |
| `-b`, `--breakpoints` | R | Breakpoint list as `source::line` pairs, comma-separated (use `%%20` for spaces) |
| `--ignore-error-breaks` | R | Prevent sending error breakpoints to connected debugger |
| `--profiling` | R | Enable profiling in the script debugger |
| `--gpu-profile` | R | Show GPU profile of slowest frame tasks |
| `--gpu-validation` | R | Enable graphics API validation layers |
| `--gpu-abort` | D | Abort on graphics API errors (helps identify freeze causes) |
| `--generate-spirv-debug-info` | R | Generate SPIR-V debug info for Vulkan (enables RenderDoc source-level shader debugging) |
| `--extra-gpu-memory-tracking` | R | Enable additional GPU memory tracking (Vulkan only — may cause crashes on some systems) |
| `--accurate-breadcrumbs` | R | Force barriers between breadcrumbs (Vulkan only — helps narrow down GPU resets) |
| `--remote-debug <uri>` | R | Remote debug (`<protocol>://<host>[:<port>]`) |
| `--single-threaded-scene` | R | Force scene tree to run single-threaded |
| `--debug-collisions` | D | Show collision shapes in-scene |
| `--debug-paths` | D | Show path lines in-scene |
| `--debug-navigation` | D | Show navigation polygons in-scene |
| `--debug-avoidance` | D | Show navigation avoidance debug visuals |
| `--debug-stringnames` | D | Print all StringName allocations on quit |
| `--debug-canvas-item-redraw` | D | Highlight canvas items requesting redraw |
| `--max-fps <fps>` | R | Limit frames per second (0 = unlimited) |
| `--frame-delay <ms>` | R | Simulate high CPU load (delay each frame by N ms) |
| `--time-scale <scale>` | R | Force time scale (1.0 = normal) |
| `--disable-vsync` | R | Force-disable vertical synchronization |
| `--disable-render-loop` | R | Disable render loop (render only on explicit script call) |
| `--disable-crash-handler` | R | Disable crash handler |
| `--fixed-fps <fps>` | R | Force fixed FPS (disables real-time synchronization) |
| `--delta-smoothing <enable>` | R | Enable/disable frame delta smoothing: `enable`, `disable` |
| `--print-fps` | R | Print FPS to stdout |
| `--editor-pseudolocalization` | E | Enable pseudolocalization for editor and project manager |

---

## Standalone Tools

| Option | Avail. | Description |
|---|---|---|
| `-s`, `--script <script>` | X | Run a script |
| `--main-loop <name>` | X | Run a MainLoop by its global class name |
| `--check-only` | X | Parse for errors and quit (use with `--script`) |
| `--import` | E | Start editor, wait for import, then quit |
| `--export-release <preset> <path>` | E | Export project in release mode |
| `--export-debug <preset> <path>` | E | Export project in debug mode |
| `--export-pack <preset> <path>` | E | Export project data only (PCK or ZIP based on extension) |
| `--export-patch <preset> <path>` | E | Export pack with changed files only |
| `--patches <paths>` | E | Comma-separated patch list for `--export-patch` |
| `--install-android-build-template` | E | Install Android build template |
| `--convert-3to4 [max_file_kb] [max_line_size]` | E | Convert project from Godot 3.x to 4.x |
| `--validate-conversion-3to4 [max_file_kb] [max_line_size]` | E | Preview what will be renamed in a 3→4 conversion |
| `--doctool [path]` | E | Dump engine API reference as XML (merges with existing) |
| `--no-docbase` | E | Disallow dumping base types (use with `--doctool`) |
| `--gdextension-docs` | E | Generate API reference from GDExtensions (use with `--doctool`) |
| `--gdscript-docs <path>` | E | Generate API reference from inline GDScript docs (use with `--doctool`) |
| `--build-solutions` | E | Build scripting solutions (e.g. C# projects) |
| `--dump-gdextension-interface` | E | Generate `gdextension_interface.h` in current folder |
| `--dump-gdextension-interface-json` | E | Generate `gdextension_interface.json` in current folder |
| `--dump-extension-api` | E | Generate `extension_api.json` for GDExtension bindings |
| `--dump-extension-api-with-docs` | E | Same as above, including documentation |
| `--validate-extension-api <path>` | E | Validate extension API compatibility (non-zero exit on error) |
| `--benchmark` | E | Benchmark run time and print to console |
| `--benchmark-file <path>` | E | Benchmark run time and save to JSON (absolute path) |

---

## Common Usage Examples

```bash
# Open a project in the editor
gd4 --editor --path /path/to/project

# Run a specific scene
gd4 --path /path/to/project --scene res://scenes/main.tscn

# Headless script execution (server/CI)
gd4 --headless --script res://tools/build.gd

# Export release build
gd4 --path /path/to/project --export-release "Linux" builds/game.x86_64

# Export debug build
gd4 --path /path/to/project --export-debug "Windows Desktop" builds/game.exe

# Check scripts for errors only
gd4 --path /path/to/project --check-only --script res://src/main.gd

# Run with debug visuals
gd4 --path /path/to/project --debug-collisions --debug-navigation
```
