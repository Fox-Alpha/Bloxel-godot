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
@onready var mp_manager = get_node("/root/Main/MultiplayerManager")

var _connecting: bool = false
var player_name: String = ""


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
	else:
		return base + " (Client)"


func _set_pid_title() -> void:
	var pid := OS.get_process_id()
	var title := "Bloxel [PID: " + str(pid) + "]"
	DisplayServer.window_set_title(title)

func _ready() -> void:
	var pid := OS.get_process_id()
	print("[PID:", pid, "] lobby _ready")
	_set_pid_title()
	get_tree().create_timer(0.3).timeout.connect(_set_pid_title)
	port_edit.text = str(mp_manager.DEFAULT_PORT)
	join_port_edit.text = str(mp_manager.DEFAULT_PORT)
	ip_edit.text = "127.0.0.1"
	_update_status("Idle")
	single_button.pressed.connect(_on_single_button_pressed)
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	mp_manager.host_ready.connect(_on_host_ready)
	mp_manager.join_success.connect(_on_join_success)
	mp_manager.join_failed.connect(_on_join_failed)
	mp_manager.peer_disconnected.connect(_on_peer_disconnected)
	mp_manager.game_start_requested.connect(_on_game_start_requested)


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


func _on_host_button_pressed() -> void:
	if _connecting:
		return
	print("[PID:", OS.get_process_id(), "] Host button clicked")
	_connecting = true
	_set_form_enabled(false)
	var port := int(port_edit.text)
	if port <= 0 or port > 65535:
		_update_status("Invalid port")
		_connecting = false
		_set_form_enabled(true)
		return
	player_name = get_display_name(true)
	mp_manager.host(port)
	_update_status("Hosting on port " + str(port) + "...")


func _on_join_button_pressed() -> void:
	if _connecting:
		return
	print("[PID:", OS.get_process_id(), "] Join button clicked")
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
	mp_manager.join(ip, port)
	_update_status("Connecting to " + ip + ":" + str(port) + "...")


func _on_host_ready() -> void:
	_update_status("Waiting for opponent...")


func _on_join_success() -> void:
	_connecting = false
	_update_status("Connected! Starting game...")


func _on_join_failed(reason: String) -> void:
	_update_status(reason)
	_connecting = false
	_set_form_enabled(true)


func _on_peer_disconnected() -> void:
	_update_status("Opponent disconnected")
	_connecting = false
	_set_form_enabled(true)


func reset() -> void:
	_connecting = false
	_set_form_enabled(true)
	_update_status("Idle")


func set_status(msg: String) -> void:
	_update_status(msg)


func _on_game_start_requested() -> void:
	_connecting = false
	game_started.emit()
	hide()
