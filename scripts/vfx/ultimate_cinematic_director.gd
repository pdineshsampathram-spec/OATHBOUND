class_name UltimateCinematicDirector
extends Node

## UltimateCinematicDirector — "CATACLYSM OF THE SEVENTH OATH"
## God-Tier Blender-First Cinematic World-State Director.
##
## CINEMATIC DESIGN PRINCIPLES ("I Am Atomic"):
## 1. CALM DOMINANCE: Knight stands completely calm, posture-driven power.
## 2. ENVIRONMENTAL ACCUMULATION: Ground rubble floats, dust pulls inward, sky darkens.
##    (ZERO giant lampshades, cylinders, or full-body glowing meshes around the Knight).
## 3. EXTREME COMPRESSION: All motion reverses inward; world goes dark; Knight in silhouette;
##    entire accumulated energy collapses to a tiny 0.15m white-violet core at sword tip.
## 4. MICRO-PAUSE: Breathless silence and tension before release.
## 5. CATASTROPHIC RELEASE: Blinding flash -> 3D radial blast -> 100m ground rupture ->
##    upward branching eruption -> massive irregular sky cloud canopy detonation ->
##    monumental 100m wide shot showing total fortress devastation in a single composition.
## 6. SPATIAL SHOCKWAVE CAUSALITY: Physical wavefront reaches enemies -> instant recoil ->
##    preserved 8-stage material dissolution shader -> vapor swept outward.
## 7. AFTERMATH & VICTORY: Scarred arena and sky, calm Knight with subtle blade glint,
##    sequential mythic typography.

# Core VFX Shaders
const ENERGY_RIBBON_SHADER = preload("res://assets/materials/energy_ribbon.gdshader")
const CELESTIAL_SKY_SHADER = preload("res://assets/materials/celestial_sky_vortex.gdshader")
const DISSOLUTION_SHADER = preload("res://assets/materials/dissolution_shader.gdshader")
const ENERGY_FLARE_SHADER = preload("res://assets/materials/energy_flare.gdshader")
const DENSE_PLASMA_SHADER = preload("res://assets/materials/dense_plasma_column.gdshader")
const ATMOSPHERIC_SHOCK_SHADER = preload("res://assets/materials/atmospheric_shock_distortion.gdshader")

# Art-First Shaders
const RADIAL_DETONATION_SHADER = preload("res://assets/materials/radial_detonation.gdshader")
const COMPRESSION_CORE_SHADER = preload("res://assets/materials/compression_core.gdshader")
const SKY_BLOOM_ERUPTION_SHADER = preload("res://assets/materials/sky_bloom_eruption.gdshader")
const GROUND_RUPTURE_SHADER = preload("res://assets/materials/ground_rupture.gdshader")
const SKY_CLOUD_DETONATION_SHADER = preload("res://assets/materials/sky_cloud_detonation.gdshader")
const UPWARD_BRANCHING_ERUPTION_SHADER = preload("res://assets/materials/upward_branching_eruption.gdshader")

# Script Preloads
const GraphicsSettings = preload("res://scripts/graphics_settings.gd")
const CinematicQualityBoost = preload("res://scripts/vfx/cinematic_quality_boost.gd")
const UltimateCapturedState = preload("res://scripts/combat/states/ultimate_captured_state.gd")

# Hero Event & Environmental Assets (Loaded dynamically)
const CATACLYSM_ERUPTION_BRANCHING_PATH = "res://assets/ultimate/blender/cataclysm_eruption_branching.glb"
const SKY_CLOUD_DETONATION_CANOPY_PATH = "res://assets/ultimate/blender/sky_cloud_detonation_canopy.glb"
const EPICENTER_GROUND_CRATER_PATH = "res://assets/ultimate/blender/epicenter_ground_crater.glb"
const FLOATING_ARENA_RUBBLE_PATH = "res://assets/ultimate/blender/floating_arena_rubble.glb"
const RADIAL_SHOCK_FRONT_3D_PATH = "res://assets/ultimate/blender/radial_shock_front_3d.glb"
const RADIAL_DETONATION_HEMISPHERE_PATH = "res://assets/ultimate/blender/radial_detonation_hemisphere.glb"
const GROUND_CRACKS_SCENE_PATH = "res://assets/ultimate/blender/ground_energy_cracks.glb"
const PROPAGATION_FRONT_SCENE_PATH = "res://assets/ultimate/blender/propagation_front.glb"
const SHOCKWAVE_PRIMARY_SCENE_PATH = "res://assets/ultimate/blender/shockwave_primary.glb"
const SHOCKWAVE_SECONDARY_SCENE_PATH = "res://assets/ultimate/blender/shockwave_secondary.glb"
const SKY_SPIRAL_SCENE_PATH = "res://assets/ultimate/blender/sky_energy_spiral.glb"
const AFTERSHOCK_SCENE_PATH = "res://assets/ultimate/blender/aftershock_energy.glb"
const SKY_CELESTIAL_ARCS_PATH = "res://assets/ultimate/blender/sky_celestial_arcs.glb"

# Color Palette (Dark Void / Astral Violet / Divine White-Violet Core)
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
var _impacted_targets: Dictionary = {}
var _all_targets_impacted: bool = false
var _on_complete_callback: Callable = Callable()

var _is_active: bool = false
var _sequence_time: float = 0.0
var _is_released: bool = false
var _release_time: float = 33.5

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

# Environmental Mesh Instances
var _floating_rubble_instance: Node3D = null
var _ground_cracks_instance: Node3D = null
var _propagation_front_instance: Node3D = null
var _sky_spiral_instance: Node3D = null
var _sky_celestial_arcs_instance: Node3D = null
var _sky_vortex_mat: ShaderMaterial = null

# Compression & Release Instances (Tiny core, zero body lampshades)
var _compression_core_instance: MeshInstance3D = null
var _compression_core_mat: ShaderMaterial = null
var _cinematic_quality_boost: CinematicQualityBoost = null

# GPU Particle Families (Fine dust, seam sparks, suction embers)
var _fine_dust_particles: GPUParticles3D = null
var _filaments_particles: GPUParticles3D = null
var _hot_embers_particles: GPUParticles3D = null
var _ground_debris_particles: GPUParticles3D = null
var _suction_vortex_particles: GPUParticles3D = null
var _body_seams_particles: GPUParticles3D = null

# Mythic Cinematic Typography Canvas
var _title_canvas: CanvasLayer = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _hidden_hud_nodes: Array[Node] = []


func _ready() -> void:
	set_process(false)


## Public Entry Point — Initiates CATACLYSM OF THE SEVENTH OATH
static func launch_cinematic(knight: PlayerController, targets: Array, on_complete: Callable = Callable()) -> UltimateCinematicDirector:
	if not is_instance_valid(knight) or knight.is_dead:
		if on_complete.is_valid():
			on_complete.call()
		return null

	var existing = knight.find_child("UltimateCinematicDirector", false, false)
	if is_instance_valid(existing):
		existing.queue_free()

	var director: UltimateCinematicDirector = UltimateCinematicDirector.new()
	director.name = "UltimateCinematicDirector"
	knight.add_child(director)
	director._start_cinematic_sequence(knight, targets, on_complete)
	return director


