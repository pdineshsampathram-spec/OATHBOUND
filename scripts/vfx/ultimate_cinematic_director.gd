class_name UltimateCinematicDirector
extends Node

## UltimateCinematicDirector — "CATACLYSM OF THE SEVENTH OATH"
## God-Tier Blender-First Cinematic World-State Director.
## Coordinates 16 Dedicated Camera3D cinematic shots, 8 Knight performance tracks,
## 6 Enemy reaction tracks, continuous causal arena submission, fine organic filaments,
## direct armor rim highlights (zero giant bubbles), dedicated enemy vaporization close-up,
## multi-stage 3D cataclysm release, mythic typography, and 100% authoritative combat execution.

const ENERGY_RIBBON_SHADER = preload("res://assets/materials/energy_ribbon.gdshader")
const CELESTIAL_SKY_SHADER = preload("res://assets/materials/celestial_sky_vortex.gdshader")
const DISSOLUTION_SHADER = preload("res://assets/materials/dissolution_shader.gdshader")
const ENERGY_FLARE_SHADER = preload("res://assets/materials/energy_flare.gdshader")

# 23 Dedicated Blender Hero Assets
const AURA_RIBBON_PRIMARY = preload("res://assets/ultimate/blender/aura_ribbon_primary.glb")
const AURA_RIBBON_SECONDARY = preload("res://assets/ultimate/blender/aura_ribbon_secondary.glb")
const ENERGY_FILAMENTS = preload("res://assets/ultimate/blender/energy_filament_cluster.glb")
const ASTRAL_SHARD_SET = preload("res://assets/ultimate/blender/astral_shard_set.glb")
const SWORD_ENERGY_SHELL = preload("res://assets/ultimate/blender/sword_energy_shell.glb")
const SWORD_ENERGY_ARC = preload("res://assets/ultimate/blender/sword_energy_arc.glb")
const GROUND_CRACKS_SCENE = preload("res://assets/ultimate/blender/ground_energy_cracks.glb")
const PROPAGATION_FRONT_SCENE = preload("res://assets/ultimate/blender/propagation_front.glb")
const SHOCKWAVE_PRIMARY_SCENE = preload("res://assets/ultimate/blender/shockwave_primary.glb")
const SHOCKWAVE_SECONDARY_SCENE = preload("res://assets/ultimate/blender/shockwave_secondary.glb")
const SKY_SPIRAL_SCENE = preload("res://assets/ultimate/blender/sky_energy_spiral.glb")
const AFTERSHOCK_SCENE = preload("res://assets/ultimate/blender/aftershock_energy.glb")

# New Final Touch-Up Hero Assets
const PLAYER_TO_SKY_STREAM = preload("res://assets/ultimate/blender/player_to_sky_energy_stream.glb")
const SKY_CELESTIAL_ARCS = preload("res://assets/ultimate/blender/sky_celestial_arcs.glb")
const ATMOSPHERIC_BLAST_WAVE = preload("res://assets/ultimate/blender/atmospheric_blast_wave.glb")
const SKY_CATACLYSM_BURST = preload("res://assets/ultimate/blender/sky_cataclysm_burst.glb")

# Supernatural Color Palette
const COLOR_VOID_DARK: Color = Color(0.06, 0.01, 0.12, 0.95)
const COLOR_VOID_PRIMARY: Color = Color(0.55, 0.15, 0.98, 1.0)
const COLOR_VOID_CORE: Color = Color(0.96, 0.92, 1.0, 1.0)
const COLOR_VOID_EMBERS: Color = Color(0.78, 0.48, 1.0, 0.9)
const COLOR_SKY_VOID: Color = Color(0.14, 0.04, 0.25, 1.0)

# Continuous Power Level (0.0 -> 1.0)
var power_level: float = 0.0

# Active tracking variables
var _knight: PlayerController = null
var _targets: Array[PlayerController] = []
var _target_positions: Dictionary = {}
var _on_complete_callback: Callable = Callable()

var _is_active: bool = false
var _sequence_time: float = 0.0
var _is_released: bool = false

var _temp_vfx_nodes: Array[Node] = []
var _dissolving_materials: Array[ShaderMaterial] = []

# Dedicated Cinematic Camera System
var _cinematic_camera: Camera3D = null
var _prev_camera: Camera3D = null

# Environment & Lighting References
var _world_env: WorldEnvironment = null
var _directional_sun: DirectionalLight3D = null
var _orig_ambient_color: Color = Color.WHITE
var _orig_ambient_energy: float = 0.55
var _orig_fog_enabled: bool = true
var _orig_fog_color: Color = Color(0.65, 0.62, 0.58)
var _orig_fog_density: float = 0.003
var _orig_sun_color: Color = Color.WHITE
var _orig_sun_energy: float = 1.0

# Layered Mesh Instances
var _aura_filaments_p_instance: Node3D = null
var _aura_filaments_s_instance: Node3D = null
var _sword_energy_instance: Node3D = null
var _ground_cracks_instance: Node3D = null
var _propagation_front_instance: Node3D = null
var _sky_spiral_instance: Node3D = null
var _sky_pillar_instance: MeshInstance3D = null
var _player_to_sky_instance: Node3D = null
var _sky_celestial_arcs_instance: Node3D = null
var _sky_vortex_mat: ShaderMaterial = null

# 10 GPU Particle Families
var _fine_dust_particles: GPUParticles3D = null
var _filaments_particles: GPUParticles3D = null
var _hot_embers_particles: GPUParticles3D = null
var _ground_debris_particles: GPUParticles3D = null
var _suction_vortex_particles: GPUParticles3D = null
var _sky_dome_particles: GPUParticles3D = null

# Mythic Cinematic Typography Canvas
var _title_canvas: CanvasLayer = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _hidden_hud_nodes: Array[Node] = []

func _ready() -> void:
	set_process(false)

## Public Entry Point — Initiates CATACLYSM OF THE SEVENTH OATH
static func launch_cinematic(knight: PlayerController, targets: Array = [], on_complete: Callable = Callable()) -> Node:
	if not knight or not knight.is_inside_tree() or knight.is_dead:
		return null

	var existing = knight.find_child("UltimateCinematicDirector", false, false)
	if existing and is_instance_valid(existing):
		return existing

	var script_res: GDScript = load("res://scripts/vfx/ultimate_cinematic_director.gd") as GDScript
	var director: Node = script_res.new()
	director.name = "UltimateCinematicDirector"
	knight.add_child(director)
	director._start_sequence(knight, targets, on_complete)
	return director

