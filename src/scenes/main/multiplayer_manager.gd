class_name MultiplayerManager
extends Node
## ENet-Peer-Setup/Teardown und Multiplayer-Signale.
##
## Kapselt die Netzwerk-Verbindung (Host/Join) und stellt Signale für
## Verbindungsereignisse bereit. Die Aufräumarbeit (close vor null) vermeidet
## Race Conditions zwischen Peer-Callbacks und explizitem [method stop].

#region Signals
signal host_ready()
signal join_success()
signal join_failed(reason: String)
signal peer_disconnected()
signal game_start_requested()
#endregion

#region Constants
const DEFAULT_PORT := 21277
#endregion

#region Public Vars
var enet_peer: ENetMultiplayerPeer
var is_host: bool = false
var opponent_id: int = 0
#endregion

#region Private Vars
## Guard gegen doppeltes Aufräumen (deferred _cleanup vs. expliziter stop).
var _is_cleaning: bool = false
#endregion


#region Lifecycle
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_peer_disconnected)
#endregion


#region Public Funcs
## Startet einen Host-Server auf dem gegebenen Port.
func host(port: int = DEFAULT_PORT) -> void:
	Log.log("[PID:%d] MultiplayerManager.host(port=%d)" % [OS.get_process_id(), port])
	stop()
	enet_peer = ENetMultiplayerPeer.new()
	var err := enet_peer.create_server(port, 1)
	if err != OK:
		Log.error("[PID:%d] host failed: %s" % [OS.get_process_id(), error_string(err)])
		join_failed.emit("Failed to create server (error " + str(err) + ")")
		return
	multiplayer.multiplayer_peer = enet_peer
	is_host = true
	host_ready.emit()
	Log.log("[PID:%d] host ready, listening on %d" % [OS.get_process_id(), port])


## Verbindet sich als Client mit Host unter ip:port.
func join(ip: String, port: int = DEFAULT_PORT) -> void:
	Log.log("[PID:%d] MultiplayerManager.join(ip=%s, port=%d)" % [OS.get_process_id(), ip, port])
	stop()
	enet_peer = ENetMultiplayerPeer.new()
	var err := enet_peer.create_client(ip, port)
	if err != OK:
		Log.error("[PID:%d] join failed: %s" % [OS.get_process_id(), error_string(err)])
		join_failed.emit("Failed to connect (error " + str(err) + ")")
		return
	multiplayer.multiplayer_peer = enet_peer
	is_host = false
	Log.log("[PID:%d] join initiated, waiting for connection..." % OS.get_process_id())


## Stoppt die Multiplayer-Sitzung explizit (gleiche Reihenfolge wie _cleanup).
func stop() -> void:
	is_host = false
	opponent_id = 0
	# Erst den Peer schliessen, dann die multiplayer_peer-Referenz lösen.
	if enet_peer != null:
		enet_peer.close()
		enet_peer = null
	multiplayer.multiplayer_peer = null
#endregion


#region Private Funcs
## Schliesst den Peer und löst die Multiplayer-Verbindung.
## Reihenfolge: erst close(), dann null — verhindert, dass ein zwischen-
## durch feuernder Callback auf einem halboffenen Zustand operiert.
func _cleanup() -> void:
	if _is_cleaning:
		return
	_is_cleaning = true
	if enet_peer != null:
		enet_peer.close()
		enet_peer = null
	multiplayer.multiplayer_peer = null
	_is_cleaning = false
#endregion


#region Signal Callbacks
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
#endregion
