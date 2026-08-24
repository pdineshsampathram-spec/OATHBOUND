class_name UltimateVFXController
extends Node

## UltimateVFXController — Overwhelming Cinematic Slow-Motion Battlefield Domination Controller.
## Coordinates the Knight's signature ultimate: "OATHBOUND ASCENDANCE" (~5.8s Cinematic Slow-Motion Event).
## Controls skeletal animation, arena-wide sky takeover, dynamic lighting, celestial sky pillar,
## multi-layer GPUParticles3D, enemy temporal stasis lock, guaranteed lethal damage, and failsafe cleanup.

const DISSOLUTION_SHADER = preload("res://assets/materials/dissolution_shader.gdshader")
const SWORD_ENERGY_SCENE = preload("res://assets/vfx/sword_energy_mesh.glb")
const AURA_RIBBON_SCENE = preload("res://assets/vfx/aura_ribbon_mesh.glb")
const SHOCKWAVE_RING_SCENE = preload("res://assets/vfx/expanding_shockwave_ring.glb")

# Supernatural Color Palette (Dark Void / Astral Violet / Divine Core)
const COLOR_VOID_DARK: Color = Color(0.08, 0.01, 0.16, 0.9)       # Abyssal Indigo
const COLOR_VOID_PRIMARY: Color = Color(0.48, 0.12, 0.95, 1.0)     # Vivid Void Violet
const COLOR_VOID_CORE: Color = Color(0.92, 0.85, 1.0, 1.0)        # Ethereal White-Violet Core
const COLOR_VOID_EMBERS: Color = Color(0.75, 0.45, 1.0, 0.9)      # Shimmering Astral Embers
const COLOR_GOLD_ACCENT: Color = Color(1.0, 0.85, 0.4, 0.9)       # Sacred Gold Accent
const COLOR_SKY_VOID: Color = Color(0.14, 0.04, 0.25, 1.0)         # Supernatural Sky Color

# Active components for cleanup tracking
var _knight: PlayerController = null
var _targets: Array[PlayerController] = []
var _on_complete_callback: Callable = Callable()

var _is_active: bool = false
var _sequence_time: float = 0.0
var _current_phase: int = 0

var _temp_vfx_nodes: Array[Node] = []
var _dissolving_materials: Array[ShaderMaterial] = []
var _camera: Camera3D = null
var _base_cam_transform: Transform3D
var _orig_cam_fov: float = 75.0

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

# Layered VFX Nodes
var _body_aura_particles: GPUParticles3D = null
var _smoke_particles: GPUParticles3D = null
var _filament_particles: GPUParticles3D = null
var _rising_ember_particles: GPUParticles3D = null
var _ground_energy_particles: GPUParticles3D = null
var _suction_particles: GPUParticles3D = null
var _sky_dome_instance: MeshInstance3D = null
var _sky_pillar_instance: MeshInstance3D = null
var _sword_energy_instance: Node3D = null
var _aura_ribbon_instance: Node3D = null

func _ready() -> void:
	set_process(false)

## Public Entry Point — Initiates CATACLYSM OF THE SEVENTH OATH via UltimateCinematicDirector
static func launch_ascendance(knight: PlayerController, targets: Array = [], on_complete: Callable = Callable()) -> Node:
	return UltimateCinematicDirector.launch_cinematic(knight, targets, on_complete)

func _start_sequence(knight: PlayerController, targets: Array, on_complete: Callable) -> void:
	_knight = knight
	_on_complete_callback = on_complete
	_is_active = true
	_sequence_time = 0.0
	_current_phase = 1

	# Lock Knight inputs cleanly
	_knight.player_input_locked = true
	_knight.movement_locked = true
	_knight.attack_locked = true
	_knight.ability_locked = true
	_knight.dodge_locked = true

	# Find valid living targets (Maximum 3 in Solo mode)
	_targets.clear()
	for t in targets:
		if is_instance_valid(t) and t is PlayerController and t != _knight and not t.is_dead:
			_targets.append(t)
			if _targets.size() >= 3:
				break

	# If no explicit targets provided, search surrounding arena
	if _targets.is_empty():
		var parent_node: Node = _knight.get_parent()
		if parent_node:
			for child in parent_node.find_children("*", "PlayerController", true, false):
				var pc = child as PlayerController
				if pc and pc != _knight and is_instance_valid(pc) and not pc.is_dead:
					_targets.append(pc)
					if _targets.size() >= 3:
						break

	# Subjugate and capture all target enemies in temporal stasis
	_capture_and_freeze_targets()

	# Cache and setup Camera Rig
	if _knight.camera_rig and _knight.camera_rig.has_node("SpringArm3D/Camera3D"):
		_camera = _knight.camera_rig.get_node("SpringArm3D/Camera3D")
		if _camera:
			_base_cam_transform = _camera.transform
			_orig_cam_fov = _camera.fov

	# Cache environment and lighting
	_cache_and_setup_environment()

	set_process(true)
	_enter_phase_1_activation()

