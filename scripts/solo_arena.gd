class_name SoloArena
extends Node3D

const WaveManager = preload("res://scripts/combat/wave_manager.gd")

## SoloArena — Controller for Solo Practice and Endless Waves Arena.
## Initializes the local player character, connects the CombatHUD, and manages the WaveManager.

@export var player_scene: PackedScene = preload("res://scenes/player/player.tscn")

@onready var players_container: Node3D = $Players
@onready var player_spawn_point: Marker3D = $PlayerSpawnPoint
@onready var wave_manager: WaveManager = $WaveManager
@onready var combat_hud: CombatHUD = $CombatHUD

func _ready() -> void:
	# Determine character from lobby selection if available
	var nm = get_node_or_null("/root/NetworkManager")
	var selected_class: String = "Knight"
	if nm and nm.players.has(1):
		selected_class = nm.players[1].get("character", "Knight")

	_spawn_local_player(selected_class)
	
	if wave_manager and combat_hud:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_completed.connect(_on_wave_completed)
		wave_manager.enemy_killed.connect(_on_enemy_killed)

func _spawn_local_player(c_class: String) -> void:
	var spawn_pos: Vector3 = Vector3(0, 0.5, 0)
	if player_spawn_point:
		spawn_pos = player_spawn_point.global_position

	var player: PlayerController = player_scene.instantiate() as PlayerController
	player.name = "1"
	player.position = spawn_pos
	player.sync_character_class = c_class
	player.is_ai = false
	player.is_local_player = true
	
	# Character resource
	match c_class.to_lower():
		"berserker":
			player.character_data = preload("res://resources/characters/berserker.tres")
		"shadow warrior", "shadow_warrior", "phantom":
			player.character_data = preload("res://resources/characters/shadow_warrior.tres")
		_:
			player.character_data = preload("res://resources/characters/knight.tres")

	players_container.add_child(player)

	if combat_hud:
		combat_hud.connect_player(player)

func _on_wave_started(wave_num: int, count: int) -> void:
	if combat_hud:
		combat_hud.show_announcement("WAVE %d" % wave_num if wave_num > 1 or wave_manager.mode == WaveManager.GameMode.ENDLESS_WAVES else "SOLO PRACTICE", 2.5)

func _on_wave_completed(wave_num: int) -> void:
	if combat_hud:
		combat_hud.show_announcement("WAVE %d CLEARED" % wave_num, 2.0)

func _on_enemy_killed(_remaining: int) -> void:
	pass
