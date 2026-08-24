class_name WaveManager
extends Node

const AICombatController = preload("res://scripts/combat/ai_combat_controller.gd")

## WaveManager — Manages Solo Practice and Endless Waves game modes.
## Spawns and coordinates up to 3 simultaneous realistic AI enemy fighters with progressive difficulty.

signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int)
signal enemy_killed(remaining_in_wave: int)
signal mode_ended(victory: bool, waves_cleared: int)

enum GameMode { PRACTICE_SOLO, ENDLESS_WAVES }

@export var mode: GameMode = GameMode.ENDLESS_WAVES
@export var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
@export var max_simultaneous_enemies: int = 3

@onready var enemies_container: Node3D = $Enemies
@onready var spawn_points_container: Node3D = $EnemySpawnPoints

var current_wave: int = 0
var enemies_remaining_to_spawn: int = 0
var active_enemies: Array[PlayerController] = []
var local_player: PlayerController = null
var is_active: bool = false

# Archetypes for variety
const ARCHETYPES: Array[String] = ["Knight", "Berserker", "Shadow Warrior"]

func _ready() -> void:
	# Defer start until scene is ready
	call_deferred("_initialize_mode")

func _initialize_mode() -> void:
	is_active = true
	# Find local player
	var p_container: Node = get_node_or_null("../Players")
	if p_container and p_container.get_child_count() > 0:
		local_player = p_container.get_child(0) as PlayerController
	
	if not local_player:
		# Search tree
		for p in get_tree().get_nodes_in_group("players"):
			if p is PlayerController and p.is_local_player:
				local_player = p
				break

	if mode == GameMode.PRACTICE_SOLO:
		_start_practice_mode()
	else:
		start_next_wave()

func _start_practice_mode() -> void:
	current_wave = 1
	wave_started.emit(1, 1)
	_spawn_enemy("Knight", 0.4, 0.4, 0.4)

func start_next_wave() -> void:
	if not is_active:
		return
	current_wave += 1
	
	# Wave scaling:
	# Wave 1: 1 enemy
	# Wave 2: 2 enemies
	# Wave 3+: 3+ enemies in stream, max 3 simultaneously
	var total_wave_enemies: int = mini(current_wave + 1, 3 + current_wave * 2)
	enemies_remaining_to_spawn = total_wave_enemies
	wave_started.emit(current_wave, total_wave_enemies)

	# Initial spawn burst up to max_simultaneous_enemies
	var initial_spawn: int = mini(total_wave_enemies, max_simultaneous_enemies)
	for i in range(initial_spawn):
		_spawn_next_queued_enemy()

func _spawn_next_queued_enemy() -> void:
	if enemies_remaining_to_spawn <= 0:
		return
	if active_enemies.size() >= max_simultaneous_enemies:
		return
	
	enemies_remaining_to_spawn -= 1
	var archetype: String = ARCHETYPES.pick_random()
	
	# Progressive AI difficulty scaling
	var aggression: float = clampf(0.35 + (current_wave * 0.08), 0.35, 0.95)
	var reaction: float = clampf(0.3 + (current_wave * 0.07), 0.3, 0.85)
	var skill: float = clampf(0.3 + (current_wave * 0.08), 0.3, 0.9)
	
	_spawn_enemy(archetype, aggression, reaction, skill)

func _spawn_enemy(archetype: String, aggression: float, reaction: float, skill: float) -> void:
	var spawn_pos: Vector3 = _get_safe_spawn_position()
	
	var enemy: PlayerController = player_scene.instantiate() as PlayerController
	enemy.name = "Enemy_%d_%d" % [current_wave, active_enemies.size() + 1]
	enemy.position = spawn_pos
	enemy.sync_character_class = archetype
	enemy.is_ai = true
	enemy.is_local_player = false
	
	# Character resource
	match archetype.to_lower():
		"berserker":
			enemy.character_data = preload("res://resources/characters/berserker.tres")
		"shadow warrior", "shadow_warrior", "phantom":
			enemy.character_data = preload("res://resources/characters/shadow_warrior.tres")
		_:
			enemy.character_data = preload("res://resources/characters/knight.tres")

	enemies_container.add_child(enemy)
	active_enemies.append(enemy)

	# Attach AI Combat Controller
	var ai: AICombatController = AICombatController.new()
	ai.name = "AIController"
	ai.aggression = aggression
	ai.reaction_speed = reaction
	ai.skill_level = skill
	enemy.add_child(ai)
	ai.setup(enemy, local_player, self)

	# Connect death signal
	if enemy.health_component:
		enemy.health_component.died.connect(_on_enemy_died.bind(enemy))

func _on_enemy_died(enemy: PlayerController) -> void:
	if not active_enemies.has(enemy):
		return
	
	active_enemies.erase(enemy)
	enemy_killed.emit(active_enemies.size() + enemies_remaining_to_spawn)

	# Cleanup dead enemy body after brief death animation
	var timer: SceneTreeTimer = get_tree().create_timer(3.0)
	var weak_enemy = weakref(enemy)
	timer.timeout.connect(func():
		var ref = weak_enemy.get_ref()
		if ref and is_instance_valid(ref) and not ref.is_queued_for_deletion():
			ref.queue_free()
	)


	# Practice mode: respawn continuously
	if mode == GameMode.PRACTICE_SOLO:
		var respawn_timer: SceneTreeTimer = get_tree().create_timer(2.0)
		respawn_timer.timeout.connect(func():
			if is_active and active_enemies.is_empty():
				_start_practice_mode()
		)
		return

	# Endless waves mode:
	if enemies_remaining_to_spawn > 0:
		var stream_timer: SceneTreeTimer = get_tree().create_timer(1.5)
		stream_timer.timeout.connect(_spawn_next_queued_enemy)
	elif active_enemies.is_empty():
		# Wave complete!
		wave_completed.emit(current_wave)
		var next_wave_timer: SceneTreeTimer = get_tree().create_timer(3.0)
		next_wave_timer.timeout.connect(start_next_wave)

func _get_safe_spawn_position() -> Vector3:
	var candidate_points: Array[Vector3] = []
	if spawn_points_container and spawn_points_container.get_child_count() > 0:
		for child in spawn_points_container.get_children():
			if child is Node3D:
				candidate_points.append(child.global_position)
	
	if candidate_points.is_empty():
		# Default arena perimeter fallback points
		var rad: float = 9.0
		for angle_deg in [0.0, 72.0, 144.0, 216.0, 288.0]:
			var r: float = deg_to_rad(angle_deg)
			candidate_points.append(Vector3(sin(r) * rad, 0.5, cos(r) * rad))

	# Pick candidate furthest from player and existing enemies
	var best_pos: Vector3 = candidate_points.pick_random()
	var max_min_dist: float = -1.0

	for pt in candidate_points:
		var min_d: float = 999.0
		if local_player and is_instance_valid(local_player):
			min_d = minf(min_d, pt.distance_to(local_player.global_position))
		for e in active_enemies:
			if is_instance_valid(e):
				min_d = minf(min_d, pt.distance_to(e.global_position))
		
		# Prefer distance around 6-12m
		if min_d > 4.0 and min_d > max_min_dist:
			max_min_dist = min_d
			best_pos = pt

	return best_pos

func get_active_enemies() -> Array[PlayerController]:
	return active_enemies