func _process(delta: float) -> void:
	if not _is_active or not is_instance_valid(_knight) or _knight.is_dead:
		force_cleanup_ultimate()
		return

	# Use unscaled delta for rock-solid deterministic timeline tracking
	var real_delta: float = delta / maxf(Engine.time_scale, 0.001)
	_sequence_time += real_delta

	# Animate helical aura ribbon
	if is_instance_valid(_aura_ribbon_instance):
		_aura_ribbon_instance.rotate_y(real_delta * 4.5)

	# Animate celestial sky dome
	if is_instance_valid(_sky_dome_instance):
		_sky_dome_instance.rotate_y(real_delta * 0.15)

	_update_camera_choreography(real_delta)
	_update_sequence_phases()

func _update_sequence_phases() -> void:
	# 16-Beat Cinematic Slow-Motion Pacing (~5.8s Total Real-Time):
	# 0.0s - 0.6s : Phase 1 (Activation Stillness, 1.0x -> 0.6x)
	# 0.6s - 1.5s : Phase 2 (Aura Emergence & Sky Darkening, 0.35x)
	# 1.5s - 2.4s : Phase 3 (Inward Energy Suction & Sword Glow, 0.35x)
	# 2.4s - 3.4s : Phase 4 (Ceremonial Skyward Elevation & Arena Engulfment, 0.25x)
	# 3.4s - 3.7s : Phase 5 (Zenith Power Compression & Breathless Pause, 0.15x)
	# 3.7s - 4.7s : Phase 6 (Massive Cataclysmic Release & Staggered Vaporization, 0.45x)
	# 4.7s - 5.8s : Phase 7 (Noble Victory Stance, "PLAYER WINS", Normal Gameplay Return, 0.85x -> 1.0x)
	if _sequence_time >= 0.6 and _current_phase == 1:
		_enter_phase_2_dark_aura()
	elif _sequence_time >= 1.5 and _current_phase == 2:
		_enter_phase_3_accumulation()
	elif _sequence_time >= 2.4 and _current_phase == 3:
		_enter_phase_4_skyward_sword()
	elif _sequence_time >= 3.4 and _current_phase == 4:
		_enter_phase_5_compression()
	elif _sequence_time >= 3.7 and _current_phase == 5:
		_enter_phase_6_climax_and_dissolution()
	elif _sequence_time >= 4.7 and _current_phase == 6:
		_enter_phase_7_victory_aftermath()
	elif _sequence_time >= 5.8 and _current_phase == 7:
		_finish_sequence()

## --- ENEMY CAPTURE & TEMPORAL STASIS ---
func _capture_and_freeze_targets() -> void:
	for target in _targets:
		if is_instance_valid(target) and target is PlayerController:
			if target.state_machine:
				target.state_machine.transition_to("UltimateCapturedState", { "knight": _knight })
			# Slow enemy animation to 0.15x for supernatural temporal stasis look
			var ap = target._get_anim_player()
			if ap:
				ap.speed_scale = 0.15

## --- ENVIRONMENT & SKY TAKEOVER ---
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

