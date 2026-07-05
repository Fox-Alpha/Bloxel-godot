extends Node

signal host_ready()
signal join_success()
signal join_failed(reason: String)
signal peer_disconnected()
signal game_start_requested()

const DEFAULT_PORT := 21277

var enet_peer: ENetMultiplayerPeer
var is_host: bool = false
var opponent_id: int = 0
var local_player_name: String = "Player 1"


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_peer_disconnected)


func host(port: int = DEFAULT_PORT) -> void:
	print("[PID:", OS.get_process_id(), "] MultiplayerManager.host(port=", port, ")")
	stop()
	enet_peer = ENetMultiplayerPeer.new()
	var err := enet_peer.create_server(port, 1)
	if err != OK:
		print("[PID:", OS.get_process_id(), "] host failed: ", err)
		join_failed.emit("Failed to create server (error " + str(err) + ")")
		return
	multiplayer.multiplayer_peer = enet_peer
	is_host = true
	host_ready.emit()
	print("[PID:", OS.get_process_id(), "] host ready, listening on ", port)


func join(ip: String, port: int = DEFAULT_PORT) -> void:
	print("[PID:", OS.get_process_id(), "] MultiplayerManager.join(ip=", ip, ", port=", port, ")")
	stop()
	enet_peer = ENetMultiplayerPeer.new()
	var err := enet_peer.create_client(ip, port)
	if err != OK:
		print("[PID:", OS.get_process_id(), "] join failed: ", err)
		join_failed.emit("Failed to connect (error " + str(err) + ")")
		return
	multiplayer.multiplayer_peer = enet_peer
	is_host = false
	print("[PID:", OS.get_process_id(), "] join initiated, waiting for connection...")


func _cleanup() -> void:
	if enet_peer != null:
		enet_peer.close()
		enet_peer = null
	multiplayer.multiplayer_peer = null


func stop() -> void:
	is_host = false
	opponent_id = 0
	multiplayer.multiplayer_peer = null
	if enet_peer != null:
		enet_peer.close()
		enet_peer = null


func _on_peer_connected(id: int) -> void:
	opponent_id = id
	game_start_requested.emit()


func _on_peer_disconnected(_id: int = 0) -> void:
	opponent_id = 0
	is_host = false
	peer_disconnected.emit()
	_cleanup.call_deferred()


func _on_connected_to_server() -> void:
	opponent_id = 1
	join_success.emit()


func _on_connection_failed() -> void:
	stop()
	join_failed.emit("Connection failed: no server responding")