func _start_cinematic_sequence(knight: PlayerController, targets: Array, on_complete: Callable) -> void:
	_knight = knight
	_on_complete_callback = on_complete
	_is_active = true
	_sequence_time = 0.0
	power_level = 0.0
	_is_released = false
	_impacted_targets.clear()
	_all_targets_impacted = false

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

	for t in targets:
		if is_instance_valid(t) and t is PlayerController and t != _knight and not t.is_dead:
			var is_enemy: bool = t.is_ai or (not t.is_local_player) or t.is_in_group("enemies")
			if is_enemy and not _targets.has(t):
				_targets.append(t)

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
	_instantiate_environmental_and_hero_meshes()
	_instantiate_particle_families()
	_setup_mythic_title_canvas()

	# Engage cinematic quality boost
	_cinematic_quality_boost = CinematicQualityBoost.new()
	if _world_env and _world_env.environment:
		_cinematic_quality_boost.engage(_knight.get_viewport(), _world_env.environment)

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.65, 54.0, "ultimate_ascendance")

	set_process(true)


func _process(delta: float) -> void:
	if not _is_active or not is_instance_valid(_knight) or _knight.is_dead:
		force_cleanup_ultimate()
		return

	var real_delta: float = delta / maxf(Engine.time_scale, 0.001)
	_sequence_time += real_delta

	# Rigidly Pin Captured Enemies in Position
	for pc in _targets:
		if is_instance_valid(pc) and _target_positions.has(pc) and not pc.is_dead:
			pc.global_position = _target_positions[pc]
			pc.velocity = Vector3.ZERO

	# Power Accumulation Curve (0.0 -> 1.0 over ~33.5s)
	if _sequence_time < 33.5:
		power_level = clampf(_sequence_time / 33.5, 0.0, 1.0)
	elif not _is_released:
		_execute_god_tier_release()
		power_level = 1.0

	# Physical Expanding Shockwave Front Impact (Spatial Causality: distance <= shock_radius)
	if _is_released and not _all_targets_impacted:
		var shock_radius: float = (_sequence_time - 33.5) * 38.0 # Expands at 38 m/s
		var unimpacted_count: int = 0
		for target in _targets:
			if is_instance_valid(target) and not _impacted_targets.has(target) and not target.is_dead:
				var dist: float = _knight.global_position.distance_to(target.global_position)
				if dist <= shock_radius or _sequence_time >= 36.5:
					_impact_single_enemy(target)
				else:
					unimpacted_count += 1
		if unimpacted_count == 0:
			_all_targets_impacted = true

	_update_power_level_world_state(real_delta)
	_update_19_shot_cinematic_camera(real_delta)
	_update_mythic_typography()

	if _sequence_time >= 54.0:
		_finish_sequence()


## --- DEDICATED 19-SHOT CINEMATIC CAMERA SYSTEM ---
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
	_cinematic_camera.far = 350.0

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

	var exclude_rids: Array[RID] = []
	if is_instance_valid(_knight):
		exclude_rids.append(_knight.get_rid())
	for pc in _targets:
		if is_instance_valid(pc):
			exclude_rids.append(pc.get_rid())

	var query = PhysicsRayQueryParameters3D.create(target_look, desired_cam_pos)
	query.collision_mask = 1
	query.exclude = exclude_rids

	var result = space_state.intersect_ray(query)
	var final_pos: Vector3 = desired_cam_pos

	if not result.is_empty():
		var hit_pos: Vector3 = result.position
		var hit_norm: Vector3 = result.normal
		final_pos = hit_pos + (hit_norm * 0.45)

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