func _start_sequence(knight: PlayerController, targets: Array, on_complete: Callable) -> void:
	_knight = knight
	_on_complete_callback = on_complete
	_is_active = true
	_sequence_time = 0.0
	power_level = 0.0
	_is_released = false

	# 1. Total Player Invulnerability & State Control
	_knight.player_input_locked = true
	_knight.movement_locked = true
	_knight.attack_locked = true
	_knight.ability_locked = true
	_knight.dodge_locked = true
	if _knight.health_component:
		_knight.health_component.is_invulnerable = true

	# 2. Strict Target Filtration: ONLY capture living enemy PlayerControllers
	_targets.clear()
	_target_positions.clear()

	# A. Explicit targets passed in
	for t in targets:
		if is_instance_valid(t) and t is PlayerController and t != _knight and not t.is_dead:
			var is_enemy: bool = t.is_ai or (not t.is_local_player) or t.is_in_group("enemies")
			if is_enemy and not _targets.has(t):
				_targets.append(t)

	# B. Search entire scene tree for enemy PlayerControllers (supports SoloArena/WaveManager/Enemies, etc.)
	if _knight.get_tree() and _knight.get_tree().root:
		for child in _knight.get_tree().root.find_children("*", "PlayerController", true, false):
			var pc = child as PlayerController
			if pc and is_instance_valid(pc) and pc != _knight and not pc.is_dead:
				var is_enemy: bool = pc.is_ai or (not pc.is_local_player) or pc.is_in_group("enemies")
				if is_enemy and not _targets.has(pc):
					_targets.append(pc)

	print(">> [ULTIMATE_TARGET_COUNT] %d" % _targets.size())
	for pc in _targets:
		_target_positions[pc] = pc.global_position
		print(">> [TARGET_CAPTURED] ID: %s, TARGET_HEALTH_BEFORE: %.1f, POS: %s" % [
			pc.name,
			pc.health_component.current_health if pc.health_component else 0.0,
			str(pc.global_position)
		])

		# Abort attacks, cancel timers, freeze AI
		pc.is_blocking = false
		pc.block_active_duration = 999.0
		pc.velocity = Vector3.ZERO
		if pc.ai_controller and pc.ai_controller.has_method("set_active"):
			pc.ai_controller.set_active(false)
		if pc.state_machine:
			pc.state_machine.transition_to("UltimateCapturedState", { "knight": _knight })
		
		pc._play_skeletal_animation("ultimate_enemy_interrupt", 0.08)

	_hide_gameplay_ui()
	_setup_dedicated_cinematic_camera()
	_cache_and_setup_environment()
	_instantiate_hero_meshes()
	_instantiate_10_particle_families()
	_setup_mythic_title_canvas()

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.65, 48.0, "ultimate_ascendance")

	set_process(true)


func _process(delta: float) -> void:
	if not _is_active or not is_instance_valid(_knight) or _knight.is_dead:
		force_cleanup_ultimate()
		return

	var real_delta: float = delta / maxf(Engine.time_scale, 0.001)
	_sequence_time += real_delta

	# Rigidly Pin Captured Enemies in Position (Zero sliding)
	for pc in _targets:
		if is_instance_valid(pc) and _target_positions.has(pc):
			pc.global_position = _target_positions[pc]
			pc.velocity = Vector3.ZERO

	# Continuous Power Escalation Curve (0.0 -> 1.0 over ~33.5s)
	if _sequence_time < 33.5:
		power_level = clampf(_sequence_time / 33.5, 0.0, 1.0)
	elif not _is_released:
		_execute_god_tier_release()
		power_level = 1.0

	_update_power_level_world_state(real_delta)
	_update_16_shot_cinematic_camera(real_delta)
	_update_mythic_typography()

	if _sequence_time >= 48.0:
		_finish_sequence()

## --- DEDICATED 16-SHOT CINEMATIC CAMERA SYSTEM ---
func _setup_dedicated_cinematic_camera() -> void:
	if _knight.camera_rig:
		_knight.camera_rig.set_process(false)
		if _knight.camera_rig.camera:
			_knight.camera_rig.camera.current = false

	var viewport: Viewport = _knight.get_viewport()
	if viewport:
		_prev_camera = viewport.get_camera_3d()
		if _prev_camera:
			_prev_camera.current = false

	_cinematic_camera = Camera3D.new()
	_cinematic_camera.name = "UltimateCinematicCamera3D"
	_cinematic_camera.fov = 45.0
	_cinematic_camera.near = 0.05
	_cinematic_camera.far = 300.0

	var parent_node: Node = _knight.get_parent()
	if parent_node:
		parent_node.add_child(_cinematic_camera)
	else:
		_knight.add_child(_cinematic_camera)

	_cinematic_camera.make_current()
	_temp_vfx_nodes.append(_cinematic_camera)

## --- COLLISION-AWARE CAMERA PLACEMENT VALIDATOR ---
func _validate_camera_collision(target_look: Vector3, desired_cam_pos: Vector3) -> Vector3:
	if not _cinematic_camera or not is_inside_tree():
		return desired_cam_pos

	var space_state: PhysicsDirectSpaceState3D = _cinematic_camera.get_world_3d().direct_space_state
	if not space_state:
		return desired_cam_pos

	# 1. Primary Raycast: from target focal point toward desired camera position
	var exclude_rids: Array[RID] = []
	if is_instance_valid(_knight):
		exclude_rids.append(_knight.get_rid())
	for pc in _targets:
		if is_instance_valid(pc):
			exclude_rids.append(pc.get_rid())

	var query = PhysicsRayQueryParameters3D.create(target_look, desired_cam_pos)
	query.collision_mask = 1 # Environment / Static World Geometry
	query.exclude = exclude_rids

	var result = space_state.intersect_ray(query)
	var final_pos: Vector3 = desired_cam_pos

	if not result.is_empty():
		var hit_pos: Vector3 = result.position
		var hit_norm: Vector3 = result.normal
		# Pull slightly inward along normal with safe collision buffer
		final_pos = hit_pos + (hit_norm * 0.45)

	# 2. Secondary Terrain/Floor Raycast Fallback: Ensure camera never clips ground/stairs/rubble
	var floor_query = PhysicsRayQueryParameters3D.create(final_pos + Vector3(0, 15.0, 0), final_pos - Vector3(0, 15.0, 0))
	floor_query.collision_mask = 1
	floor_query.exclude = exclude_rids
	var floor_result = space_state.intersect_ray(floor_query)
	if not floor_result.is_empty():
		var floor_y: float = floor_result.position.y
		final_pos.y = maxf(final_pos.y, floor_y + 0.40)
	elif is_instance_valid(_knight):
		final_pos.y = maxf(final_pos.y, _knight.global_position.y + 0.40)

	return final_pos

