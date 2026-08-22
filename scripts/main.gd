class_name Main
extends Node3D

## Main Match Controller — Manages server-authoritative player spawning, HUD linking, and match state.

@export var player_scene: PackedScene = preload("res://scenes/player/player.tscn")

@onready var players_container: Node3D = $Players
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var spawn_points_container: Node3D = $SpawnPoints
@onready var combat_hud: CombatHUD = $CombatHUD

var spawn_points: Array[Node] = []

func _ready() -> void:
	spawn_points = spawn_points_container.get_children()

	if spawner:
		spawner.spawn_function = _custom_spawn_player

	# If server or offline, spawn all active players
	if NetworkManager.is_server():
		_spawn_all_connected_players()
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# Connect local player to HUD once ready
	_find_and_connect_local_player()

func _spawn_all_connected_players() -> void:
	var player_ids: Array = NetworkManager.players.keys()
	if player_ids.is_empty():
		# Offline fallback
		player_ids = [1]

	for i in range(player_ids.size()):
		var p_id: int = player_ids[i]
		_spawn_player_at_index(p_id, i)

func _spawn_player_at_index(p_id: int, spawn_idx: int) -> void:
	if players_container.has_node(str(p_id)):
		return

	var spawn_pos: Vector3 = Vector3(0, 0, 0)
	var spawn_rot: float = 0.0

	if not spawn_points.is_empty():
		var pt: Marker3D = spawn_points[spawn_idx % spawn_points.size()] as Marker3D
		if pt:
			spawn_pos = pt.global_position
			spawn_rot = pt.global_rotation.y

	var p_node: PlayerController = player_scene.instantiate() as PlayerController
	p_node.name = str(p_id)
	p_node.position = spawn_pos
	p_node.rotation.y = spawn_rot
	players_container.add_child(p_node, true)

func _custom_spawn_player(data: Variant) -> Node:
	var p_node: PlayerController = player_scene.instantiate() as PlayerController
	if data is Dictionary:
		p_node.name = str(data.get("id", 1))
		p_node.position = data.get("pos", Vector3.ZERO)
		p_node.rotation.y = data.get("rot", 0.0)
	return p_node

func _on_peer_disconnected(id: int) -> void:
	if players_container.has_node(str(id)):
		var p_node: Node = players_container.get_node(str(id))
		if p_node:
			p_node.queue_free()

func _find_and_connect_local_player() -> void:
	# Wait for nodes to settle
	await get_tree().process_frame
	await get_tree().process_frame

	var my_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var local_player: PlayerController = null

	for child in players_container.get_children():
		if child is PlayerController and child.name == str(my_id):
			local_player = child
			break

	if local_player and combat_hud:
		combat_hud.connect_player(local_player)
	elif not players_container.get_children().is_empty() and combat_hud:
		# Fallback to first player
		combat_hud.connect_player(players_container.get_child(0) as PlayerController)