## --- PHASE 1: ACTIVATION STILLNESS (0.0s - 0.6s) ---
func _enter_phase_1_activation() -> void:
	_current_phase = 1

	# Dynamic Slow-Motion: Smoothly transition from 1.0x to 0.6x
	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.60, 5.8, "ultimate_ascendance")

	# Character Animation: Play the 135-frame continuous Blender-authored hero animation!
	_knight._play_skeletal_animation("ultimate_ascendance", 0.08)
	var ap = _knight._get_anim_player()
	if ap:
		# Paced so the 135 frames play smoothly across the ~5.8s slow-motion duration
		ap.speed_scale = 0.85

	# Audio: Activation sub-bass drone (55Hz)
	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_activation()

	# Environmental reaction: Subtle ground vibration sparks
	var ground_sparks: GPUParticles3D = _create_billboard_particles(
		30, 0.6, Vector2(0.09, 0.09), COLOR_VOID_CORE,
		Vector3(0, 0.05, 0), Vector3(0, 0.6, 0), 50.0, 1.8, 3.5, 0.8
	)
	_knight.add_child(ground_sparks)
	_temp_vfx_nodes.append(ground_sparks)

## --- PHASE 2: DARK AURA & SKY DARKENING (0.6s - 1.5s) ---
func _enter_phase_2_dark_aura() -> void:
	_current_phase = 2

	# Deepen slow-motion to 0.35x
	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.35, 5.2, "ultimate_ascendance")

	# Dynamic Environment Shift: Sun shifts to deep astral indigo, fog thickens across 100m arena
	if _world_env and _world_env.environment:
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_world_env.environment, "fog_density", 0.015, 1.2)
		tween.tween_property(_world_env.environment, "fog_light_color", COLOR_SKY_VOID, 1.2)
		tween.tween_property(_world_env.environment, "ambient_light_energy", 0.30, 1.2)

	if _directional_sun:
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_directional_sun, "light_color", Color(0.35, 0.12, 0.65), 1.2)
		tween.tween_property(_directional_sun, "light_energy", 0.40, 1.2)

	# Spawn Celestial Sky Dome Mesh covering the entire 100m arena
	_spawn_celestial_sky_dome()

	# Blender Custom VFX: Helical Aura Ribbon Mesh
	if AURA_RIBBON_SCENE:
		_aura_ribbon_instance = AURA_RIBBON_SCENE.instantiate() as Node3D
		if _aura_ribbon_instance:
			_apply_emissive_material_to_node(_aura_ribbon_instance, COLOR_VOID_PRIMARY)
			_knight.add_child(_aura_ribbon_instance)
			_aura_ribbon_instance.position = Vector3(0, 0.2, 0)
			_temp_vfx_nodes.append(_aura_ribbon_instance)

	# Layer 1: Body Aura (tight around armor)
	_body_aura_particles = _create_cylinder_particles(
		45, 0.7, Vector2(0.2, 0.2), COLOR_VOID_PRIMARY,
		0.55, 1.5, Vector3(0, 1.2, 0), 0.25
	)
	_knight.add_child(_body_aura_particles)
	_temp_vfx_nodes.append(_body_aura_particles)

	# Layer 2: Dark Smoke Haze (swirling dark volumetric appearance)
	_smoke_particles = _create_cylinder_particles(
		35, 1.0, Vector2(0.4, 0.4), COLOR_VOID_DARK,
		0.75, 1.7, Vector3(0, 0.8, 0), 0.15
	)
	_knight.add_child(_smoke_particles)
	_temp_vfx_nodes.append(_smoke_particles)

	# Layer 3: Energy Filaments (tight orbital ribbons)
	_filament_particles = _create_ring_particles(
		40, 0.65, Vector2(0.14, 0.14), COLOR_VOID_CORE,
		0.7, 0.35, Vector3(0, 0.9, 0), 2.8
	)
	_knight.add_child(_filament_particles)
	_temp_vfx_nodes.append(_filament_particles)

	# Layer 4: Rising Floating Embers
	_rising_ember_particles = _create_cylinder_particles(
		40, 0.9, Vector2(0.07, 0.07), COLOR_VOID_EMBERS,
		0.9, 0.25, Vector3(0, 2.5, 0), 1.0
	)
	_knight.add_child(_rising_ember_particles)
	_temp_vfx_nodes.append(_rising_ember_particles)

	# Layer 5: Ground Energy Circle
	_ground_energy_particles = _create_ring_particles(
		50, 0.8, Vector2(0.16, 0.16), COLOR_VOID_PRIMARY,
		2.2, 0.05, Vector3(0, 0.05, 0), 1.2
	)
	_knight.add_child(_ground_energy_particles)
	_temp_vfx_nodes.append(_ground_energy_particles)

	# Audio: Dark aura energy hum
	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_buildup()