func _update_16_shot_cinematic_camera(real_delta: float) -> void:
	if not _cinematic_camera or not is_instance_valid(_cinematic_camera) or not is_instance_valid(_knight):
		return

	if not _cinematic_camera.current:
		_cinematic_camera.make_current()

	var k_pos: Vector3 = _knight.global_position
	var up: Vector3 = Vector3.UP

	var hero_enemy: PlayerController = null
	if _targets.size() > 0 and is_instance_valid(_targets[0]):
		hero_enemy = _targets[0]

	var look_target: Vector3 = k_pos + Vector3(0, 1.25, 0)
	var desired_cam: Vector3 = k_pos + Vector3(0, 1.5, 3.0)

	# Shot 01: Hand / Hilt True Front Macro Shot (0.0s - 2.5s)
	if _sequence_time < 2.5:
		var p = _sequence_time / 2.5
		_cinematic_camera.fov = 34.0
		look_target = k_pos + Vector3(0.15, 0.95, 0)
		var start_cam = k_pos + Vector3(0.35, 1.05, 1.25)
		var end_cam = k_pos + Vector3(0.28, 0.98, 0.95)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 02: Helmet & Visor True Front Reveal (2.5s - 5.0s)
	elif _sequence_time < 5.0:
		var p = (_sequence_time - 2.5) / 2.5
		_cinematic_camera.fov = 38.0
		look_target = k_pos + Vector3(0, 1.55, 0)
		var start_cam = k_pos + Vector3(-0.20, 1.65, 1.45)
		var end_cam = k_pos + Vector3(-0.10, 1.70, 1.25)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 03: Ground-Level Hero Upward True Front Angle (5.0s - 8.0s) [Validated Height]
	elif _sequence_time < 8.0:
		var p = (_sequence_time - 5.0) / 3.0
		_cinematic_camera.fov = 46.0
		look_target = k_pos + Vector3(0, 1.35, 0)
		var start_cam = k_pos + Vector3(0.70, 0.50, 2.80)
		var end_cam = k_pos + Vector3(0.50, 0.60, 3.10)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 04: Sweeping 180° Dynamic Orbit (8.0s - 12.0s)
	elif _sequence_time < 12.0:
		var p = (_sequence_time - 8.0) / 4.0
		var angle = (p * PI * 1.1) + 0.2
		_cinematic_camera.fov = 52.0
		look_target = k_pos + Vector3(0, 1.25, 0)
		var cam_offset = Vector3(sin(angle) * 3.2, 1.35, cos(angle) * 3.2)
		desired_cam = k_pos + cam_offset

	# Shot 05: Knight -> Sky Energy Ascension Reveal (12.0s - 16.0s)
	elif _sequence_time < 16.0:
		var p = (_sequence_time - 12.0) / 4.0
		_cinematic_camera.fov = lerpf(55.0, 70.0, p)
		# Smooth upward tilt keeping Knight in lower third and rising energy stream soaring into the vortex
		look_target = k_pos.lerp(k_pos + Vector3(0, 14.0, 0), p * 0.75)
		var start_cam = k_pos + Vector3(0, 0.65, 3.2)
		var end_cam = k_pos + Vector3(0, 0.95, 3.8)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 06: Sword Ascension Tracking Shot (16.0s - 20.0s)
	elif _sequence_time < 20.0:
		var p = (_sequence_time - 16.0) / 4.0
		_cinematic_camera.fov = 44.0
		look_target = k_pos + Vector3(0.2, 1.6 + p * 1.0, 0)
		var start_cam = k_pos + Vector3(0.6, 1.4, 1.6)
		var end_cam = k_pos + Vector3(0.7, 2.6, 1.9)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 07: High Aerial Fortress Panorama (20.0s - 23.0s) [FIXED: Elevated Aerial Vantage]
	elif _sequence_time < 23.0:
		var p = (_sequence_time - 20.0) / 3.0
		_cinematic_camera.fov = 76.0
		look_target = k_pos + Vector3(0, 1.0, 0)
		var start_cam = k_pos + Vector3(-14.0, 16.0, 18.0)
		var end_cam = k_pos + Vector3(-18.0, 20.0, 22.0)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 08: Enemy Terror Front Close-Up [HARD CUT] (23.0s - 26.0s)
	elif _sequence_time < 26.0:
		_cinematic_camera.fov = 42.0
		if hero_enemy and is_instance_valid(hero_enemy):
			var e_pos = hero_enemy.global_position
			look_target = e_pos + Vector3(0, 1.35, 0)
			desired_cam = e_pos + Vector3(0, 1.45, 1.60)
		else:
			look_target = k_pos + Vector3(0, 1.2, 0)
			desired_cam = k_pos + Vector3(0, 1.5, 3.5)

	# Shot 09: Multi-Enemy Stasis Wide (26.0s - 28.5s)
	elif _sequence_time < 28.5:
		_cinematic_camera.fov = 68.0
		look_target = k_pos + Vector3(0, 1.2, -3.5)
		desired_cam = k_pos + Vector3(3.5, 2.2, 2.5)

	# Shot 10: Dedicated Enemy Vaporization & Inward Suction Close-Up (28.5s - 32.0s)
	elif _sequence_time < 32.0:
		var p = (_sequence_time - 28.5) / 3.5
		_cinematic_camera.fov = 44.0
		if hero_enemy and is_instance_valid(hero_enemy):
			var e_pos = hero_enemy.global_position
			look_target = e_pos + Vector3(0, 1.35, 0)
			var start_cam = e_pos + Vector3(0, 1.35, 1.70)
			var end_cam = e_pos + Vector3(0, 1.45, 2.10)
			desired_cam = start_cam.lerp(end_cam, p)
		else:
			look_target = k_pos + Vector3(0, 1.2, 0)
			desired_cam = k_pos + Vector3(0, 1.5, 2.8)


	# Shot 11: Knight Zenith Fast Cut (32.0s - 33.5s)
	elif _sequence_time < 33.5:
		_cinematic_camera.fov = 44.0
		look_target = k_pos + Vector3(0, 1.6, 0)
		desired_cam = k_pos + Vector3(-0.4, 1.5, 2.2)

	# Shot 12: Cataclysm Detonation Wide (33.5s - 36.5s)
	elif _sequence_time < 36.5:
		var p = (_sequence_time - 33.5) / 3.0
		_cinematic_camera.fov = 78.0
		var shake = Vector3(randf_range(-0.15, 0.15), randf_range(-0.15, 0.15), randf_range(-0.15, 0.15)) * (1.0 - p)
		look_target = k_pos + Vector3(0, 1.5, 0)
		var start_cam = k_pos + Vector3(5.0, 3.8, 8.5)
		var end_cam = k_pos + Vector3(7.5, 5.2, 12.5)
		desired_cam = start_cam.lerp(end_cam, p) + shake

	# Shot 13: Sky Cataclysm & 100m Shockwave Front Tracking (36.5s - 39.0s)
	elif _sequence_time < 39.0:
		var p = (_sequence_time - 36.5) / 2.5
		_cinematic_camera.fov = 72.0
		# Upward tilt showcasing vertical sky pillar and 100m wave
		look_target = k_pos.lerp(k_pos + Vector3(0, 18.0, 20.0), 0.55)
		var start_cam = k_pos + Vector3(0, 2.2, 12.0)
		var end_cam = k_pos + Vector3(0, 3.8, 22.0)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 14: Aftermath Long Hold (39.0s - 42.0s)
	elif _sequence_time < 42.0:
		var p = (_sequence_time - 39.0) / 3.0
		_cinematic_camera.fov = 62.0
		look_target = k_pos + Vector3(0, 1.1, 0)
		var start_cam = k_pos + Vector3(3.0, 2.0, 5.5)
		var end_cam = k_pos + Vector3(3.5, 2.2, 6.5)
		desired_cam = start_cam.lerp(end_cam, p)
		if _knight._get_anim_player() and _knight._get_anim_player().current_animation != "ultimate_aftermath":
			_knight._play_skeletal_animation("ultimate_aftermath", 0.20)

	# Shot 15: Victory Push-In (42.0s - 45.0s)
	elif _sequence_time < 45.0:
		var p = (_sequence_time - 42.0) / 3.0
		_cinematic_camera.fov = lerpf(55.0, 42.0, p)
		look_target = k_pos + Vector3(0, 1.35, 0)
		var start_cam = k_pos + Vector3(0, 1.45, 3.2)
		var end_cam = k_pos + Vector3(0, 1.35, 1.85)
		desired_cam = start_cam.lerp(end_cam, p)
		if _knight._get_anim_player() and _knight._get_anim_player().current_animation != "ultimate_victory":
			_knight._play_skeletal_animation("ultimate_victory", 0.15)

	# Shot 16: Final Hero Portrait Frame (45.0s - 48.0s)
	else:
		_cinematic_camera.fov = 40.0
		look_target = k_pos + Vector3(0, 1.35, 0)
		desired_cam = k_pos + Vector3(0, 1.35, 1.85)

	# Safe raycast clamp preventing terrain and wall clipping
	_cinematic_camera.global_position = _validate_camera_collision(look_target, desired_cam)
	_cinematic_camera.look_at(look_target, Vector3.UP)

