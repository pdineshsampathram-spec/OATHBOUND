extends Node

## NetworkManager — Autoloaded singleton managing ENet multiplayer peers, lobby, and match transitions.

signal server_started()
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connected_to_server()
signal connection_failed()
signal server_disconnected()
signal players_updated()
signal match_started()

const DEFAULT_PORT: int = 9999
const MAX_PLAYERS: int = 5

var peer: ENetMultiplayerPeer = null
var players: Dictionary = {} # peer_id -> {"name": String, "character": String}
var local_player_name: String = "Warrior"
var local_character_choice: String = "Knight"
var is_match_running: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT, max_clients: int = MAX_PLAYERS - 1) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(port, max_clients)
	if err != OK:
		push_error("NetworkManager: Failed to create server on port %d: %s" % [port, error_string(err)])
		return err

	multiplayer.multiplayer_peer = peer
	players.clear()
	
	# Register host (peer ID 1)
	players[1] = {
		"name": local_player_name + " (Host)",
		"character": local_character_choice
	}
	
	server_started.emit()
	players_updated.emit()
	return OK

func join_game(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(address, port)
	if err != OK:
		push_error("NetworkManager: Failed to create client connecting to %s:%d: %s" % [address, port, error_string(err)])
		return err

	multiplayer.multiplayer_peer = peer
	players.clear()
	return OK

func disconnect_game() -> void:
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null
	players.clear()
	is_match_running = false
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

# --- Signal Callbacks ---

func _on_peer_connected(id: int) -> void:
	player_connected.emit(id)
	if multiplayer.is_server():
		# Send current players list to new peer
		for existing_id in players.keys():
			_register_player.rpc_id(id, existing_id, players[existing_id]["name"], players[existing_id]["character"])

func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	player_disconnected.emit(id)
	players_updated.emit()

func _on_connected_to_server() -> void:
	var my_id: int = multiplayer.get_unique_id()
	_register_player.rpc_id(1, my_id, local_player_name, local_character_choice)
	connected_to_server.emit()
	players_updated.emit()

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	peer = null
	connection_failed.emit()

func _on_server_disconnected() -> void:
	disconnect_game()
	server_disconnected.emit()

# --- RPCs for Lobby & Match Sync ---

@rpc("any_peer", "call_local", "reliable")
func _register_player(id: int, p_name: String, p_char: String) -> void:
	players[id] = {
		"name": p_name,
		"character": p_char
	}
	if multiplayer.is_server():
		# Re-broadcast to all other peers
		_register_player.rpc(id, p_name, p_char)
	players_updated.emit()

@rpc("authority", "call_local", "reliable")
func start_match() -> void:
	is_match_running = true
	match_started.emit()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func is_server() -> bool:
	return multiplayer.is_server() or multiplayer.multiplayer_peer == null