## --- PHASE 3: ENERGY ACCUMULATION (1.5s - 2.4s) ---
func _enter_phase_3_accumulation() -> void:
	_current_phase = 3

	# Inward Suction Particles: Energy rushing from the entire arena into the Knight
	_suction_particles = GPUParticles3D.new()
	_suction_particles.amount = 80
	_suction_particles.lifetime = 0.65
	_suction_particles.explosiveness = 0.0

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 10.0
	pmat.gravity = Vector3.ZERO
	pmat.radial_accel_min = -16.0
	pmat.radial_accel_max = -26.0
	pmat.scale_min = 0.12
	pmat.scale_max = 0.32
	pmat.color = COLOR_VOID_CORE
	_suction_particles.process_material = pmat

	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(0.2, 0.2)
	var smat: StandardMaterial3D = StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = COLOR_VOID_CORE
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = smat
	_suction_particles.draw_pass_1 = qm

	_knight.add_child(_suction_particles)
	_suction_particles.position = Vector3(0, 1.2, 0)
	_temp_vfx_nodes.append(_suction_particles)

	# Blender Custom VFX: Sword Energy Mesh attached directly onto sword pivot
	if SWORD_ENERGY_SCENE and _knight.sword_pivot:
		_sword_energy_instance = SWORD_ENERGY_SCENE.instantiate() as Node3D
		if _sword_energy_instance:
			_apply_emissive_material_to_node(_sword_energy_instance, COLOR_VOID_CORE)
			_knight.sword_pivot.add_child(_sword_energy_instance)
			_temp_vfx_nodes.append(_sword_energy_instance)

## --- PHASE 4: SKYWARD SWORD & ARENA ENGULFMENT (2.4s - 3.4s) ---
func _enter_phase_4_skyward_sword() -> void:
	_current_phase = 4

	# Deepen slow-motion to 0.25x for majestic sword raise
	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.25, 4.0, "ultimate_ascendance")

	# Audio: Resonant blade chime
	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_sword_rise()

	# Arena-Wide Domain Field: Expanding 100m dark-violet surge across the battlefield
	var arena_field: GPUParticles3D = GPUParticles3D.new()
	arena_field.amount = 140
	arena_field.lifetime = 1.2
	arena_field.explosiveness = 0.85

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_radius = 2.5
	pmat.emission_ring_height = 0.1
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.direction = Vector3(0, 0.1, 0)
	pmat.spread = 20.0
	pmat.initial_velocity_min = 25.0
	pmat.initial_velocity_max = 40.0
	pmat.damping_min = 12.0
	pmat.damping_max = 18.0
	pmat.gravity = Vector3(0, 0.8, 0)
	pmat.scale_min = 0.3
	pmat.scale_max = 0.65
	pmat.color = COLOR_VOID_PRIMARY
	arena_field.process_material = pmat

	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(0.4, 0.4)
	var smat: StandardMaterial3D = StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = COLOR_VOID_PRIMARY
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = smat
	arena_field.draw_pass_1 = qm

	var parent_node: Node = _knight.get_parent()
	if parent_node:
		parent_node.add_child(arena_field)
		arena_field.global_position = _knight.global_position
		_temp_vfx_nodes.append(arena_field)

## --- PHASE 5: ZENITH POWER COMPRESSION & PAUSE (3.4s - 3.7s) ---
func _enter_phase_5_compression() -> void:
	_current_phase = 5
	# Ultra-slow breathless moment (0.15x) of maximum energy compression before the release
	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.15, 0.4, "ultimate_ascendance")