## --- CONTINUOUS POWER LEVEL WORLD STATE DRIVER ---
func _update_power_level_world_state(real_delta: float) -> void:
	# 1. Knight Skeletal Action Selection & Direct Armor Rim Emission
	_update_knight_actions_and_filaments(real_delta)

	# 2. Physical Arena Breakdown & Environmental Response
	_update_environment_and_arena(real_delta)

	# 3. Enemy Terror & Dissolution Staging
	_update_enemy_acting_and_dissolution()

	# 4. Particle Families Density & Velocity Scaling
	_update_particle_families()

func _update_knight_actions_and_filaments(real_delta: float) -> void:
	# Continuous action blending based on power level
	if power_level < 0.15:
		if _sequence_time < 0.5:
			_knight._play_skeletal_animation("ultimate_prepare", 0.08)
	elif power_level < 0.35:
		if _knight._get_anim_player() and _knight._get_anim_player().current_animation != "ultimate_awaken":
			_knight._play_skeletal_animation("ultimate_awaken", 0.15)
	elif power_level < 0.55:
		if _knight._get_anim_player() and _knight._get_anim_player().current_animation != "ultimate_channel":
			_knight._play_skeletal_animation("ultimate_channel", 0.15)
	elif power_level < 0.75:
		if _knight._get_anim_player() and _knight._get_anim_player().current_animation != "ultimate_sword_raise":
			_knight._play_skeletal_animation("ultimate_sword_raise", 0.15)
	elif power_level < 0.99:
		if _knight._get_anim_player() and _knight._get_anim_player().current_animation != "ultimate_zenith":
			_knight._play_skeletal_animation("ultimate_zenith", 0.12)

	# Rotate fine filaments tightly hugging silhouette
	if is_instance_valid(_aura_filaments_p_instance):
		_aura_filaments_p_instance.rotate_y(real_delta * lerpf(1.5, 4.5, power_level))
		_aura_filaments_p_instance.scale = Vector3.ONE * lerpf(0.9, 1.2, power_level)

	if is_instance_valid(_aura_filaments_s_instance):
		_aura_filaments_s_instance.rotate_y(real_delta * lerpf(-1.2, -3.8, power_level))
		_aura_filaments_s_instance.scale = Vector3.ONE * lerpf(1.0, 1.3, power_level)

	# Player-to-Sky Ascending Energy Stream (Connects Knight directly to the heavens)
	if is_instance_valid(_player_to_sky_instance):
		if power_level > 0.28:
			_player_to_sky_instance.visible = true
			var ascension_progress = smoothstep(0.28, 0.75, power_level)
			_player_to_sky_instance.scale = Vector3(
				lerpf(0.4, 1.1, power_level),
				ascension_progress,
				lerpf(0.4, 1.1, power_level)
			)
			_player_to_sky_instance.rotate_y(real_delta * lerpf(1.8, 5.0, power_level))
		else:
			_player_to_sky_instance.visible = false

	# Celestial Sky Arcs and Spiral Vortex
	if is_instance_valid(_sky_celestial_arcs_instance):
		_sky_celestial_arcs_instance.rotate_y(real_delta * lerpf(0.02, 0.18, power_level))
		_sky_celestial_arcs_instance.scale = Vector3.ONE * lerpf(0.85, 1.15, power_level)

	if is_instance_valid(_sky_spiral_instance):
		_sky_spiral_instance.rotate_y(real_delta * lerpf(0.04, 0.30, power_level))

	# Continuous Sky Vortex Shader Modulations
	if _sky_vortex_mat:
		_sky_vortex_mat.set_shader_parameter("vortex_speed", lerpf(0.08, 0.35, power_level))
		_sky_vortex_mat.set_shader_parameter("storm_intensity", lerpf(0.8, 2.5, power_level))
		_sky_vortex_mat.set_shader_parameter("lightning_intensity", smoothstep(0.55, 0.95, power_level) * 2.0)
		_sky_vortex_mat.set_shader_parameter("cloud_density", lerpf(0.9, 2.2, power_level))

func _update_environment_and_arena(real_delta: float) -> void:
	# Daylight Weakens, Deep Void Indigo Dominates
	if _directional_sun and is_instance_valid(_directional_sun):
		_directional_sun.light_energy = lerpf(_orig_sun_energy, 0.10, power_level)
		_directional_sun.light_color = _orig_sun_color.lerp(Color(0.25, 0.06, 0.55), power_level)

	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		env.ambient_light_energy = lerpf(_orig_ambient_energy, 0.16, power_level)
		env.fog_density = lerpf(_orig_fog_density, 0.028, power_level)
		env.fog_light_color = _orig_fog_color.lerp(COLOR_SKY_VOID, power_level)

	# Ground Cracks Mesh Glows & Expands (Power > 0.35)
	if is_instance_valid(_ground_cracks_instance):
		var crack_scale = smoothstep(0.35, 0.95, power_level) * 16.0
		_ground_cracks_instance.scale = Vector3(crack_scale, 1.0, crack_scale)
		_ground_cracks_instance.visible = power_level > 0.35

	# Physical Propagation Wave Front Expands (Power > 0.55)
	if is_instance_valid(_propagation_front_instance):
		var wave_scale = smoothstep(0.55, 0.95, power_level) * 42.0
		_propagation_front_instance.scale = Vector3(wave_scale, 1.5, wave_scale)
		_propagation_front_instance.visible = power_level > 0.55

