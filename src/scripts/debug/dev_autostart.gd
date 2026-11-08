class_name DevAutostart
extends Node
## Startet eine Debug-Instanz automatisch in einer festgelegten Rolle.
##
## Wird nur aktiv, wenn die Instanz mit [code]--instance=N[/code] gestartet wurde
## (Debug > Customize Run Instances). Die Rolle je Instanz steht in [constant ROLES_FILE].[br]
## Erwartet die Lobby als Parent und löst deren Buttons aus, als hätte jemand sie angeklickt.

#region Constants
## Datei mit der Zuordnung Instanz zu Rolle.
const ROLES_FILE: String = "res://scripts/debug/run_roles.cfg"
## Sektion in [constant ROLES_FILE].
const ROLES_SECTION: String = "roles"
## Startargument mit der Nummer der Instanz.
const INSTANCE_ARG: String = "--instance="
## Rolle: Die Lobby bleibt offen.
const ROLE_MENU: String = "menu"
## Rolle: Die Instanz startet als Host.
const ROLE_SERVER: String = "server"
## Rolle: Die Instanz verbindet sich als Client.
const ROLE_CLIENT: String = "client"
## Rolle: Die Instanz startet ein Einzelspiel.
const ROLE_SINGLE: String = "single"
## Wartezeit in Sekunden vor einem erneuten Verbindungsversuch.
const CLIENT_RETRY_DELAY: float = 1.0
## Maximale Anzahl erneuter Verbindungsversuche.
const CLIENT_MAX_RETRIES: int = 10
#endregion

#region Public Vars
## Nummer der Instanz aus [constant INSTANCE_ARG], 0 wenn nicht gesetzt.
var instance_index: int = 0
## Rolle der Instanz aus [constant ROLES_FILE].
var role: String = ROLE_MENU
#endregion

#region Private Vars
## Bisherige erneute Verbindungsversuche.
var _client_retries: int = 0
## Wird gesetzt, sobald der Client verbunden ist.
var _client_connected: bool = false
#endregion

#region OnReady Vars
## Button für das Einzelspiel in der Lobby.
@onready var _single_button: Button = get_node("../VBox/SingleButton")
## Button zum Hosten in der Lobby.
@onready var _host_button: Button = get_node("../VBox/HostButton")
## Button zum Verbinden in der Lobby.
@onready var _join_button: Button = get_node("../VBox/JoinButton")
## Multiplayer-Manager der Lobby.
@onready var _multiplayer_manager: Node = get_parent().get("mp_manager")
#endregion


#region Lifecycle
## Löst je nach Rolle den passenden Button aus. Ohne [code]--instance=N[/code] passiert nichts.
func _ready() -> void:
	instance_index = _read_instance_index()
	if instance_index <= 0:
		return

	role = _read_role(instance_index)
	Log.log("[PID:%d] DevAutostart: Instanz %d, Rolle %s" % [OS.get_process_id(), instance_index, role])
	match role:
		ROLE_SINGLE:
			_press_button.call_deferred(_single_button)
		ROLE_SERVER:
			_press_button.call_deferred(_host_button)
		ROLE_CLIENT:
			_setup_signals()
			_press_button.call_deferred(_join_button)
#endregion


#region Signal Setup
## Verbindet die Rückmeldungen des Verbindungsaufbaus für die Rolle Client.
func _setup_signals() -> void:
	# Über den Namen verbinden, weil der Multiplayer-Manager hier nur als Node typisiert ist.
	_multiplayer_manager.connect("join_success", _on_multiplayer_manager_join_success)
	_multiplayer_manager.connect("join_failed", _on_multiplayer_manager_join_failed)
#endregion


#region Private Funcs
## Liest die Nummer der Instanz aus den Startargumenten.
## [b]return[/b] [int] — Nummer der Instanz, 0 wenn das Argument fehlt.
func _read_instance_index() -> int:
	# Benutzerargumente (nach --) haben Vorrang vor Engine-Argumenten.
	for arg: String in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with(INSTANCE_ARG):
			return arg.trim_prefix(INSTANCE_ARG).to_int()
	return 0


## Liest die Rolle der Instanz aus [constant ROLES_FILE], Rückfall ist [constant ROLE_MENU].
## [param index] — Nummer der Instanz.
## [b]return[/b] [String] — Rolle in Kleinbuchstaben.
func _read_role(index: int) -> String:
	var config := ConfigFile.new()
	var error: Error = config.load(ROLES_FILE)
	if error != OK:
		Log.warn("DevAutostart: %s nicht lesbar (%s)" % [ROLES_FILE, error_string(error)])
		return ROLE_MENU

	var value: String = str(config.get_value(ROLES_SECTION, "instance_%d" % index, ROLE_MENU)).to_lower()
	if value not in [ROLE_MENU, ROLE_SERVER, ROLE_CLIENT, ROLE_SINGLE]:
		Log.warn("DevAutostart: unbekannte Rolle %s für Instanz %d" % [value, index])
		return ROLE_MENU
	return value


## Löst einen Lobby-Button aus, wie ein Klick.
## [param button] — auszulösender Button.
func _press_button(button: Button) -> void:
	button.pressed.emit()

#endregion


#region Signal Callbacks
## Merkt sich die erfolgreiche Verbindung, spätere Trennungen lösen keinen neuen Versuch aus.
func _on_multiplayer_manager_join_success() -> void:
	_client_connected = true


## Wiederholt den Verbindungsaufbau, solange der Client noch nie verbunden war.
## [param _reason] — Fehlermeldung des Multiplayer-Managers.
func _on_multiplayer_manager_join_failed(_reason: String) -> void:
	if _client_connected:
		return
	if _client_retries >= CLIENT_MAX_RETRIES:
		Log.warn("DevAutostart: keine Verbindung nach %d Versuchen" % _client_retries)
		return

	_client_retries += 1
	Log.log(
		"[PID:%d] DevAutostart: Neuer Verbindungsversuch %d/%d"
		% [OS.get_process_id(), _client_retries, CLIENT_MAX_RETRIES]
	)
	# Kurze Pause, damit der Host Zeit zum Starten hat.
	await get_tree().create_timer(CLIENT_RETRY_DELAY).timeout
	_press_button(_join_button)
#endregion