## --- PHASE 6: MASSIVE CLIMAX & STAGGERED VAPORIZATION (3.7s - 4.7s) ---
func _enter_phase_6_climax_and_dissolution() -> void:
	_current_phase = 6

	# Accelerate time slightly for explosive release impact (0.45x)
	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.45, 2.5, "ultimate_ascendance")

	# Audio: Massive layered cosmic thunder detonation
	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_climax()

	# Camera Impact Trauma Punch
	if _knight.camera_rig:
		_knight.camera_rig.apply_trauma(0.95)

	# Spawn Celestial Sky Pillar: Massive 65m-tall vertical column connecting sword to sky
	_spawn_celestial_sky_pillar()

	# Blender Custom VFX: Expanding Shockwave Ring Mesh across arena
	if SHOCKWAVE_RING_SCENE:
		var shockwave_mesh: Node3D = SHOCKWAVE_RING_SCENE.instantiate() as Node3D
		if shockwave_mesh:
			_apply_emissive_material_to_node(shockwave_mesh, COLOR_VOID_CORE)
			var parent_node: Node = _knight.get_parent()
			if parent_node:
				parent_node.add_child(shockwave_mesh)
				shockwave_mesh.global_position = _knight.global_position
				shockwave_mesh.scale = Vector3(1.0, 1.0, 1.0)
				_temp_vfx_nodes.append(shockwave_mesh)
				
				var ring_tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				ring_tween.tween_property(shockwave_mesh, "scale", Vector3(36.0, 4.5, 36.0), 0.75)

	# Concentric Climax Shockwave Explosion
	var shockwave: GPUParticles3D = GPUParticles3D.new()
	shockwave.amount = 140
	shockwave.lifetime = 0.7
	shockwave.one_shot = true
	shockwave.explosiveness = 0.95

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 0.25, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 22.0
	pmat.initial_velocity_max = 40.0
	pmat.damping_min = 12.0
	pmat.damping_max = 20.0
	pmat.gravity = Vector3(0, -2.5, 0)
	pmat.scale_min = 0.35
	pmat.scale_max = 0.75
	pmat.color = COLOR_VOID_CORE
	shockwave.process_material = pmat

	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(0.45, 0.45)
	var smat: StandardMaterial3D = StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = COLOR_VOID_CORE
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = smat
	shockwave.draw_pass_1 = qm

	var parent_node: Node = _knight.get_parent()
	if parent_node:
		parent_node.add_child(shockwave)
		shockwave.global_position = _knight.global_position
		shockwave.emitting = true
		_temp_vfx_nodes.append(shockwave)

	# Execute Authoritative Lethal Damage & Staggered Vaporization on captured enemies
	var delay: float = 0.0
	for target in _targets:
		if is_instance_valid(target) and target is PlayerController:
			_execute_enemy_elimination(target, delay)
			delay += 0.22

## Authoritative Execution: Guaranteed Lethal Damage + Staggered Vaporization
func _execute_enemy_elimination(enemy: PlayerController, delay_sec: float) -> void:
	# 1. Authoritatively apply lethal damage and guarantee death state
	if is_instance_valid(enemy):
		enemy.is_blocking = false
		enemy.block_active_duration = 999.0
		if enemy.health_component:
			enemy.health_component.is_invulnerable = false
			enemy.health_component.take_damage(99999.0, _knight)
		enemy.take_damage_complex(99999.0, _knight, PlayerController.AttackType.FINISHER, 1000.0)

	# 2. Visual Vaporization with 3D noise discard shader & inward disintegration particles
	var timer: SceneTreeTimer = get_tree().create_timer(delay_sec, true, false, true)
	timer.timeout.connect(func():
		if not is_instance_valid(enemy):
			return

		# Apply Dissolution Shader to enemy meshes
		var meshes: Array[Node] = enemy.find_children("*", "MeshInstance3D", true, false)
		for mesh_node in meshes:
			var mi: MeshInstance3D = mesh_node as MeshInstance3D
			if mi:
				var d_mat: ShaderMaterial = ShaderMaterial.new()
				d_mat.shader = DISSOLUTION_SHADER
				d_mat.set_shader_parameter("dissolve_amount", 0.0)
				d_mat.set_shader_parameter("burn_color", COLOR_VOID_PRIMARY)
				d_mat.set_shader_parameter("burn_core_color", COLOR_VOID_CORE)
				mi.material_override = d_mat
				_dissolving_materials.append(d_mat)

				# Tween dissolve_amount from 0.0 to 1.0 (vaporization duration ~0.85s)
				var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tween.tween_property(d_mat, "shader_parameter/dissolve_amount", 1.0, 0.85)

		# Spawn Disintegration Particles that vaporize upward and get pulled inward
		var disintegrate_particles: GPUParticles3D = _create_cylinder_particles(
			70, 0.9, Vector2(0.16, 0.16), COLOR_VOID_CORE,
			0.6, 1.6, Vector3(0, 1.5, 0), 2.5
		)
		disintegrate_particles.one_shot = true
		disintegrate_particles.explosiveness = 0.85
		enemy.add_child(disintegrate_particles)
		disintegrate_particles.emitting = true
		_temp_vfx_nodes.append(disintegrate_particles)

		# Audio: Particle crackle disintegration
		if _knight.combat_audio:
			_knight.combat_audio.play_ultimate_dissolution()

		# Final cleanup: Free enemy node after vaporization completes
		var kill_timer: SceneTreeTimer = get_tree().create_timer(0.95, true, false, true)
		kill_timer.timeout.connect(func():
			if is_instance_valid(enemy):
				enemy.queue_free()
		)
	)