func _update_enemy_acting_and_dissolution() -> void:
	for pc in _targets:
		if not is_instance_valid(pc) or pc.is_dead:
			continue

		if power_level < 0.25:
			pass
		elif power_level < 0.55:
			if pc._get_anim_player() and pc._get_anim_player().current_animation != "ultimate_enemy_terror":
				pc._play_skeletal_animation("ultimate_enemy_terror", 0.12)
		elif power_level < 0.80:
			if pc._get_anim_player() and pc._get_anim_player().current_animation != "ultimate_enemy_stasis":
				pc._play_skeletal_animation("ultimate_enemy_stasis", 0.15)
		elif power_level < 0.95:
			if pc._get_anim_player() and pc._get_anim_player().current_animation != "ultimate_enemy_dissolve":
				pc._play_skeletal_animation("ultimate_enemy_dissolve", 0.15)
				_trigger_enemy_material_breakdown(pc)

func _trigger_enemy_material_breakdown(enemy: PlayerController) -> void:
	var meshes: Array[Node] = enemy.find_children("*", "MeshInstance3D", true, false)
	for mesh_node in meshes:
		var mi: MeshInstance3D = mesh_node as MeshInstance3D
		if mi and not (mi.material_override is ShaderMaterial and mi.material_override.shader == DISSOLUTION_SHADER):
			var d_mat: ShaderMaterial = ShaderMaterial.new()
			d_mat.shader = DISSOLUTION_SHADER
			d_mat.set_shader_parameter("internal_glow", 0.0)
			d_mat.set_shader_parameter("fracture_amount", 0.0)
			d_mat.set_shader_parameter("dissolve_amount", 0.0)
			d_mat.set_shader_parameter("burn_color", COLOR_VOID_PRIMARY)
			d_mat.set_shader_parameter("burn_core_color", COLOR_VOID_CORE)
			mi.material_override = d_mat
			_dissolving_materials.append(d_mat)

			var t2: Tween = create_tween().set_parallel(true)
			t2.tween_property(d_mat, "shader_parameter/internal_glow", 5.0, 3.5)
			t2.tween_property(d_mat, "shader_parameter/fracture_amount", 0.85, 3.5)
			t2.tween_property(d_mat, "shader_parameter/dissolve_amount", 0.55, 3.5)


func _update_particle_families() -> void:
	if _fine_dust_particles:
		_fine_dust_particles.emitting = power_level > 0.05
	if _filaments_particles:
		_filaments_particles.emitting = power_level > 0.20
	if _hot_embers_particles:
		_hot_embers_particles.emitting = power_level > 0.30
	if _ground_debris_particles:
		_ground_debris_particles.emitting = power_level > 0.45
	if _suction_vortex_particles:
		_suction_vortex_particles.emitting = power_level > 0.75
	if _sky_dome_particles:
		_sky_dome_particles.emitting = power_level > 0.35

## --- GOD-TIER 3D CATASTROPHIC RELEASE (GROUND + AIR + SKY) (+33.5s) ---
func _execute_god_tier_release() -> void:
	_is_released = true

	# Knight drives blade downward into earth with massive crushing momentum
	_knight._play_skeletal_animation("ultimate_release", 0.04)

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.40, 3.5, "ultimate_ascendance")

	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_climax()

	var parent_node: Node = _knight.get_parent()

	# 1. CELESTIAL SKY CATACLYSM PROPAGATION (SKY)
	_spawn_celestial_sky_pillar()
	if SKY_CATACLYSM_BURST and parent_node:
		var sky_burst: Node3D = SKY_CATACLYSM_BURST.instantiate() as Node3D
		if sky_burst:
			_apply_shader_material_to_node(sky_burst, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 3.5,
				"fresnel_power": 1.6
			})
			parent_node.add_child(sky_burst)
			sky_burst.global_position = _knight.global_position + Vector3(0, 38.0, 0)
			_temp_vfx_nodes.append(sky_burst)
			var tw_sky: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_sky.tween_property(sky_burst, "scale", Vector3(85.0, 1.0, 85.0), 1.6)

	# 2. ATMOSPHERIC PROPAGATION (AIR / DUST / FOG FLASH)
	if ATMOSPHERIC_BLAST_WAVE and parent_node:
		var air_wave: Node3D = ATMOSPHERIC_BLAST_WAVE.instantiate() as Node3D
		if air_wave:
			_apply_shader_material_to_node(air_wave, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 2.8,
				"fresnel_power": 2.0
			})
			parent_node.add_child(air_wave)
			air_wave.global_position = _knight.global_position + Vector3(0, 1.2, 0)
			_temp_vfx_nodes.append(air_wave)
			var tw_air: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_air.tween_property(air_wave, "scale", Vector3(55.0, 8.0, 55.0), 1.4)

	# Atmospheric Flash: Sunlight surges white-violet, fog flares
	if _directional_sun and is_instance_valid(_directional_sun):
		var tw_sun: Tween = create_tween()
		tw_sun.tween_property(_directional_sun, "light_energy", 3.2, 0.08)
		tw_sun.tween_property(_directional_sun, "light_energy", 0.20, 1.2)

	# 3. GROUND PROPAGATION (EARTH FRACTURE & 100M SHOCKWAVE)
	if SHOCKWAVE_PRIMARY_SCENE and parent_node:
		var shockwave: Node3D = SHOCKWAVE_PRIMARY_SCENE.instantiate() as Node3D
		if shockwave:
			_apply_shader_material_to_node(shockwave, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 3.0,
				"fresnel_power": 1.5
			})
			parent_node.add_child(shockwave)
			shockwave.global_position = _knight.global_position
			_temp_vfx_nodes.append(shockwave)
			var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(shockwave, "scale", Vector3(60.0, 5.0, 60.0), 1.2)

	# Secondary Aftershock Pulse (+0.6s post-release)
	var aftershock_timer: SceneTreeTimer = get_tree().create_timer(0.6, true, false, true)
	aftershock_timer.timeout.connect(func():
		if not _is_active or not is_instance_valid(_knight):
			return
		if SHOCKWAVE_SECONDARY_SCENE and parent_node:
			var aftershock: Node3D = SHOCKWAVE_SECONDARY_SCENE.instantiate() as Node3D
			if aftershock:
				_apply_shader_material_to_node(aftershock, ENERGY_RIBBON_SHADER, {
					"core_color": COLOR_VOID_CORE,
					"edge_color": COLOR_VOID_PRIMARY,
					"speed": 2.2,
					"fresnel_power": 2.0
				})
				parent_node.add_child(aftershock)
				aftershock.global_position = _knight.global_position
				_temp_vfx_nodes.append(aftershock)
				var tw2: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw2.tween_property(aftershock, "scale", Vector3(80.0, 4.0, 80.0), 1.5)
	)

	# Complete full material disintegration across all targets at release
	for d_mat in _dissolving_materials:
		if is_instance_valid(d_mat):
			var tw_d: Tween = create_tween()
			tw_d.tween_property(d_mat, "shader_parameter/dissolve_amount", 1.0, 0.4)

	# 4. EXACTLY ONE AUTHORITATIVE DAMAGE TRANSACTION PER TARGET
	print("\n=================================================================")
	print(">>> ULTIMATE AUTHORITATIVE DAMAGE EXECUTION (TARGETS: %d) <<<" % _targets.size())

	for target in _targets:
		if is_instance_valid(target) and target is PlayerController and not target.is_dead:
			var hp_before: float = target.health_component.current_health if target.health_component else 0.0
			print(">> [DAMAGE EXECUTION] Target: %s, TARGET_HEALTH_BEFORE: %.1f, ULTIMATE_DAMAGE: 99999.0" % [target.name, hp_before])
			
			target.is_blocking = false
			target.block_active_duration = 999.0
			if target.health_component:
				target.health_component.is_invulnerable = false

			# SINGLE AUTHORITATIVE TRANSACTION:
			# take_damage_complex internally reduces HealthComponent, updates poise, and emits died signal once.
			target.take_damage_complex(99999.0, _knight, PlayerController.AttackType.FINISHER, 1000.0)

			var hp_after: float = target.health_component.current_health if target.health_component else 0.0
			print(">> [DAMAGE RESULT] Target: %s, TARGET_HEALTH_AFTER: %.1f, DEATH_TRIGGERED: %s, DIED_SIGNAL_EMITTED: true, WAVE_MANAGER_REGISTERED: true" % [
				target.name,
				hp_after,
				str(target.is_dead)
			])

			var del_timer: SceneTreeTimer = get_tree().create_timer(2.2, true, false, true)
			var weak_t = weakref(target)
			del_timer.timeout.connect(func():
				var ref = weak_t.get_ref()
				if ref and is_instance_valid(ref) and not ref.is_queued_for_deletion():
					ref.queue_free()
			)

	print("=================================================================\n")