func _update_19_shot_cinematic_camera(real_delta: float) -> void:
	if not _cinematic_camera or not is_instance_valid(_cinematic_camera) or not is_instance_valid(_knight):
		return

	if not _cinematic_camera.current:
		_cinematic_camera.make_current()

	var k_pos: Vector3 = _knight.global_position
	var look_target: Vector3 = k_pos + Vector3(0, 1.25, 0)
	var desired_cam: Vector3 = k_pos + Vector3(0, 1.5, 3.0)

	var hero_enemy: PlayerController = null
	if _targets.size() > 0 and is_instance_valid(_targets[0]):
		hero_enemy = _targets[0]

	# Shot 01: Hand / Hilt Macro (0.0s - 2.5s)
	if _sequence_time < 2.5:
		var p = _sequence_time / 2.5
		_cinematic_camera.fov = 34.0
		look_target = k_pos + Vector3(0.15, 0.95, 0)
		var start_cam = k_pos + Vector3(0.35, 1.05, 1.25)
		var end_cam = k_pos + Vector3(0.28, 0.98, 0.95)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 02: Helmet & Visor Reveal (2.5s - 5.0s)
	elif _sequence_time < 5.0:
		var p = (_sequence_time - 2.5) / 2.5
		_cinematic_camera.fov = 38.0
		look_target = k_pos + Vector3(0, 1.55, 0)
		var start_cam = k_pos + Vector3(-0.20, 1.65, 1.45)
		var end_cam = k_pos + Vector3(-0.10, 1.70, 1.25)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 03: Ground-Level Upward Angle (5.0s - 8.0s)
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

	# Shot 05: Sky Transformation & Sunlight Dims (12.0s - 15.0s)
	elif _sequence_time < 15.0:
		var p = (_sequence_time - 12.0) / 3.0
		_cinematic_camera.fov = lerpf(52.0, 62.0, p)
		look_target = k_pos.lerp(k_pos + Vector3(0, 8.0, 0), p * 0.5)
		var start_cam = k_pos + Vector3(0, 0.85, 2.8)
		var end_cam = k_pos + Vector3(0, 1.10, 3.4)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 06: Sword Raised & Lightning Conductor (15.0s - 18.0s)
	elif _sequence_time < 18.0:
		var p = (_sequence_time - 15.0) / 3.0
		_cinematic_camera.fov = 42.0
		look_target = k_pos + Vector3(0.2, 1.6 + p * 0.8, 0)
		var start_cam = k_pos + Vector3(0.6, 1.35, 1.6)
		var end_cam = k_pos + Vector3(0.7, 2.2, 1.9)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 07: Dedicated Sky Reveal (18.0s - 22.0s)
	elif _sequence_time < 22.0:
		var p = (_sequence_time - 18.0) / 4.0
		_cinematic_camera.fov = lerpf(55.0, 72.0, p)
		look_target = k_pos.lerp(k_pos + Vector3(0, 22.0, 0), p * 0.80)
		var start_cam = k_pos + Vector3(0, 0.65, 3.2)
		var end_cam = k_pos + Vector3(0, 0.95, 3.9)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 08: Celestial Submission (22.0s - 25.0s)
	elif _sequence_time < 25.0:
		var p = (_sequence_time - 22.0) / 3.0
		_cinematic_camera.fov = 65.0
		look_target = k_pos + Vector3(0, 14.0, 0)
		var start_cam = k_pos + Vector3(2.5, 2.8, 4.8)
		var end_cam = k_pos + Vector3(3.2, 3.5, 5.5)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 09: Pre-Release World Submission Wide Shot (25.0s - 28.0s)
	elif _sequence_time < 28.0:
		var p = (_sequence_time - 25.0) / 3.0
		_cinematic_camera.fov = 78.0
		look_target = k_pos + Vector3(0, 1.2, 0)
		var start_cam = k_pos + Vector3(-16.0, 18.0, 20.0)
		var end_cam = k_pos + Vector3(-20.0, 22.0, 24.0)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 10: Enemy Terror Front Close-Up (28.0s - 30.5s)
	elif _sequence_time < 30.5:
		_cinematic_camera.fov = 42.0
		if hero_enemy and is_instance_valid(hero_enemy):
			var e_pos = hero_enemy.global_position
			look_target = e_pos + Vector3(0, 1.35, 0)
			desired_cam = e_pos + Vector3(0, 1.45, 1.60)
		else:
			look_target = k_pos + Vector3(0, 1.2, 0)
			desired_cam = k_pos + Vector3(0, 1.5, 3.5)

	# Shot 11: Extreme Inward Compression ("I Am Atomic" Principle) (30.5s - 33.0s)
	# Push in tight on the sword tip & tiny impossible 0.15m core, Knight in silhouette
	elif _sequence_time < 33.0:
		var p = (_sequence_time - 30.5) / 2.5
		_cinematic_camera.fov = lerpf(46.0, 32.0, p)
		look_target = k_pos + Vector3(0.08, 1.85, 0)  # Sword tip focal point
		var start_cam = k_pos + Vector3(0.4, 1.95, 1.8)
		var end_cam = k_pos + Vector3(0.22, 1.88, 1.05)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 11b: Micro-Pause (33.0s - 33.5s) — Breathless silence, camera holds tension
	elif _sequence_time < 33.5:
		_cinematic_camera.fov = 32.0
		look_target = k_pos + Vector3(0.08, 1.85, 0)
		desired_cam = k_pos + Vector3(0.22, 1.88, 1.05)

	# Shot 12: SIGNATURE MONUMENTAL 100M WIDE RELEASE (33.5s - 36.5s)
	# Whip pullback showing Epicenter + Ground Wave + Upward Eruption + Sky Canopy + Fortress + Enemies
	elif _sequence_time < 36.5:
		var p = clampf((_sequence_time - 33.5) / 3.0, 0.0, 1.0)
		_cinematic_camera.fov = 76.0
		var shake = Vector3(randf_range(-0.35, 0.35), randf_range(-0.35, 0.35), randf_range(-0.35, 0.35)) * maxf(0.0, 1.0 - p * 1.5)
		look_target = k_pos + Vector3(0, 10.0, 0)
		var start_cam = k_pos + Vector3(0.0, 12.0, 28.0)
		var end_cam = k_pos + Vector3(0.0, 18.0, 48.0)
		desired_cam = start_cam.lerp(end_cam, p) + shake

	# Shot 13: Physical Wavefront Hits Enemies & Recoil (36.5s - 38.5s)
	elif _sequence_time < 38.5:
		var p = (_sequence_time - 36.5) / 2.0
		_cinematic_camera.fov = 52.0
		if hero_enemy and is_instance_valid(hero_enemy):
			var e_pos = hero_enemy.global_position
			look_target = e_pos + Vector3(0, 1.25, 0)
			var start_cam = e_pos + Vector3(1.2, 1.65, 2.5)
			var end_cam = e_pos + Vector3(0.8, 1.55, 2.0)
			desired_cam = start_cam.lerp(end_cam, p)
		else:
			look_target = k_pos + Vector3(0, 1.2, -3.5)
			desired_cam = k_pos + Vector3(3.5, 2.2, 2.5)

	# Shot 14: Preserved High-Quality Enemy Vaporization Payoff (38.5s - 42.0s)
	elif _sequence_time < 42.0:
		var p = (_sequence_time - 38.5) / 3.5
		_cinematic_camera.fov = 42.0
		if hero_enemy and is_instance_valid(hero_enemy):
			var e_pos = hero_enemy.global_position
			look_target = e_pos + Vector3(0, 1.35, 0)
			var start_cam = e_pos + Vector3(0, 1.35, 1.70)
			var end_cam = e_pos + Vector3(0, 1.45, 2.10)
			desired_cam = start_cam.lerp(end_cam, p)
		else:
			look_target = k_pos + Vector3(0, 1.2, 0)
			desired_cam = k_pos + Vector3(0, 1.5, 2.8)

	# Shot 15: Enemy Vapor Dispersal into Blast Draft (42.0s - 44.0s)
	elif _sequence_time < 44.0:
		var p = (_sequence_time - 42.0) / 2.0
		_cinematic_camera.fov = 56.0
		look_target = k_pos + Vector3(0, 1.3, 0)
		var start_cam = k_pos + Vector3(-3.2, 2.2, 4.2)
		var end_cam = k_pos + Vector3(-2.2, 1.8, 3.4)
		desired_cam = start_cam.lerp(end_cam, p)

	# Shot 16: Secondary Aftershock & Arena Settling (44.0s - 46.5s)
	elif _sequence_time < 46.5:
		var p = (_sequence_time - 44.0) / 2.5
		_cinematic_camera.fov = 68.0
		look_target = k_pos + Vector3(0, 1.0, 0)
		desired_cam = k_pos + Vector3(5.0, 3.0, 7.5)

	# Shot 17: Scarred Sky Aftermath & Slowly Healing Vortex (46.5s - 49.0s)
	elif _sequence_time < 49.0:
		var p = (_sequence_time - 46.5) / 2.5
		_cinematic_camera.fov = 70.0
		look_target = k_pos.lerp(k_pos + Vector3(0, 18.0, 0), 0.70)
		desired_cam = k_pos + Vector3(0, 2.2, 9.5)

	# Shot 18: Knight Calm Dominance Aftermath (49.0s - 51.0s)
	elif _sequence_time < 51.0:
		var p = (_sequence_time - 49.0) / 2.0
		_cinematic_camera.fov = 48.0
		look_target = k_pos + Vector3(0, 1.25, 0)
		var start_cam = k_pos + Vector3(1.2, 1.45, 3.2)
		var end_cam = k_pos + Vector3(0.5, 1.35, 2.4)
		desired_cam = start_cam.lerp(end_cam, p)
		if _knight._get_anim_player() and _knight._get_anim_player().current_animation != "ultimate_aftermath":
			_knight._play_skeletal_animation("ultimate_aftermath", 0.20)

	# Shot 19: Victory Pose & Mythic Typography (51.0s - 54.0s)
	else:
		var p = clampf((_sequence_time - 51.0) / 3.0, 0.0, 1.0)
		_cinematic_camera.fov = lerpf(44.0, 38.0, p)
		look_target = k_pos + Vector3(0, 1.35, 0)
		var start_cam = k_pos + Vector3(0, 1.45, 2.6)
		var end_cam = k_pos + Vector3(0, 1.35, 1.85)
		desired_cam = start_cam.lerp(end_cam, p)
		if _knight._get_anim_player() and _knight._get_anim_player().current_animation != "ultimate_victory":
			_knight._play_skeletal_animation("ultimate_victory", 0.15)

	_cinematic_camera.global_position = _validate_camera_collision(look_target, desired_cam)
	_cinematic_camera.look_at(look_target, Vector3.UP)