## --- PHASE 7: NOBLE VICTORY CAMERA & AFTERMATH (4.7s - 5.8s) ---
func _enter_phase_7_victory_aftermath() -> void:
	_current_phase = 7

	# Smoothly return time scale toward normal (0.85x)
	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.85, 1.2, "ultimate_ascendance")

	# Audio: Triumphant victory chord
	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_victory()

	# Announce Victory on HUD
	var hud: CombatHUD = _find_combat_hud()
	if hud:
		hud.show_announcement("OATHBOUND ASCENDANCE", 2.5)

	# Gracefully fade sky takeover and return lighting
	_restore_environment_lighting(1.0)

	# Fade out aura emitters
	for node in _temp_vfx_nodes:
		if is_instance_valid(node) and node is GPUParticles3D:
			node.emitting = false

## --- SEQUENCE COMPLETION & GUARANTEED RESTORATION ---
func _finish_sequence() -> void:
	force_cleanup_ultimate()

	if _on_complete_callback.is_valid():
		_on_complete_callback.call()

## Guaranteed cleanup function called on completion, interrupt, death, scene change, or disconnect
func force_cleanup_ultimate() -> void:
	if not _is_active:
		return
	_is_active = false
	set_process(false)

	# Restore time scale unconditionally via CombatTimeController
	if is_inside_tree():
		var ctc: Node = get_node_or_null("/root/CombatTimeController")
		if ctc and ctc.has_method("force_restore_normal_time"):
			ctc.force_restore_normal_time()

	# Restore player state and controls with guaranteed authority
	if is_instance_valid(_knight):
		_knight.force_restore_player_control()

	# Restore environment and lighting
	_restore_environment_lighting(0.3)

	# Restore camera
	if _camera and is_instance_valid(_camera):
		var tween: Tween = create_tween()
		tween.tween_property(_camera, "fov", _orig_cam_fov, 0.4)
		tween.parallel().tween_property(_camera, "transform", _base_cam_transform, 0.4)

	# Cleanup all temporary VFX nodes
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

## --- CELESTIAL SKY DOME & PILLAR GENERATORS ---

func _spawn_celestial_sky_dome() -> void:
	_sky_dome_instance = MeshInstance3D.new()
	_sky_dome_instance.name = "CelestialSkyDome"

	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = 80.0
	sphere_mesh.height = 70.0
	sphere_mesh.is_hemisphere = true

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.05, 0.35, 0.75)
	mat.cull_mode = BaseMaterial3D.CULL_FRONT # Inside surface visible
	sphere_mesh.material = mat
	_sky_dome_instance.mesh = sphere_mesh

	var parent_node: Node = _knight.get_parent()
	if parent_node:
		parent_node.add_child(_sky_dome_instance)
		_sky_dome_instance.global_position = _knight.global_position + Vector3(0, -5.0, 0)
		_temp_vfx_nodes.append(_sky_dome_instance)

func _spawn_celestial_sky_pillar() -> void:
	_sky_pillar_instance = MeshInstance3D.new()
	_sky_pillar_instance.name = "CelestialSkyPillar"

	var cyl_mesh: CylinderMesh = CylinderMesh.new()
	cyl_mesh.top_radius = 2.5
	cyl_mesh.bottom_radius = 1.2
	cyl_mesh.height = 65.0

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = COLOR_VOID_CORE
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cyl_mesh.material = mat
	_sky_pillar_instance.mesh = cyl_mesh

	var parent_node: Node = _knight.get_parent()
	if parent_node:
		parent_node.add_child(_sky_pillar_instance)
		_sky_pillar_instance.global_position = _knight.global_position + Vector3(0, 30.0, 0)
		_temp_vfx_nodes.append(_sky_pillar_instance)

		# Animate flash & fade out of the pillar
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_sky_pillar_instance, "scale:x", 3.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_sky_pillar_instance, "scale:z", 3.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