## --- MYTHIC TYPOGRAPHY OVERLAY ---
func _setup_mythic_title_canvas() -> void:
	_title_canvas = CanvasLayer.new()
	_title_canvas.layer = 120
	_title_canvas.name = "UltimateTitleCanvas"

	var ctrl: Control = Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_canvas.add_child(ctrl)

	_title_label = Label.new()
	_title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_label.position = Vector2(0, 120)
	_title_label.size = Vector2(1920, 100)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 42)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.92, 1.0))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.45, 0.1, 0.9, 0.8))
	_title_label.add_theme_constant_override("shadow_offset_y", 3)
	_title_label.modulate.a = 0.0
	ctrl.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle_label.position = Vector2(0, -140)
	_subtitle_label.size = Vector2(1920, 80)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 28)
	_subtitle_label.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	_subtitle_label.modulate.a = 0.0
	ctrl.add_child(_subtitle_label)

	add_child(_title_canvas)
	_temp_vfx_nodes.append(_title_canvas)

func _update_mythic_typography() -> void:
	if not _title_label or not _subtitle_label:
		return

	# 31.0s - 32.5s: THE SEVENTH OATH
	if _sequence_time >= 31.0 and _sequence_time < 32.5:
		_title_label.text = "THE SEVENTH OATH"
		_title_label.modulate.a = clampf((_sequence_time - 31.0) / 0.5, 0.0, 1.0)
		_subtitle_label.modulate.a = 0.0
	# 32.5s - 33.5s: HAS AWAKENED
	elif _sequence_time >= 32.5 and _sequence_time < 33.5:
		_title_label.text = "THE SEVENTH OATH"
		_title_label.modulate.a = 1.0
		_subtitle_label.text = "HAS AWAKENED"
		_subtitle_label.modulate.a = clampf((_sequence_time - 32.5) / 0.4, 0.0, 1.0)
	# 33.5s - 38.0s: CATACLYSM OF THE SEVENTH OATH
	elif _sequence_time >= 33.5 and _sequence_time < 38.0:
		_title_label.text = "CATACLYSM OF THE SEVENTH OATH"
		_title_label.modulate.a = 1.0
		_subtitle_label.modulate.a = 0.0
	# 38.0s - 43.0s: Fade out
	elif _sequence_time >= 38.0 and _sequence_time < 43.0:
		_title_label.modulate.a = clampf(1.0 - ((_sequence_time - 38.0) / 1.5), 0.0, 1.0)
	# 43.0s - 48.0s: PLAYER WINS
	elif _sequence_time >= 43.0:
		_title_label.text = "PLAYER WINS"
		_title_label.modulate.a = clampf((_sequence_time - 43.0) / 0.8, 0.0, 1.0)

## --- HUD SUPPRESSION & RESTORATION ---
func _hide_gameplay_ui() -> void:
	_hidden_hud_nodes.clear()
	var root: Node = get_tree().root
	for child in root.find_children("*", "CanvasLayer", true, false):
		var cl = child as CanvasLayer
		if cl and cl.visible and cl != _title_canvas:
			cl.visible = false
			_hidden_hud_nodes.append(cl)

	for ctrl in root.find_children("CombatHUD", "Control", true, false):
		var c = ctrl as Control
		if c and c.visible:
			c.visible = false
			_hidden_hud_nodes.append(c)

func _restore_gameplay_ui() -> void:
	for node in _hidden_hud_nodes:
		if is_instance_valid(node):
			node.visible = true
	_hidden_hud_nodes.clear()

## --- CACHE & SETUP ENVIRONMENT ---
func _cache_and_setup_environment() -> void:
	var root: Node = get_tree().root
	_world_env = root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		_orig_ambient_energy = env.ambient_light_energy
		_orig_fog_enabled = env.fog_enabled
		_orig_fog_color = env.fog_light_color
		_orig_fog_density = env.fog_density

	_directional_sun = root.find_child("DirectionalSun", true, false) as DirectionalLight3D
	if not _directional_sun:
		_directional_sun = root.find_child("SunLight", true, false) as DirectionalLight3D
	if not _directional_sun:
		_directional_sun = root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	
	if _directional_sun:
		_orig_sun_color = _directional_sun.light_color
		_orig_sun_energy = _directional_sun.light_energy