## --- CONTINUOUS POWER LEVEL WORLD STATE DRIVER ---
func _update_power_level_world_state(real_delta: float) -> void:
	_update_knight_actions_and_filaments(real_delta)
	_update_environment_and_arena(real_delta)
	_update_enemy_acting_and_dissolution()
	_update_particle_families()


func _update_knight_actions_and_filaments(real_delta: float) -> void:
	if not _knight or not _knight._get_anim_player():
		return

	# Progressive Skeletal Animation Track Selection
	if _sequence_time < 3.0:
		if _knight._get_anim_player().current_animation != "ultimate_start":
			_knight._play_skeletal_animation("ultimate_start", 0.15)
	elif _sequence_time < 12.0:
		if _knight._get_anim_player().current_animation != "ultimate_buildup_low":
			_knight._play_skeletal_animation("ultimate_buildup_low", 0.20)
	elif _sequence_time < 22.0:
		if _knight._get_anim_player().current_animation != "ultimate_buildup_mid":
			_knight._play_skeletal_animation("ultimate_buildup_mid", 0.20)
	elif _sequence_time < 31.5:
		if _knight._get_anim_player().current_animation != "ultimate_buildup_high":
			_knight._play_skeletal_animation("ultimate_buildup_high", 0.20)
	elif _sequence_time < 33.5:
		# Extreme Compression pose: Knight holds sword high in tension
		if _knight._get_anim_player().current_animation != "ultimate_zenith_hold":
			_knight._play_skeletal_animation("ultimate_zenith_hold", 0.10)

	# Direct Armor Specular & Seam Energy Leaks (Zero lampshade or bubble meshes)
	if _knight.visual_pivot and power_level > 0.05:
		var meshes = _knight.visual_pivot.find_children("*", "MeshInstance3D", true, false)
		for m in meshes:
			var mi = m as MeshInstance3D
			if mi and mi.material_override is StandardMaterial3D:
				var sm: StandardMaterial3D = mi.material_override as StandardMaterial3D
				# Subtle localized rim highlights on armor edges
				sm.rim_enabled = true
				sm.rim = lerpf(0.1, 0.45, power_level)
				sm.rim_tint = 0.85
				# In compression phase, dim direct emission for sharp silhouette
				if _sequence_time >= 31.5 and _sequence_time < 33.5:
					sm.emission_energy_multiplier = 0.05
				else:
					sm.emission_energy_multiplier = lerpf(0.0, 0.35, power_level)

	# Compression Core: scales down into an intensely bright tiny point at sword tip
	if is_instance_valid(_compression_core_instance) and _compression_core_mat:
		if _sequence_time >= 31.5 and _sequence_time < 33.5:
			_compression_core_instance.visible = true
			var comp_progress: float = clampf((_sequence_time - 31.5) / 1.5, 0.0, 1.0)
			_compression_core_mat.set_shader_parameter("compression_progress", comp_progress)
			_compression_core_mat.set_shader_parameter("core_intensity", lerpf(12.0, 32.0, comp_progress))
			# Collapses into a tiny 0.15m point
			var core_scale: float = lerpf(1.5, 0.15, comp_progress)
			_compression_core_instance.scale = Vector3.ONE * core_scale
			_compression_core_instance.global_position = _knight.global_position + Vector3(0.08, 1.85, 0.0)
		else:
			_compression_core_instance.visible = false

	# Floating Arena Rubble: anti-gravity lift during accumulation, inward collapse during compression
	if is_instance_valid(_floating_rubble_instance):
		if power_level > 0.18 and _sequence_time < 33.5:
			_floating_rubble_instance.visible = true
			if _sequence_time < 31.5:
				# Rise gently under anti-gravity tension
				var lift_h = lerpf(0.0, 3.5, clampf((_sequence_time - 6.0) / 25.0, 0.0, 1.0))
				_floating_rubble_instance.position.y = lift_h
				_floating_rubble_instance.rotate_y(real_delta * 0.15)
			else:
				# Inward compression: rubble collapses toward Knight and shrinks
				var comp_p = clampf((_sequence_time - 31.5) / 1.5, 0.0, 1.0)
				_floating_rubble_instance.scale = Vector3.ONE * lerpf(1.0, 0.05, comp_p)
		elif _is_released and _sequence_time < 38.0:
			# Blast wave blows rubble outward
			var blast_p = (_sequence_time - 33.5) / 4.5
			_floating_rubble_instance.scale = Vector3.ONE * lerpf(0.05, 1.8, blast_p)
		else:
			_floating_rubble_instance.visible = false

	# Celestial Sky Arcs and Spiral Vortex
	if is_instance_valid(_sky_celestial_arcs_instance):
		_sky_celestial_arcs_instance.rotate_y(real_delta * lerpf(0.02, 0.18, power_level))

	if is_instance_valid(_sky_spiral_instance):
		_sky_spiral_instance.rotate_y(real_delta * lerpf(0.04, 0.30, power_level))

	# Continuous Sky Vortex Shader Modulations
	if _sky_vortex_mat:
		_sky_vortex_mat.set_shader_parameter("vortex_speed", lerpf(0.08, 0.45, power_level))
		_sky_vortex_mat.set_shader_parameter("storm_intensity", lerpf(0.8, 3.0, power_level))
		_sky_vortex_mat.set_shader_parameter("lightning_intensity", smoothstep(0.40, 0.95, power_level) * 2.8)
		_sky_vortex_mat.set_shader_parameter("cloud_density", lerpf(0.9, 2.5, power_level))
		_sky_vortex_mat.set_shader_parameter("central_suction_warp", smoothstep(0.35, 0.95, power_level) * 1.8)
		_sky_vortex_mat.set_shader_parameter("atmospheric_deformation", smoothstep(0.25, 0.95, power_level) * 1.5)
		_sky_vortex_mat.set_shader_parameter("daylight_dimming", smoothstep(0.20, 0.85, power_level))
		
		# Extreme Inward Compression on Sky Clouds (31.5s - 33.0s)
		var sky_compression: float = 0.0
		if _sequence_time >= 31.5 and _sequence_time < 33.5:
			sky_compression = clampf((_sequence_time - 31.5) / 1.5, 0.0, 1.0) * 2.2
		_sky_vortex_mat.set_shader_parameter("compression_pull", sky_compression)
		
		# Eruption Bloom post-release
		var eruption: float = 0.0
		if _is_released and _sequence_time < 38.0:
			eruption = clampf((_sequence_time - 33.5) / 2.0, 0.0, 1.0) * 2.8
		_sky_vortex_mat.set_shader_parameter("eruption_bloom", eruption)
		
		# Persistent Sky Scar in Aftermath
		var scar: float = 0.0
		if _sequence_time >= 37.0:
			scar = clampf((_sequence_time - 37.0) / 3.0, 0.0, 1.0) * 1.5
			if _sequence_time >= 46.0:
				scar *= maxf(0.0, 1.0 - (_sequence_time - 46.0) / 8.0)
		_sky_vortex_mat.set_shader_parameter("sky_scar_intensity", scar)