## --- CAMERA CHOREOGRAPHY ---
func _update_camera_choreography(real_delta: float) -> void:
	if not _camera or not is_instance_valid(_camera):
		return

	# Phase 1 & 2: Smooth slow-motion dolly in & downward tilt
	if _sequence_time < 2.4:
		var factor: float = clampf(_sequence_time / 2.4, 0.0, 1.0)
		_camera.fov = lerpf(_orig_cam_fov, _orig_cam_fov - 12.0, factor)
	# Phase 4 (Sword Elevation): Low-angle orbital sweep around the Knight
	elif _sequence_time < 3.4:
		var orbit_progress: float = (_sequence_time - 2.4) / 1.0
		var angle: float = orbit_progress * 0.45
		_camera.h_offset = sin(angle) * 0.5
		_camera.v_offset = cos(angle) * 0.25
	# Phase 5 & 6 (Climax): Focus punch
	elif _sequence_time < 4.7:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0
	# Phase 7 (Victory): Smooth hero pullback
	else:
		var pull_progress: float = clampf((_sequence_time - 4.7) / 1.1, 0.0, 1.0)
		_camera.fov = lerpf(_orig_cam_fov - 12.0, _orig_cam_fov, pull_progress)

## --- PARTICLE FACTORY HELPERS ---

func _create_cylinder_particles(
	amount: int, lifetime: float, quad_size: Vector2, color: Color,
	radius: float, height: float, gravity: Vector3, speed: float
) -> GPUParticles3D:
	var p: GPUParticles3D = GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 0.1

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_radius = radius
	pmat.emission_ring_height = height
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 20.0
	pmat.initial_velocity_min = speed * 0.8
	pmat.initial_velocity_max = speed * 1.2
	pmat.gravity = gravity
	pmat.scale_min = 0.1
	pmat.scale_max = 0.28
	pmat.color = color
	p.process_material = pmat

	var qm: QuadMesh = QuadMesh.new()
	qm.size = quad_size
	var smat: StandardMaterial3D = StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = color
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = smat
	p.draw_pass_1 = qm

	return p

func _create_ring_particles(
	amount: int, lifetime: float, quad_size: Vector2, color: Color,
	radius: float, height: float, offset: Vector3, initial_vel: float
) -> GPUParticles3D:
	var p: GPUParticles3D = _create_cylinder_particles(amount, lifetime, quad_size, color, radius, height, Vector3.ZERO, initial_vel)
	p.position = offset
	return p

func _create_billboard_particles(
	amount: int, lifetime: float, quad_size: Vector2, color: Color,
	offset: Vector3, dir: Vector3, spread: float, v_min: float, v_max: float, damp: float
) -> GPUParticles3D:
	var p: GPUParticles3D = GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 0.8

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.direction = dir
	pmat.spread = spread
	pmat.initial_velocity_min = v_min
	pmat.initial_velocity_max = v_max
	pmat.damping_min = damp
	pmat.damping_max = damp * 1.5
	pmat.scale_min = 0.08
	pmat.scale_max = 0.22
	pmat.color = color
	p.process_material = pmat

	var qm: QuadMesh = QuadMesh.new()
	qm.size = quad_size
	var smat: StandardMaterial3D = StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = color
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = smat
	p.draw_pass_1 = qm

	p.position = offset
	return p

func _find_combat_hud() -> CombatHUD:
	var root: Node = get_tree().root
	var hud = root.find_child("CombatHUD", true, false)
	return hud as CombatHUD

func _apply_emissive_material_to_node(root_node: Node, color: Color) -> void:
	if not root_node: return
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	var meshes: Array[Node] = root_node.find_children("*", "MeshInstance3D", true, false)
	if root_node is MeshInstance3D:
		meshes.append(root_node)
	for m in meshes:
		var mi: MeshInstance3D = m as MeshInstance3D
		if mi:
			mi.material_override = mat