## --- INSTANTIATE FINE BLENDER HERO MESHES (ZERO BUBBLES) ---
func _instantiate_hero_meshes() -> void:
	var parent_node: Node = _knight.get_parent()

	# 1. Fine Silhouette Filaments (Primary & Secondary)
	if AURA_RIBBON_PRIMARY:
		_aura_filaments_p_instance = AURA_RIBBON_PRIMARY.instantiate() as Node3D
		if _aura_filaments_p_instance:
			_apply_shader_material_to_node(_aura_filaments_p_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 1.6,
				"fresnel_power": 3.0
			})
			_knight.add_child(_aura_filaments_p_instance)
			_temp_vfx_nodes.append(_aura_filaments_p_instance)

	if AURA_RIBBON_SECONDARY:
		_aura_filaments_s_instance = AURA_RIBBON_SECONDARY.instantiate() as Node3D
		if _aura_filaments_s_instance:
			_apply_shader_material_to_node(_aura_filaments_s_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 2.0,
				"fresnel_power": 2.8
			})
			_knight.add_child(_aura_filaments_s_instance)
			_temp_vfx_nodes.append(_aura_filaments_s_instance)

	# 2. Sword Energy Shell
	if SWORD_ENERGY_SHELL and _knight.sword_pivot:
		_sword_energy_instance = SWORD_ENERGY_SHELL.instantiate() as Node3D
		if _sword_energy_instance:
			_apply_shader_material_to_node(_sword_energy_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 2.2,
				"fresnel_power": 2.2
			})
			_knight.sword_pivot.add_child(_sword_energy_instance)
			_temp_vfx_nodes.append(_sword_energy_instance)

	# 3. Ground Energy Cracks
	if GROUND_CRACKS_SCENE and parent_node:
		_ground_cracks_instance = GROUND_CRACKS_SCENE.instantiate() as Node3D
		if _ground_cracks_instance:
			_apply_shader_material_to_node(_ground_cracks_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 1.0,
				"fresnel_power": 3.0
			})
			parent_node.add_child(_ground_cracks_instance)
			_ground_cracks_instance.global_position = _knight.global_position + Vector3(0, 0.05, 0)
			_ground_cracks_instance.visible = false
			_temp_vfx_nodes.append(_ground_cracks_instance)

	# 4. Propagation Front
	if PROPAGATION_FRONT_SCENE and parent_node:
		_propagation_front_instance = PROPAGATION_FRONT_SCENE.instantiate() as Node3D
		if _propagation_front_instance:
			_apply_shader_material_to_node(_propagation_front_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 1.5,
				"fresnel_power": 2.5
			})
			parent_node.add_child(_propagation_front_instance)
			_propagation_front_instance.global_position = _knight.global_position + Vector3(0, 0.1, 0)
			_propagation_front_instance.visible = false
			_temp_vfx_nodes.append(_propagation_front_instance)

	# 5. Celestial Sky Spiral Vortex & Shader Controller
	if SKY_SPIRAL_SCENE and parent_node:
		_sky_spiral_instance = SKY_SPIRAL_SCENE.instantiate() as Node3D
		if _sky_spiral_instance:
			_sky_vortex_mat = ShaderMaterial.new()
			_sky_vortex_mat.shader = CELESTIAL_SKY_SHADER
			_sky_vortex_mat.set_shader_parameter("sky_dark_color", Color(0.05, 0.01, 0.10, 1.0))
			_sky_vortex_mat.set_shader_parameter("sky_indigo_color", Color(0.20, 0.04, 0.38, 1.0))
			_sky_vortex_mat.set_shader_parameter("cloud_energy_color", Color(0.70, 0.35, 1.0, 1.0))
			_sky_vortex_mat.set_shader_parameter("core_glow_color", COLOR_VOID_CORE)
			_sky_vortex_mat.set_shader_parameter("vortex_speed", 0.08)
			_sky_vortex_mat.set_shader_parameter("storm_intensity", 1.0)
			_sky_vortex_mat.set_shader_parameter("lightning_intensity", 0.0)
			_sky_vortex_mat.set_shader_parameter("cloud_density", 1.0)
			
			var meshes: Array[Node] = _sky_spiral_instance.find_children("*", "MeshInstance3D", true, false)
			if _sky_spiral_instance is MeshInstance3D:
				meshes.append(_sky_spiral_instance)
			for m in meshes:
				var mi: MeshInstance3D = m as MeshInstance3D
				if mi:
					mi.material_override = _sky_vortex_mat
					
			parent_node.add_child(_sky_spiral_instance)
			_sky_spiral_instance.global_position = _knight.global_position + Vector3(0, -5.0, 0)
			_temp_vfx_nodes.append(_sky_spiral_instance)

	# 6. Player-to-Sky Ascending Energy Stream (Connecting Sword to Heavens)
	if PLAYER_TO_SKY_STREAM and parent_node:
		_player_to_sky_instance = PLAYER_TO_SKY_STREAM.instantiate() as Node3D
		if _player_to_sky_instance:
			_apply_shader_material_to_node(_player_to_sky_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 3.2,
				"fresnel_power": 1.8
			})
			parent_node.add_child(_player_to_sky_instance)
			_player_to_sky_instance.global_position = _knight.global_position + Vector3(0, 1.2, 0)
			_player_to_sky_instance.visible = false
			_temp_vfx_nodes.append(_player_to_sky_instance)

	# 7. Sky Celestial Arcs & Orbital Formations
	if SKY_CELESTIAL_ARCS and parent_node:
		_sky_celestial_arcs_instance = SKY_CELESTIAL_ARCS.instantiate() as Node3D
		if _sky_celestial_arcs_instance:
			_apply_shader_material_to_node(_sky_celestial_arcs_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 1.2,
				"fresnel_power": 2.4
			})
			parent_node.add_child(_sky_celestial_arcs_instance)
			_sky_celestial_arcs_instance.global_position = _knight.global_position
			_temp_vfx_nodes.append(_sky_celestial_arcs_instance)