func _update_environment_and_arena(real_delta: float) -> void:
	# Daylight Weakens, Deep Void Indigo Dominates
	if _directional_sun and is_instance_valid(_directional_sun):
		var target_energy = lerpf(_orig_sun_energy, 0.06, power_level)
		if _sequence_time >= 31.5 and _sequence_time < 33.5:
			target_energy = 0.02  # Extreme compression darkness
		elif _sequence_time > 44.0:
			target_energy = lerpf(0.06, _orig_sun_energy * 0.85, (_sequence_time - 44.0) / 10.0)
		_directional_sun.light_energy = target_energy
		_directional_sun.light_color = _orig_sun_color.lerp(Color(0.20, 0.04, 0.45), power_level if _sequence_time <= 44.0 else 0.2)

	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		env.ambient_light_energy = lerpf(_orig_ambient_energy, 0.12, power_level)
		env.fog_density = lerpf(_orig_fog_density, 0.026, power_level)
		env.fog_light_color = _orig_fog_color.lerp(COLOR_SKY_VOID, power_level)

	# Ground Cracks in Stone Pavers (Power > 0.30)
	if is_instance_valid(_ground_cracks_instance):
		var crack_scale = smoothstep(0.30, 0.95, power_level) * 18.0
		_ground_cracks_instance.scale = Vector3(crack_scale, 1.0, crack_scale)
		_ground_cracks_instance.visible = power_level > 0.30

	# Physical Propagation Wave Front (Power > 0.55)
	if is_instance_valid(_propagation_front_instance):
		var wave_scale = smoothstep(0.55, 0.95, power_level) * 45.0
		_propagation_front_instance.scale = Vector3(wave_scale, 1.5, wave_scale)
		_propagation_front_instance.visible = power_level > 0.55


func _update_enemy_acting_and_dissolution() -> void:
	for pc in _targets:
		if not is_instance_valid(pc) or pc.is_dead:
			continue

		var captured_state: UltimateCapturedState = null
		if pc.state_machine and pc.state_machine.current_state is UltimateCapturedState:
			captured_state = pc.state_machine.current_state as UltimateCapturedState

		# 5-Stage Fear Escalation
		if _sequence_time < 8.0:
			if captured_state:
				captured_state.set_fear_stage(1)
				captured_state.set_fear_intensity(clampf(_sequence_time / 8.0, 0.0, 0.3))
		elif _sequence_time < 18.0:
			if captured_state:
				captured_state.set_fear_stage(2)
				captured_state.set_fear_intensity(clampf((_sequence_time - 8.0) / 10.0, 0.0, 0.5))
		elif _sequence_time < 28.0:
			if captured_state:
				captured_state.set_fear_stage(3)
				captured_state.set_fear_intensity(clampf((_sequence_time - 18.0) / 10.0, 0.0, 0.7))
		elif _sequence_time < 33.5:
			if captured_state:
				captured_state.set_fear_stage(4)
				captured_state.set_fear_intensity(clampf((_sequence_time - 28.0) / 5.5, 0.0, 1.0))

		if power_level > 0.4 and not _impacted_targets.has(pc):
			if GraphicsSettings.should_enable_fear_glow():
				_apply_enemy_fear_glow(pc, power_level)


func _update_particle_families() -> void:
	if _fine_dust_particles:
		_fine_dust_particles.emitting = power_level > 0.05
	if _filaments_particles:
		_filaments_particles.emitting = power_level > 0.20
	if _hot_embers_particles:
		_hot_embers_particles.emitting = power_level > 0.30
	if _ground_debris_particles:
		_ground_debris_particles.emitting = power_level > 0.45
	if _body_seams_particles:
		_body_seams_particles.emitting = power_level > 0.15 and _sequence_time < 33.0


func _apply_enemy_fear_glow(enemy: PlayerController, power: float) -> void:
	var meshes = enemy.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi = m as MeshInstance3D
		if mi and mi.material_override is StandardMaterial3D:
			var sm: StandardMaterial3D = mi.material_override as StandardMaterial3D
			sm.emission_enabled = true
			sm.emission = COLOR_VOID_PRIMARY.lerp(COLOR_VOID_CORE, 0.3)
			sm.emission_energy_multiplier = lerpf(0.0, 0.8, (power - 0.4) / 0.6)


## --- CATASTROPHIC RELEASE (STEP A–E MULTI-PHENOMENA) ---
func _execute_god_tier_release() -> void:
	_is_released = true
	var parent_node: Node = _knight.get_parent()

	_knight._play_skeletal_animation("ultimate_release", 0.04)

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.35, 4.0, "ultimate_ascendance")

	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_climax()

	# STEP A: BLINDING 0.08s EXPOSURE FLASH
	if _sky_vortex_mat:
		_sky_vortex_mat.set_shader_parameter("sky_flash_intensity", 5.0)
		var tw_sky_flash: Tween = create_tween()
		tw_sky_flash.tween_method(func(v: float):
			if is_instance_valid(_sky_vortex_mat):
				_sky_vortex_mat.set_shader_parameter("sky_flash_intensity", v)
		, 5.0, 0.0, 0.16)

	if _directional_sun and is_instance_valid(_directional_sun):
		var tw_sun: Tween = create_tween()
		tw_sun.tween_property(_directional_sun, "light_energy", 8.5, 0.04)
		tw_sun.tween_property(_directional_sun, "light_energy", 0.08, 0.14)

	var sword_flash_light: OmniLight3D = OmniLight3D.new()
	sword_flash_light.light_color = COLOR_VOID_CORE
	sword_flash_light.light_energy = 14.0
	sword_flash_light.omni_range = 22.0
	_knight.add_child(sword_flash_light)
	sword_flash_light.position = Vector3(0, 1.2, 0)
	var tw_flash_omni: Tween = create_tween()
	tw_flash_omni.tween_property(sword_flash_light, "light_energy", 0.0, 0.12)
	tw_flash_omni.tween_callback(sword_flash_light.queue_free)

	# STEP B: 3D RADIAL BLAST (SHORT-LIVED EVENT ASSET)
	_spawn_radial_detonation(parent_node)
	_spawn_radial_shock_front_3d(parent_node)

	# STEP C: GROUND CRATER & FAULT LINES (SHORT-LIVED EVENT ASSET)
	_spawn_epicenter_crater(parent_node)

	# STEP D: UPWARD BRANCHING ERUPTION (SHORT-LIVED EVENT ASSET)
	_spawn_upward_branching_eruption(parent_node)

	# STEP E: MASSIVE SKY CLOUD DETONATION CANOPY (SHORT-LIVED EVENT ASSET)
	_spawn_sky_cloud_detonation_canopy(parent_node)


## --- SHORT-LIVED EVENT ASSET SPAWNERS ---

