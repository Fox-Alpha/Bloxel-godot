class_name Lobby
extends Control
## Lobby-Overlay: Spielername, Einzelspieler, Host/Join und Beenden.
##
## Liest die Eingaben des Formulars, startet über den [MultiplayerManager] Host oder Join
## und zeigt den Verbindungsstatus an. In Debug-Builds wird zusätzlich ein [DevAutostart] angehängt.

#region Signals
## Wird emittiert, wenn der Einzelspieler-Button gedrückt wurde.
signal single_player_requested()
## Wird emittiert, wenn ein Gegner verbunden ist und das Mehrspieler-Spiel starten kann.
signal game_started()
#endregion

#region Exports
## Verbindung zum Netzwerk, wird in der Hauptszene zugewiesen.
@export var mp_manager: MultiplayerManager
#endregion

#region Public Vars
## Spielername ohne Rollenzusatz, wird beim Host/Join aus dem Namensfeld übernommen.
var player_name: String = ""
#endregion

#region Private Vars
## Ob gerade ein Host- oder Join-Vorgang läuft (verhindert doppelte Klicks).
var _connecting: bool = false
## Rolle dieser Instanz für den Fenstertitel, leer solange keine Verbindung besteht.
var _window_role: String = ""
#endregion

#region OnReady Vars
## Titel-Label der Lobby.
@onready var title_label: Label = $VBox/TitleLabel
## Eingabefeld für den Spielernamen.
@onready var name_edit: LineEdit = $VBox/NameHBox/NameEdit
## Button für den Einzelspieler-Modus.
@onready var single_button: Button = $VBox/SingleButton
## Eingabefeld für den Port beim Hosten.
@onready var port_edit: LineEdit = $VBox/PortHBox/PortEdit
## Button zum Hosten.
@onready var host_button: Button = $VBox/HostButton
## Eingabefeld für die IP-Adresse des Hosts.
@onready var ip_edit: LineEdit = $VBox/IPHBox/IPEdit
## Eingabefeld für den Port beim Beitreten.
@onready var join_port_edit: LineEdit = $VBox/JoinPortHBox/JoinPortEdit
## Button zum Beitreten.
@onready var join_button: Button = $VBox/JoinButton
## Label für den Verbindungsstatus.
@onready var status_label: Label = $VBox/StatusLabel
## Button zum Beenden des Spiels.
@onready var quit_button: Button = $VBox/QuitButton
#endregion


#region Lifecycle
## Setzt Fenstertitel und Standardwerte, verbindet Buttons und Manager-Signale
## und hängt in Debug-Builds den [DevAutostart] an.
func _ready() -> void:
	var pid := OS.get_process_id()
	Log.log("[PID:%d] lobby _ready" % pid)
	_set_pid_title()
	get_tree().create_timer(0.3).timeout.connect(_set_pid_title)
	port_edit.text = str(mp_manager.DEFAULT_PORT)
	join_port_edit.text = str(mp_manager.DEFAULT_PORT)
	ip_edit.text = "127.0.0.1"
	_update_status("Idle")
	single_button.pressed.connect(_on_single_button_pressed)
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	mp_manager.host_ready.connect(_on_host_ready)
	mp_manager.join_success.connect(_on_join_success)
	mp_manager.join_failed.connect(_on_join_failed)
	mp_manager.peer_disconnected.connect(_on_peer_disconnected)
	mp_manager.game_start_requested.connect(_on_game_start_requested)
	if OS.is_debug_build():
		add_child(DevAutostart.new())
#endregion


#region Public Funcs
## Liest den Namen aus dem Namensfeld (Vorgabe "Spieler 1" bzw. "Spieler 2") und speichert ihn in
## [member player_name].
## [param is_host_role] — [code]true[/code] für die Host-Rolle.
## [b]return[/b] [String] — Name mit Zusatz " (Host)" bzw. " (Client)".
func get_display_name(is_host_role: bool) -> String:
	var base := name_edit.text.strip_edges()
	if base.is_empty():
		if is_host_role:
			base = "Spieler 1"
		else:
			base = "Spieler 2"
	player_name = base
	if is_host_role:
		return base + " (Host)"
	return base + " (Client)"


## Setzt die Lobby in den Ausgangszustand zurück: Formular aktiv, Status "Idle", keine Rolle im Fenstertitel.
func reset() -> void:
	_connecting = false
	_set_window_role("")
	_set_form_enabled(true)
	_update_status("Idle")