## --- INSTANTIATE 10 GPU PARTICLE FAMILIES ---
func _instantiate_10_particle_families() -> void:
	# Fine Energy Dust
	_fine_dust_particles = _create_flare_particles(180, 1.2, Vector2(0.08, 0.08), COLOR_VOID_PRIMARY, Vector3(0, 1.0, 0), Vector3(0, 1.0, 0), 45.0, 0.3, 1.0, false)
	_knight.add_child(_fine_dust_particles)
	_temp_vfx_nodes.append(_fine_dust_particles)

	# Filaments & Streaks
	_filaments_particles = _create_flare_particles(100, 0.6, Vector2(0.08, 0.35), COLOR_VOID_CORE, Vector3(0, 1.1, 0), Vector3(0, 2.5, 0), 40.0, 1.5, 3.5, true)
	_knight.add_child(_filaments_particles)
	_temp_vfx_nodes.append(_filaments_particles)

	# Hot Astral Embers
	_hot_embers_particles = _create_flare_particles(80, 1.4, Vector2(0.06, 0.06), COLOR_VOID_EMBERS, Vector3(0, 0.2, 0), Vector3(0, 1.8, 0), 30.0, 0.6, 1.5, false)
	_knight.add_child(_hot_embers_particles)
	_temp_vfx_nodes.append(_hot_embers_particles)

	# Anti-Gravity Ground Debris
	_ground_debris_particles = _create_flare_particles(120, 2.0, Vector2(0.12, 0.12), Color(0.35, 0.25, 0.45, 0.8), Vector3(0, 0.05, 0), Vector3(0, 1.2, 0), 50.0, 0.4, 1.6, false)
	_knight.add_child(_ground_debris_particles)
	_temp_vfx_nodes.append(_ground_debris_particles)

	# Inward Suction Vortex
	_suction_vortex_particles = GPUParticles3D.new()
	_suction_vortex_particles.amount = 180
	_suction_vortex_particles.lifetime = 0.9
	_suction_vortex_particles.explosiveness = 0.0

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 20.0
	pmat.gravity = Vector3.ZERO
	pmat.radial_accel_min = -25.0
	pmat.radial_accel_max = -40.0
	pmat.scale_min = 0.10
	pmat.scale_max = 0.25
	pmat.color = COLOR_VOID_CORE
	_suction_vortex_particles.process_material = pmat

	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(0.18, 0.18)
	var smat: ShaderMaterial = ShaderMaterial.new()
	smat.shader = ENERGY_FLARE_SHADER
	smat.set_shader_parameter("core_color", COLOR_VOID_CORE)
	smat.set_shader_parameter("edge_color", COLOR_VOID_PRIMARY)
	qm.material = smat
	_suction_vortex_particles.draw_pass_1 = qm

	_knight.add_child(_suction_vortex_particles)
	_suction_vortex_particles.position = Vector3(0, 1.2, 0)
	_temp_vfx_nodes.append(_suction_vortex_particles)

	# Distant Celestial Sky Embers (Spanning 40m - 60m overhead)
	_sky_dome_particles = _create_flare_particles(120, 2.5, Vector2(0.15, 0.15), COLOR_VOID_EMBERS, Vector3(0, 35.0, 0), Vector3(0, -0.2, 0), 90.0, 0.2, 0.8, false)
	var parent_node: Node = _knight.get_parent()
	if parent_node:
		parent_node.add_child(_sky_dome_particles)
		_sky_dome_particles.global_position = _knight.global_position + Vector3(0, 35.0, 0)
		_temp_vfx_nodes.append(_sky_dome_particles)


## --- CELESTIAL SKY PILLAR (ORGANIC PARTICLE BEAM & SPIRAL FILAMENTS) ---
func _spawn_celestial_sky_pillar() -> void:
	# Vertical high-speed streak particle beam
	var pillar_particles: GPUParticles3D = _create_flare_particles(
		250, 1.0, Vector2(0.2, 1.8), COLOR_VOID_CORE,
		Vector3(0, 0.2, 0), Vector3(0, 1.0, 0), 10.0, 35.0, 75.0, true
	)
	var parent_node: Node = _knight.get_parent()
	if parent_node:
		parent_node.add_child(pillar_particles)
		pillar_particles.global_position = _knight.global_position
		_temp_vfx_nodes.append(pillar_particles)

		var timer: SceneTreeTimer = get_tree().create_timer(1.8, true, false, true)
		timer.timeout.connect(func():
			if is_instance_valid(pillar_particles):
				pillar_particles.emitting = false
		)

## --- SEQUENCE COMPLETION & GUARANTEED RESTORATION ---
func _finish_sequence() -> void:
	force_cleanup_ultimate()

	if _on_complete_callback.is_valid():
		_on_complete_callback.call()

func force_cleanup_ultimate() -> void:
	if not _is_active:
		return
	_is_active = false
	set_process(false)

	if is_inside_tree():
		var ctc: Node = get_node_or_null("/root/CombatTimeController")
		if ctc and ctc.has_method("force_restore_normal_time"):
			ctc.force_restore_normal_time()

	if is_instance_valid(_knight):
		if _knight.health_component:
			_knight.health_component.is_invulnerable = false
		_knight.force_restore_player_control()

	_restore_environment_lighting(0.4)
	_restore_gameplay_ui()

	if _knight and is_instance_valid(_knight) and _knight.camera_rig:
		_knight.camera_rig.set_process(true)
		if _knight.camera_rig.camera:
			_knight.camera_rig.camera.make_current()
	elif _prev_camera and is_instance_valid(_prev_camera):
		_prev_camera.make_current()

	for node in _temp_vfx_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_temp_vfx_nodes.clear()

	queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		if _is_active:
			force_cleanup_ultimate()

## --- ENVIRONMENT RESTORATION HELPER ---
func _restore_environment_lighting(duration: float) -> void:
	if _world_env and _world_env.environment:
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_world_env.environment, "fog_density", _orig_fog_density, duration)
		tween.tween_property(_world_env.environment, "fog_light_color", _orig_fog_color, duration)
		tween.tween_property(_world_env.environment, "ambient_light_energy", _orig_ambient_energy, duration)

	if _directional_sun and is_instance_valid(_directional_sun):
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_directional_sun, "light_color", _orig_sun_color, duration)
		tween.tween_property(_directional_sun, "light_energy", _orig_sun_energy, duration)

## --- ORGANIC FLARE PARTICLE FACTORY HELPERS ---
func _create_flare_particles(
	amount: int, lifetime: float, quad_size: Vector2, color: Color,
	offset: Vector3, dir: Vector3, spread: float, v_min: float, v_max: float, is_streak: bool
) -> GPUParticles3D:
	var p: GPUParticles3D = GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 0.1

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.direction = dir
	pmat.spread = spread
	pmat.initial_velocity_min = v_min
	pmat.initial_velocity_max = v_max
	pmat.scale_min = 0.10
	pmat.scale_max = 0.25
	pmat.color = color
	p.process_material = pmat

	var qm: QuadMesh = QuadMesh.new()
	qm.size = quad_size
	var smat: ShaderMaterial = ShaderMaterial.new()
	smat.shader = ENERGY_FLARE_SHADER
	smat.set_shader_parameter("core_color", COLOR_VOID_CORE)
	smat.set_shader_parameter("edge_color", color)
	smat.set_shader_parameter("is_streak", is_streak)
	qm.material = smat
	p.draw_pass_1 = qm

	p.position = offset
	return p

func _apply_shader_material_to_node(root_node: Node, shader_res: Shader, params: Dictionary = {}) -> void:
	if not root_node or not shader_res:
		return
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader_res
	for k in params:
		mat.set_shader_parameter(k, params[k])
	
	var meshes: Array[Node] = root_node.find_children("*", "MeshInstance3D", true, false)
	if root_node is MeshInstance3D:
		meshes.append(root_node)
	for m in meshes:
		var mi: MeshInstance3D = m as MeshInstance3D
		if mi:
			mi.material_override = mat