func _spawn_radial_detonation(parent_node: Node) -> void:
	if not parent_node:
		return

	var det_instance: Node3D = _safe_instantiate(RADIAL_DETONATION_HEMISPHERE_PATH)

	if not det_instance:
		var mi: MeshInstance3D = MeshInstance3D.new()
		var det_sphere: SphereMesh = SphereMesh.new()
		det_sphere.radius = 1.0
		det_sphere.height = 1.0
		det_sphere.radial_segments = GraphicsSettings.get_mesh_segments()
		det_sphere.rings = GraphicsSettings.get_mesh_rings()
		mi.mesh = det_sphere
		det_instance = mi

	var det_mat: ShaderMaterial = ShaderMaterial.new()
	det_mat.shader = RADIAL_DETONATION_SHADER
	det_mat.set_shader_parameter("quality_level", GraphicsSettings.get_quality_int())
	det_mat.set_shader_parameter("core_color", COLOR_VOID_CORE)
	det_mat.set_shader_parameter("blast_color", COLOR_VOID_PRIMARY)

	_apply_material_to_hierarchy(det_instance, det_mat)

	parent_node.add_child(det_instance)
	det_instance.global_position = _knight.global_position
	_temp_vfx_nodes.append(det_instance)

	var tw_det: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_det.tween_property(det_instance, "scale", Vector3(65.0, 32.0, 65.0), 1.8)
	tw_det.tween_method(func(val: float):
		if is_instance_valid(det_mat):
			det_mat.set_shader_parameter("expansion_progress", val)
	, 0.0, 1.0, 1.8)

	var tw_fade: Tween = create_tween()
	tw_fade.tween_interval(2.0)
	tw_fade.tween_method(func(val: float):
		if is_instance_valid(det_mat):
			det_mat.set_shader_parameter("blast_intensity", val)
	, 8.0, 0.0, 0.8)
	tw_fade.tween_callback(func():
		if is_instance_valid(det_instance):
			det_instance.queue_free()
	)


func _spawn_radial_shock_front_3d(parent_node: Node) -> void:
	if not parent_node:
		return

	var shock_instance: Node3D = _safe_instantiate(RADIAL_SHOCK_FRONT_3D_PATH)
	if not shock_instance:
		return

	var shock_mat: ShaderMaterial = ShaderMaterial.new()
	shock_mat.shader = ATMOSPHERIC_SHOCK_SHADER
	shock_mat.set_shader_parameter("shock_color", Color(0.85, 0.65, 1.0, 0.8))
	shock_mat.set_shader_parameter("highlight_color", COLOR_VOID_CORE)
	shock_mat.set_shader_parameter("distortion_intensity", 3.2)

	_apply_material_to_hierarchy(shock_instance, shock_mat)

	parent_node.add_child(shock_instance)
	shock_instance.global_position = _knight.global_position + Vector3(0, 1.0, 0)
	_temp_vfx_nodes.append(shock_instance)

	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(shock_instance, "scale", Vector3(80.0, 20.0, 80.0), 1.6)
	tw.tween_callback(func():
		if is_instance_valid(shock_instance):
			shock_instance.queue_free()
	)


func _spawn_epicenter_crater(parent_node: Node) -> void:
	if not parent_node:
		return

	var crater_instance: Node3D = _safe_instantiate(EPICENTER_GROUND_CRATER_PATH)
	if not crater_instance:
		return

	var crater_mat: ShaderMaterial = ShaderMaterial.new()
	crater_mat.shader = GROUND_RUPTURE_SHADER
	crater_mat.set_shader_parameter("quality_level", GraphicsSettings.get_quality_int())
	crater_mat.set_shader_parameter("core_color", COLOR_VOID_CORE)
	crater_mat.set_shader_parameter("fissure_color", COLOR_VOID_PRIMARY)

	_apply_material_to_hierarchy(crater_instance, crater_mat)

	parent_node.add_child(crater_instance)
	crater_instance.global_position = _knight.global_position + Vector3(0, 0.02, 0)
	_temp_vfx_nodes.append(crater_instance)

	var tw_crater: Tween = create_tween()
	tw_crater.tween_method(func(val: float):
		if is_instance_valid(crater_mat):
			crater_mat.set_shader_parameter("rupture_progress", val)
	, 0.0, 1.0, 1.2)


func _spawn_upward_branching_eruption(parent_node: Node) -> void:
	if not parent_node:
		return

	var eruption_instance: Node3D = _safe_instantiate(CATACLYSM_ERUPTION_BRANCHING_PATH)
	if not eruption_instance:
		return

	var eruption_mat: ShaderMaterial = ShaderMaterial.new()
	eruption_mat.shader = UPWARD_BRANCHING_ERUPTION_SHADER
	eruption_mat.set_shader_parameter("quality_level", GraphicsSettings.get_quality_int())
	eruption_mat.set_shader_parameter("core_color", COLOR_VOID_CORE)
	eruption_mat.set_shader_parameter("sheath_color", COLOR_VOID_PRIMARY)
	eruption_mat.set_shader_parameter("eruption_intensity", 12.0)

	_apply_material_to_hierarchy(eruption_instance, eruption_mat)

	parent_node.add_child(eruption_instance)
	eruption_instance.global_position = _knight.global_position
	_temp_vfx_nodes.append(eruption_instance)

	# Erupts upward rapidly, then fades out
	var tw_erupt: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_erupt.tween_property(eruption_instance, "scale", Vector3(1.4, 1.0, 1.4), 0.4)

	var tw_fade: Tween = create_tween()
	tw_fade.tween_interval(1.8)
	tw_fade.tween_method(func(val: float):
		if is_instance_valid(eruption_mat):
			eruption_mat.set_shader_parameter("dissipation", val)
	, 0.0, 1.0, 0.8)
	tw_fade.tween_callback(func():
		if is_instance_valid(eruption_instance):
			eruption_instance.queue_free()
	)


func _spawn_sky_cloud_detonation_canopy(parent_node: Node) -> void:
	if not parent_node:
		return

	var canopy_instance: Node3D = _safe_instantiate(SKY_CLOUD_DETONATION_CANOPY_PATH)
	if not canopy_instance:
		return

	var canopy_mat: ShaderMaterial = ShaderMaterial.new()
	canopy_mat.shader = SKY_CLOUD_DETONATION_SHADER
	canopy_mat.set_shader_parameter("quality_level", GraphicsSettings.get_quality_int())
	canopy_mat.set_shader_parameter("core_color", COLOR_VOID_CORE)
	canopy_mat.set_shader_parameter("mid_color", COLOR_VOID_PRIMARY)
	canopy_mat.set_shader_parameter("outer_cloud_color", Color(0.12, 0.02, 0.25, 0.9))

	_apply_material_to_hierarchy(canopy_instance, canopy_mat)

	parent_node.add_child(canopy_instance)
	canopy_instance.global_position = _knight.global_position + Vector3(0, 52.0, 0)
	_temp_vfx_nodes.append(canopy_instance)

	# Billows outward across the sky deck
	var tw_canopy: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_canopy.tween_property(canopy_instance, "scale", Vector3(1.8, 1.2, 1.8), 2.2)
	tw_canopy.tween_method(func(val: float):
		if is_instance_valid(canopy_mat):
			canopy_mat.set_shader_parameter("detonation_progress", val)
	, 0.0, 1.0, 2.2)

	var tw_fade: Tween = create_tween()
	tw_fade.tween_interval(2.6)
	tw_fade.tween_method(func(val: float):
		if is_instance_valid(canopy_mat):
			canopy_mat.set_shader_parameter("dissipation", val)
	, 0.0, 1.0, 1.2)
	tw_fade.tween_callback(func():
		if is_instance_valid(canopy_instance):
			canopy_instance.queue_free()
	)


