class_name Lobby
extends Control

signal single_player_requested()
signal game_started()

@onready var title_label: Label = $VBox/TitleLabel
@onready var name_edit: LineEdit = $VBox/NameHBox/NameEdit
@onready var single_button: Button = $VBox/SingleButton
@onready var port_edit: LineEdit = $VBox/PortHBox/PortEdit
@onready var host_button: Button = $VBox/HostButton
@onready var ip_edit: LineEdit = $VBox/IPHBox/IPEdit
@onready var join_port_edit: LineEdit = $VBox/JoinPortHBox/JoinPortEdit
@onready var join_button: Button = $VBox/JoinButton
@onready var status_label: Label = $VBox/StatusLabel
@onready var quit_button: Button = $VBox/QuitButton
@onready var mp_manager: MultiplayerManager = get_node("/root/Main/MultiplayerManager")

var _connecting: bool = false
var player_name: String = ""
## Rolle dieser Instanz für den Fenstertitel, leer solange keine Verbindung besteht.
var _window_role: String = ""


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


func _set_pid_title() -> void:
	var pid := OS.get_process_id()
	var role_text := "" if _window_role.is_empty() else _window_role + " | "
	DisplayServer.window_set_title("Bloxel [%sPID: %d]" % [role_text, pid])


## Merkt sich die Rolle dieser Instanz und aktualisiert den Fenstertitel.
## [param window_role] — "Server", "Client" oder leer.
func _set_window_role(window_role: String) -> void:
	_window_role = window_role
	_set_pid_title()

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


func _update_status(msg: String) -> void:
	status_label.text = "Status: " + msg


func _set_form_enabled(enabled: bool) -> void:
	single_button.disabled = not enabled
	host_button.disabled = not enabled
	join_button.disabled = not enabled
	name_edit.editable = enabled
	port_edit.editable = enabled
	ip_edit.editable = enabled
	join_port_edit.editable = enabled


func _on_single_button_pressed() -> void:
	single_player_requested.emit()
	hide()


## Beendet das Spiel. Eine wartende Verbindung wird vorher getrennt.
func _on_quit_button_pressed() -> void:
	mp_manager.stop()
	get_tree().quit()


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


func _on_host_ready() -> void:
	_update_status("Waiting for opponent...")


func _on_join_success() -> void:
	_connecting = false
	_update_status("Connected! Starting game...")


func _on_join_failed(reason: String) -> void:
	_update_status(reason)
	_set_window_role("")
	_connecting = false
	_set_form_enabled(true)


func _on_peer_disconnected() -> void:
	_update_status("Opponent disconnected")
	_set_window_role("")
	_connecting = false
	_set_form_enabled(true)


func reset() -> void:
	_connecting = false
	_set_window_role("")
	_set_form_enabled(true)
	_update_status("Idle")


func set_status(msg: String) -> void:
	_update_status(msg)


func _on_game_start_requested() -> void:
	_connecting = false
	game_started.emit()
	hide()