## Zeigt eine Statusmeldung in der Lobby an.
## [param msg] — Anzuzeigender Text.
func set_status(msg: String) -> void:
	_update_status(msg)
#endregion


#region Private Funcs
## Setzt den Fenstertitel aus Rolle (falls vorhanden) und Prozess-ID, um mehrere Instanzen zu unterscheiden.
func _set_pid_title() -> void:
	var pid := OS.get_process_id()
	var role_text := "" if _window_role.is_empty() else _window_role + " | "
	DisplayServer.window_set_title("Bloxel [%sPID: %d]" % [role_text, pid])


## Merkt sich die Rolle dieser Instanz und aktualisiert den Fenstertitel.
## [param window_role] — "Server", "Client" oder leer.
func _set_window_role(window_role: String) -> void:
	_window_role = window_role
	_set_pid_title()


## Schreibt die Statusmeldung mit Präfix "Status: " ins Status-Label.
## [param msg] — Anzuzeigender Text.
func _update_status(msg: String) -> void:
	status_label.text = "Status: " + msg


## Aktiviert oder sperrt Buttons und Eingabefelder des Formulars.
## [param enabled] — [code]true[/code] aktiviert, [code]false[/code] sperrt.
func _set_form_enabled(enabled: bool) -> void:
	single_button.disabled = not enabled
	host_button.disabled = not enabled
	join_button.disabled = not enabled
	name_edit.editable = enabled
	port_edit.editable = enabled
	ip_edit.editable = enabled
	join_port_edit.editable = enabled
#endregion


#region Signal Callbacks
## Fordert den Einzelspieler-Modus an und blendet die Lobby aus.
func _on_single_button_pressed() -> void:
	single_player_requested.emit()
	hide()


## Beendet das Spiel. Eine wartende Verbindung wird vorher getrennt.
func _on_quit_button_pressed() -> void:
	mp_manager.stop()
	get_tree().quit()


## Prüft den Port und startet den Host. Bei ungültigem Port wird das Formular wieder freigegeben.
func _on_host_button_pressed() -> void:
	if _connecting:
		return
	Log.log("[PID:%d] Host button clicked" % OS.get_process_id())
	_connecting = true
	_set_form_enabled(false)
	var port := int(port_edit.text)
	if port <= 0 or port > 65535:
		_update_status("Invalid port")
		_connecting = false
		_set_form_enabled(true)
		return
	player_name = get_display_name(true)
	_set_window_role("Server")
	mp_manager.host(port)
	_update_status("Hosting on port " + str(port) + "...")


## Prüft IP und Port und startet den Verbindungsaufbau. Bei ungültigen Eingaben wird das Formular wieder
## freigegeben.
func _on_join_button_pressed() -> void:
	if _connecting:
		return
	Log.log("[PID:%d] Join button clicked" % OS.get_process_id())
	_connecting = true
	_set_form_enabled(false)
	var ip := ip_edit.text.strip_edges()
	var port := int(join_port_edit.text)
	if ip.is_empty():
		_update_status("Enter an IP address")
		_connecting = false
		_set_form_enabled(true)
		return
	if port <= 0 or port > 65535:
		_update_status("Invalid port")
		_connecting = false
		_set_form_enabled(true)
		return
	player_name = get_display_name(false)
	_set_window_role("Client")
	mp_manager.join(ip, port)
	_update_status("Connecting to " + ip + ":" + str(port) + "...")


## Host: Server steht, zeigt den Wartestatus an.
func _on_host_ready() -> void:
	_update_status("Waiting for opponent...")


## Client: Verbindung steht, zeigt den Startstatus an.
func _on_join_success() -> void:
	_connecting = false
	_update_status("Connected! Starting game...")


## Zeigt den Fehlergrund an und gibt das Formular wieder frei.
## [param reason] — Fehlermeldung des [MultiplayerManager].
func _on_join_failed(reason: String) -> void:
	_update_status(reason)
	_set_window_role("")
	_connecting = false
	_set_form_enabled(true)


## Zeigt die Trennung an und gibt das Formular wieder frei.
func _on_peer_disconnected() -> void:
	_update_status("Opponent disconnected")
	_set_window_role("")
	_connecting = false
	_set_form_enabled(true)


## Gegner ist verbunden: meldet den Spielstart und blendet die Lobby aus.
func _on_game_start_requested() -> void:
	_connecting = false
	game_started.emit()
	hide()
#endregion