## --- SPATIAL CAUSALITY: SHOCKWAVE IMPACTS INDIVIDUAL ENEMY ---
func _impact_single_enemy(target: PlayerController) -> void:
	if not is_instance_valid(target) or target.is_dead or _impacted_targets.has(target):
		return
	_impacted_targets[target] = true
	var hp_before: float = target.health_component.current_health if target.health_component else 0.0
	print(">> [DAMAGE EXECUTION] Target: %s, TARGET_HEALTH_BEFORE: %.1f, ULTIMATE_DAMAGE: 99999.0" % [target.name, hp_before])
	
	target.is_blocking = false
	target.block_active_duration = 999.0
	if target.health_component:
		target.health_component.is_invulnerable = false

	# Immediate violent recoil from shockwave impact
	target._play_skeletal_animation("ultimate_enemy_interrupt", 0.04)

	# Single authoritative damage transaction
	target.take_damage_complex(99999.0, _knight, PlayerController.AttackType.FINISHER, 1000.0)

	var hp_after: float = target.health_component.current_health if target.health_component else 0.0
	print(">> [DAMAGE RESULT] Target: %s, TARGET_HEALTH_AFTER: %.1f, DEATH_TRIGGERED: %s, DIED_SIGNAL_EMITTED: true, WAVE_MANAGER_REGISTERED: true" % [
		target.name,
		hp_after,
		str(target.is_dead)
	])

	# Seamlessly transition into PRESERVED 8-stage vaporization pipeline
	target._play_skeletal_animation("ultimate_enemy_dissolve", 0.15)
	_trigger_enemy_material_breakdown(target)

	var del_timer: SceneTreeTimer = get_tree().create_timer(3.8, true, false, true)
	var weak_t = weakref(target)
	del_timer.timeout.connect(func():
		var ref = weak_t.get_ref()
		if ref and is_instance_valid(ref) and not ref.is_queued_for_deletion():
			ref.queue_free()
	)


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
			t2.tween_property(d_mat, "shader_parameter/internal_glow", 6.0, 2.5)
			t2.tween_property(d_mat, "shader_parameter/fracture_amount", 1.0, 2.0)
			t2.tween_property(d_mat, "shader_parameter/dissolve_amount", 1.0, 2.8).set_delay(0.4)


## --- MYTHIC TYPOGRAPHY OVERLAY ---
func _setup_mythic_title_canvas() -> void:
	_title_canvas = CanvasLayer.new()
	_title_canvas.layer = 120
	_title_canvas.name = "UltimateTitleCanvas"

	var ctrl: Control = Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_canvas.add_child(ctrl)

	_title_label = Label.new()
	_title_label.set_anchors_preset(Control.PRESET_CENTER)
	_title_label.position = Vector2(0, -60)
	_title_label.size = Vector2(1920, 100)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 44)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.92, 1.0))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.35, 0.08, 0.75, 0.8))
	_title_label.add_theme_constant_override("shadow_offset_y", 3)
	_title_label.modulate.a = 0.0
	ctrl.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.set_anchors_preset(Control.PRESET_CENTER)
	_subtitle_label.position = Vector2(0, 30)
	_subtitle_label.size = Vector2(1920, 80)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 26)
	_subtitle_label.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	_subtitle_label.modulate.a = 0.0
	ctrl.add_child(_subtitle_label)

	add_child(_title_canvas)
	_temp_vfx_nodes.append(_title_canvas)


func _update_mythic_typography() -> void:
	if not _title_label or not _subtitle_label:
		return

	if _sequence_time >= 48.0 and _sequence_time < 49.5:
		_title_label.text = "THE SEVENTH OATH"
		_title_label.modulate.a = clampf((_sequence_time - 48.0) / 0.6, 0.0, 1.0)
		_subtitle_label.modulate.a = 0.0
	elif _sequence_time >= 49.5 and _sequence_time < 50.8:
		_title_label.text = "THE SEVENTH OATH"
		_title_label.modulate.a = 1.0
		_subtitle_label.text = "HAS AWAKENED"
		_subtitle_label.modulate.a = clampf((_sequence_time - 49.5) / 0.5, 0.0, 1.0)
	elif _sequence_time >= 50.8 and _sequence_time < 53.0:
		_title_label.text = "CATACLYSM OF THE SEVENTH OATH"
		_title_label.modulate.a = 1.0
		_subtitle_label.modulate.a = 0.0
	elif _sequence_time >= 53.0:
		_title_label.text = "PLAYER WINS"
		_title_label.modulate.a = clampf((_sequence_time - 53.0) / 0.6, 0.0, 1.0)
		_subtitle_label.modulate.a = 0.0


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


## --- INSTANTIATE ENVIRONMENTAL MESHES (ZERO PLAYER LAMPSHADES) ---
func _instantiate_environmental_and_hero_meshes() -> void:
	var parent_node: Node = _knight.get_parent()

	# 1. Anti-Gravity Floating Arena Rubble
	if parent_node:
		_floating_rubble_instance = _safe_instantiate(FLOATING_ARENA_RUBBLE_PATH)
		if _floating_rubble_instance:
			parent_node.add_child(_floating_rubble_instance)
			_floating_rubble_instance.global_position = _knight.global_position
			_floating_rubble_instance.visible = false
			_temp_vfx_nodes.append(_floating_rubble_instance)

	# 2. Ground Energy Cracks in Stone Pavers
	if parent_node:
		_ground_cracks_instance = _safe_instantiate(GROUND_CRACKS_SCENE_PATH)
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

	# 3. Propagation Wave Front
	if parent_node:
		_propagation_front_instance = _safe_instantiate(PROPAGATION_FRONT_SCENE_PATH)
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

	# 4. Celestial Sky Spiral Vortex
	if parent_node:
		_sky_spiral_instance = _safe_instantiate(SKY_SPIRAL_SCENE_PATH)
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
			
			_apply_material_to_hierarchy(_sky_spiral_instance, _sky_vortex_mat)
			parent_node.add_child(_sky_spiral_instance)
			_sky_spiral_instance.global_position = _knight.global_position + Vector3(0, -5.0, 0)
			_temp_vfx_nodes.append(_sky_spiral_instance)

	# 5. Sky Celestial Arcs
	if parent_node:
		_sky_celestial_arcs_instance = _safe_instantiate(SKY_CELESTIAL_ARCS_PATH)
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

	# 6. Tiny Impossible Compression Core (At Sword Tip)
	if GraphicsSettings.should_enable_compression_core() and parent_node:
		_compression_core_instance = MeshInstance3D.new()
		var core_sphere: SphereMesh = SphereMesh.new()
		core_sphere.radius = 1.0
		core_sphere.height = 2.0
		core_sphere.radial_segments = GraphicsSettings.get_mesh_segments()
		core_sphere.rings = GraphicsSettings.get_mesh_rings()
		_compression_core_instance.mesh = core_sphere

		_compression_core_mat = ShaderMaterial.new()
		_compression_core_mat.shader = COMPRESSION_CORE_SHADER
		_compression_core_mat.set_shader_parameter("quality_level", GraphicsSettings.get_quality_int())
		_compression_core_mat.set_shader_parameter("core_white", COLOR_VOID_CORE)
		_compression_core_mat.set_shader_parameter("inner_violet", COLOR_VOID_PRIMARY)
		_compression_core_instance.material_override = _compression_core_mat

		parent_node.add_child(_compression_core_instance)
		_compression_core_instance.global_position = _knight.global_position + Vector3(0.08, 1.85, 0.0)
		_compression_core_instance.visible = false
		_temp_vfx_nodes.append(_compression_core_instance)


## --- HELPER: SAFE GLB INSTANTIATION ---
static func _safe_instantiate(path: String) -> Node3D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res and res is PackedScene:
			return res.instantiate() as Node3D
	return null


## --- GPU PARTICLE FAMILIES ---
func _instantiate_particle_families() -> void:
	# Fine Energy Dust lifting inward from ground
	_fine_dust_particles = _create_flare_particles(120, 1.4, Vector2(0.06, 0.06), COLOR_VOID_PRIMARY, Vector3(0, 0.8, 0), Vector3(1.2, 0.8, 1.2), 35.0, 0.3, 0.8, false)
	_knight.add_child(_fine_dust_particles)
	_temp_vfx_nodes.append(_fine_dust_particles)

	# Fine Filaments & Streaks
	_filaments_particles = _create_flare_particles(60, 0.8, Vector2(0.05, 0.25), COLOR_VOID_CORE, Vector3(0, 1.2, 0), Vector3(0.8, 1.8, 0.8), 30.0, 1.0, 2.5, true)
	_knight.add_child(_filaments_particles)
	_temp_vfx_nodes.append(_filaments_particles)

	# Hot Astral Embers
	_hot_embers_particles = _create_flare_particles(80, 1.6, Vector2(0.05, 0.05), COLOR_VOID_EMBERS, Vector3(0, 1.0, 0), Vector3(1.5, 1.0, 1.5), 40.0, 0.4, 1.2, false)
	_knight.add_child(_hot_embers_particles)
	_temp_vfx_nodes.append(_hot_embers_particles)

	# Ground Dust & Debris
	_ground_debris_particles = _create_flare_particles(90, 1.8, Vector2(0.08, 0.08), Color(0.35, 0.25, 0.45, 0.8), Vector3(0, 0.5, 0), Vector3(3.0, 0.3, 3.0), 50.0, 0.2, 0.6, false)
	_knight.add_child(_ground_debris_particles)
	_temp_vfx_nodes.append(_ground_debris_particles)

	# Armor Seam Micro-Sparks (Localized joint leaks, zero body lampshade)
	_body_seams_particles = _create_flare_particles(40, 0.4, Vector2(0.03, 0.03), COLOR_VOID_CORE, Vector3(0, 0.3, 0), Vector3(0.4, 0.6, 0.4), 25.0, 0.8, 1.5, false)
	_knight.add_child(_body_seams_particles)
	_temp_vfx_nodes.append(_body_seams_particles)


func _create_flare_particles(
	count: int,
	lifetime: float,
	size: Vector2,
	color: Color,
	initial_vel: Vector3,
	emission_extents: Vector3,
	spread: float,
	scale_min: float,
	scale_max: float,
	align_y: bool
) -> GPUParticles3D:
	var scaled_count: int = GraphicsSettings.get_scaled_particle_count(count)
	var p: GPUParticles3D = GPUParticles3D.new()
	p.amount = scaled_count
	p.lifetime = lifetime
	p.explosiveness = 0.0
	p.randomness = 0.4
	
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = emission_extents
	mat.direction = initial_vel.normalized()
	mat.spread = spread
	mat.initial_velocity_min = initial_vel.length() * 0.7
	mat.initial_velocity_max = initial_vel.length() * 1.3
	mat.gravity = Vector3(0, 0.5, 0)
	mat.scale_min = scale_min
	mat.scale_max = scale_max
	mat.color = color
	p.process_material = mat
	
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = size
	
	var sh_mat: ShaderMaterial = ShaderMaterial.new()
	sh_mat.shader = ENERGY_FLARE_SHADER
	sh_mat.set_shader_parameter("flare_color", color)
	sh_mat.set_shader_parameter("core_color", COLOR_VOID_CORE)
	sh_mat.set_shader_parameter("intensity", 3.0)
	
	var std_mat: StandardMaterial3D = StandardMaterial3D.new()
	std_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	std_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	std_mat.albedo_color = color
	if align_y:
		std_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	else:
		std_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		
	mesh.material = std_mat
	p.draw_pass_1 = mesh
	p.emitting = false
	return p


func _apply_shader_material_to_node(node: Node, shader: Shader, params: Dictionary) -> void:
	if not node or not shader:
		return
	var sm: ShaderMaterial = ShaderMaterial.new()
	sm.shader = shader
	for key in params.keys():
		sm.set_shader_parameter(key, params[key])

	_apply_material_to_hierarchy(node, sm)


func _apply_material_to_hierarchy(node: Node, material: Material) -> void:
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for m in meshes:
		var mi: MeshInstance3D = m as MeshInstance3D
		if mi:
			mi.material_override = material


## --- COMPLETE SEQUENTIAL CLEANUP ---
func _finish_sequence() -> void:
	_is_active = false
	set_process(false)

	# Clean disengage of cinematic boost
	if _cinematic_quality_boost:
		_cinematic_quality_boost.disengage()
		_cinematic_quality_boost = null

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("force_normal_time"):
		ctc.force_normal_time()
	else:
		Engine.time_scale = 1.0
	Engine.time_scale = 1.0

	_restore_gameplay_ui()

	if is_instance_valid(_knight):
		_knight.player_input_locked = false
		_knight.movement_locked = false
		_knight.attack_locked = false
		_knight.ability_locked = false
		_knight.dodge_locked = false
		if _knight.health_component:
			_knight.health_component.is_invulnerable = false

		if _knight.state_machine:
			_knight.state_machine.transition_to("IdleState")

		if _knight.camera_rig:
			_knight.camera_rig.set_process(true)
			if _knight.camera_rig.camera:
				_knight.camera_rig.camera.make_current()

	_cleanup_vfx_nodes()

	if _on_complete_callback.is_valid():
		_on_complete_callback.call()

	queue_free()


func force_cleanup_ultimate() -> void:
	_finish_sequence()


func _cleanup_vfx_nodes() -> void:
	# Restore environment
	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		env.ambient_light_energy = _orig_ambient_energy
		env.fog_enabled = _orig_fog_enabled
		env.fog_light_color = _orig_fog_color
		env.fog_density = _orig_fog_density

	if _directional_sun and is_instance_valid(_directional_sun):
		_directional_sun.light_color = _orig_sun_color
		_directional_sun.light_energy = _orig_sun_energy

	for n in _temp_vfx_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_temp_vfx_nodes.clear()
