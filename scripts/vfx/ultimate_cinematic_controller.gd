class_name UltimateCinematicController
extends Node

## UltimateCinematicController — "CATACLYSM OF THE SEVENTH OATH"
## God-Tier 42-Second Battlefield Cataclysm Director.
## Coordinates 12 distinct scenes, 12 emotional camera choreographies (Close -> Med -> Wide -> Close -> Wide -> Close),
## layered atmospheric sky vortex, physical ground propagation wave, 8-stage material-specific enemy vaporization,
## multi-scale cataclysmic release, lingering aftermath, and 100% authoritative combat reliability.

const ENERGY_RIBBON_SHADER = preload("res://assets/materials/energy_ribbon.gdshader")
const CELESTIAL_SKY_SHADER = preload("res://assets/materials/celestial_sky_vortex.gdshader")
const DISSOLUTION_SHADER = preload("res://assets/materials/dissolution_shader.gdshader")
const ENERGY_FLARE_SHADER = preload("res://assets/materials/energy_flare.gdshader")

const SWORD_ENERGY_SCENE = preload("res://assets/vfx/sword_energy_mesh.glb")
const AURA_RIBBON_SCENE = preload("res://assets/vfx/aura_ribbon_mesh.glb")
const SHOCKWAVE_RING_SCENE = preload("res://assets/vfx/expanding_shockwave_ring.glb")
const PROPAGATION_WAVE_SCENE = preload("res://assets/vfx/propagation_wave_mesh.glb")
const CELESTIAL_DOME_SCENE = preload("res://assets/vfx/celestial_dome_mesh.glb")

# Supernatural Color Palette (Dark Void / Astral Violet / Divine Core)
const COLOR_VOID_DARK: Color = Color(0.06, 0.01, 0.12, 0.95)      # Abyssal Indigo
const COLOR_VOID_PRIMARY: Color = Color(0.48, 0.12, 0.95, 1.0)     # Vivid Void Violet
const COLOR_VOID_CORE: Color = Color(0.94, 0.88, 1.0, 1.0)        # Ethereal White-Violet Core
const COLOR_VOID_EMBERS: Color = Color(0.75, 0.45, 1.0, 0.9)      # Shimmering Astral Embers
const COLOR_GOLD_ACCENT: Color = Color(1.0, 0.85, 0.4, 0.9)       # Sacred Gold Accent
const COLOR_SKY_VOID: Color = Color(0.12, 0.03, 0.22, 1.0)         # Supernatural Sky Color

# Active tracking variables
var _knight: PlayerController = null
var _targets: Array[PlayerController] = []
var _on_complete_callback: Callable = Callable()

var _is_active: bool = false
var _sequence_time: float = 0.0
var _current_scene: int = 0

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

# Layered Mesh & VFX Nodes
var _body_aura_particles: GPUParticles3D = null
var _smoke_particles: GPUParticles3D = null
var _filament_particles: GPUParticles3D = null
var _rising_ember_particles: GPUParticles3D = null
var _ground_energy_particles: GPUParticles3D = null
var _suction_particles: GPUParticles3D = null
var _sky_dome_instance: Node3D = null
var _sky_pillar_instance: MeshInstance3D = null
var _sword_energy_instance: Node3D = null
var _aura_ribbon_instance: Node3D = null
var _propagation_wave_instance: Node3D = null

func _ready() -> void:
	set_process(false)

## Public Entry Point — Initiates CATACLYSM OF THE SEVENTH OATH via UltimateCinematicDirector
static func launch_cinematic(knight: PlayerController, targets: Array = [], on_complete: Callable = Callable()) -> Node:
	return UltimateCinematicDirector.launch_cinematic(knight, targets, on_complete)

func _start_sequence(knight: PlayerController, targets: Array, on_complete: Callable) -> void:
	_knight = knight
	_on_complete_callback = on_complete
	_is_active = true
	_sequence_time = 0.0
	_current_scene = 1

	# 1. Guaranteed Player Cinematic Safety & Invulnerability
	_knight.player_input_locked = true
	_knight.movement_locked = true
	_knight.attack_locked = true
	_knight.ability_locked = true
	_knight.dodge_locked = true
	if _knight.health_component:
		_knight.health_component.is_invulnerable = true

	# 2. Arena-Wide Enemy Subjugation & Threat Neutralization
	_targets.clear()
	var parent_node: Node = _knight.get_parent()
	if parent_node:
		for child in parent_node.find_children("*", "PlayerController", true, false):
			var pc = child as PlayerController
			if pc and pc != _knight and is_instance_valid(pc) and not pc.is_dead:
				_targets.append(pc)
				# Freeze enemy completely: no attacks, no damage, no movement
				pc.is_blocking = false
				pc.block_active_duration = 999.0
				if pc.state_machine:
					pc.state_machine.transition_to("UltimateCapturedState", { "knight": _knight })
				var ap = pc._get_anim_player()
				if ap:
					ap.speed_scale = 0.15 # Supernatural temporal stasis

	# Cache camera and environment
	if _knight.camera_rig and _knight.camera_rig.has_node("SpringArm3D/Camera3D"):
		_camera = _knight.camera_rig.get_node("SpringArm3D/Camera3D")
		if _camera:
			_base_cam_transform = _camera.transform
			_orig_cam_fov = _camera.fov

	_cache_and_setup_environment()

	set_process(true)
	_enter_scene_01_preparation()

func _process(delta: float) -> void:
	if not _is_active or not is_instance_valid(_knight) or _knight.is_dead:
		force_cleanup_ultimate()
		return

	var real_delta: float = delta / maxf(Engine.time_scale, 0.001)
	_sequence_time += real_delta

	# Animate helical aura ribbon with organic twist
	if is_instance_valid(_aura_ribbon_instance):
		_aura_ribbon_instance.rotate_y(real_delta * 2.8)

	# Animate celestial sky vortex
	if is_instance_valid(_sky_dome_instance):
		_sky_dome_instance.rotate_y(real_delta * 0.08)

	_update_camera_director(real_delta)
	_update_timeline_scenes()

func _update_timeline_scenes() -> void:
	# 12-Scene Cinematic Arc (~42.0s Total):
	if _sequence_time >= 3.5 and _current_scene == 1:
		_enter_scene_02_power_awakening()
	elif _sequence_time >= 6.8 and _current_scene == 2:
		_enter_scene_03_aura_formation()
	elif _sequence_time >= 11.0 and _current_scene == 3:
		_enter_scene_04_sky_transformation()
	elif _sequence_time >= 15.5 and _current_scene == 4:
		_enter_scene_05_sword_ascension()
	elif _sequence_time >= 20.0 and _current_scene == 5:
		_enter_scene_06_battlefield_capture()
	elif _sequence_time >= 24.5 and _current_scene == 6:
		_enter_scene_07_enemy_terror()
	elif _sequence_time >= 27.5 and _current_scene == 7:
		_enter_scene_08_enemy_vaporization()
	elif _sequence_time >= 31.5 and _current_scene == 8:
		_enter_scene_09_zenith_compression()
	elif _sequence_time >= 33.5 and _current_scene == 9:
		_enter_scene_10_cataclysmic_release()
	elif _sequence_time >= 37.0 and _current_scene == 10:
		_enter_scene_11_aftermath()
	elif _sequence_time >= 40.0 and _current_scene == 11:
		_enter_scene_12_victory()
	elif _sequence_time >= 43.5 and _current_scene == 12:
		_finish_sequence()

## --- ENVIRONMENT & LIGHTING CACHING ---
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

## =========================================================================
## 12 CINEMATIC SCENE IMPLEMENTATIONS
## =========================================================================

## --- SCENE 01: PREPARATION & TENSION (0.0s - 3.5s) ---
## Emotional Purpose: "Something is wrong."
## Camera: Tight Close-Up on helmet, hands gripping hilt, grounded boots.
func _enter_scene_01_preparation() -> void:
	_current_scene = 1

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.85, 43.0, "ultimate_ascendance")

	# Play 40s Blender-authored hero animation!
	_knight._play_skeletal_animation("ultimate_ascendance", 0.12)
	var ap = _knight._get_anim_player()
	if ap:
		ap.speed_scale = 1.0

	# Audio: Duck combat sound, low tension drone
	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_activation()

	# Elegant Mythic Title Typography Display
	var hud: CombatHUD = _find_combat_hud()
	if hud:
		hud.show_announcement("THE SEVENTH OATH AWAKENS", 3.0)

## --- SCENE 02: POWER AWAKENING (3.5s - 6.8s) ---
## Emotional Purpose: "Power has awakened."
## Camera: Low-Angle looking up as faint ground dust & violet sparks lift from stone seams.
func _enter_scene_02_power_awakening() -> void:
	_current_scene = 2

	var ground_sparks: GPUParticles3D = _create_flare_particles(
		45, 1.4, Vector2(0.12, 0.12), COLOR_VOID_CORE,
		Vector3(0, 0.05, 0), Vector3(0, 0.6, 0), 40.0, 1.2, 2.5, false
	)
	_knight.add_child(ground_sparks)
	_temp_vfx_nodes.append(ground_sparks)

## --- SCENE 03: AURA FORMATION (6.8s - 11.0s) ---
## Emotional Purpose: "This is growing."
## Camera: Medium orbit around rising double-helix ribbons. Character remains clearly framed!
func _enter_scene_03_aura_formation() -> void:
	_current_scene = 3

	# Blender Custom VFX: Organic Spiral Ribbons with dynamic plasma shader (no solid tubes!)
	if AURA_RIBBON_SCENE:
		_aura_ribbon_instance = AURA_RIBBON_SCENE.instantiate() as Node3D
		if _aura_ribbon_instance:
			_apply_shader_material_to_node(_aura_ribbon_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 1.5,
				"fresnel_power": 2.5
			})
			_knight.add_child(_aura_ribbon_instance)
			_aura_ribbon_instance.position = Vector3(0, 0.1, 0)
			_temp_vfx_nodes.append(_aura_ribbon_instance)

	# Layer 1: Body Aura (soft organic flares following armor)
	_body_aura_particles = _create_flare_particles(
		50, 0.9, Vector2(0.2, 0.2), COLOR_VOID_PRIMARY,
		Vector3(0, 1.1, 0), Vector3(0, 1.2, 0), 30.0, 0.5, 1.2, false
	)
	_knight.add_child(_body_aura_particles)
	_temp_vfx_nodes.append(_body_aura_particles)

	# Layer 2: Dark Smoke Haze
	_smoke_particles = _create_flare_particles(
		35, 1.4, Vector2(0.4, 0.4), COLOR_VOID_DARK,
		Vector3(0, 0.8, 0), Vector3(0, 0.8, 0), 40.0, 0.3, 0.8, false
	)
	_knight.add_child(_smoke_particles)
	_temp_vfx_nodes.append(_smoke_particles)

	# Layer 3: Fast-moving Energy Streaks
	_filament_particles = _create_flare_particles(
		45, 0.7, Vector2(0.14, 0.45), COLOR_VOID_CORE,
		Vector3(0, 1.0, 0), Vector3(0, 2.5, 0), 50.0, 2.0, 4.0, true
	)
	_knight.add_child(_filament_particles)
	_temp_vfx_nodes.append(_filament_particles)

	# Layer 4: Rising Floating Embers
	_rising_ember_particles = _create_flare_particles(
		40, 1.4, Vector2(0.08, 0.08), COLOR_VOID_EMBERS,
		Vector3(0, 0.2, 0), Vector3(0, 2.2, 0), 30.0, 0.8, 1.8, false
	)
	_knight.add_child(_rising_ember_particles)
	_temp_vfx_nodes.append(_rising_ember_particles)

	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_buildup()

## --- SCENE 04: SKY TRANSFORMATION (11.0s - 15.5s) ---
## Emotional Purpose: "The heavens are changing."
## Camera: Wide low-angle looking past Knight into the swirling celestial storm vortex.
func _enter_scene_04_sky_transformation() -> void:
	_current_scene = 4

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.40, 32.0, "ultimate_ascendance")

	# Real-time atmospheric shift
	if _world_env and _world_env.environment:
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_world_env.environment, "fog_density", 0.016, 2.5)
		tween.tween_property(_world_env.environment, "fog_light_color", COLOR_SKY_VOID, 2.5)
		tween.tween_property(_world_env.environment, "ambient_light_energy", 0.25, 2.5)

	if _directional_sun:
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_directional_sun, "light_color", Color(0.32, 0.10, 0.60), 2.5)
		tween.tween_property(_directional_sun, "light_energy", 0.35, 2.5)

	# Spawn Blender Celestial Dome with dynamic shader (no fake purple bowl!)
	if CELESTIAL_DOME_SCENE:
		_sky_dome_instance = CELESTIAL_DOME_SCENE.instantiate() as Node3D
		if _sky_dome_instance:
			_apply_shader_material_to_node(_sky_dome_instance, CELESTIAL_SKY_SHADER, {
				"sky_dark_color": Color(0.06, 0.02, 0.12, 1.0),
				"sky_indigo_color": Color(0.22, 0.05, 0.38, 1.0),
				"cloud_energy_color": Color(0.70, 0.40, 1.0, 1.0),
				"vortex_speed": 0.08,
				"storm_intensity": 1.2
			})
			var parent_node: Node = _knight.get_parent()
			if parent_node:
				parent_node.add_child(_sky_dome_instance)
				_sky_dome_instance.global_position = _knight.global_position + Vector3(0, -5.0, 0)
				_temp_vfx_nodes.append(_sky_dome_instance)

## --- SCENE 05: SWORD ASCENSION (15.5s - 20.0s) ---
## Emotional Purpose: "The Knight has become the focus."
## Camera: Medium vertical tracking following the glowing blade tip to the heavens.
func _enter_scene_05_sword_ascension() -> void:
	_current_scene = 5

	# Attach Blender Custom VFX Sword Energy Mesh with plasma shader
	if SWORD_ENERGY_SCENE and _knight.sword_pivot:
		_sword_energy_instance = SWORD_ENERGY_SCENE.instantiate() as Node3D
		if _sword_energy_instance:
			_apply_shader_material_to_node(_sword_energy_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 2.2,
				"fresnel_power": 1.8
			})
			_knight.sword_pivot.add_child(_sword_energy_instance)
			_temp_vfx_nodes.append(_sword_energy_instance)

	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_sword_rise()

## --- SCENE 06: BATTLEFIELD CAPTURE WAVE (20.0s - 24.5s) ---
## Emotional Purpose: "The entire battlefield is being claimed."
## Camera: Extreme wide panoramic high-angle shot showing 100m fortress and traveling wave.
func _enter_scene_06_battlefield_capture() -> void:
	_current_scene = 6

	# Physical Ground Propagation Wave
	if PROPAGATION_WAVE_SCENE:
		_propagation_wave_instance = PROPAGATION_WAVE_SCENE.instantiate() as Node3D
		if _propagation_wave_instance:
			_apply_shader_material_to_node(_propagation_wave_instance, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 1.2,
				"fresnel_power": 3.0
			})
			var parent_node: Node = _knight.get_parent()
			if parent_node:
				parent_node.add_child(_propagation_wave_instance)
				_propagation_wave_instance.global_position = _knight.global_position + Vector3(0, 0.1, 0)
				_propagation_wave_instance.scale = Vector3(1.0, 1.0, 1.0)
				_temp_vfx_nodes.append(_propagation_wave_instance)

				# Physical wave visibly travels outward from 5m to 100m
				var wave_tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				wave_tween.tween_property(_propagation_wave_instance, "scale", Vector3(30.0, 2.0, 30.0), 4.5)

	# Inward Suction Particle Flares across arena
	_suction_particles = GPUParticles3D.new()
	_suction_particles.amount = 100
	_suction_particles.lifetime = 1.0
	_suction_particles.explosiveness = 0.0

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 20.0
	pmat.gravity = Vector3.ZERO
	pmat.radial_accel_min = -20.0
	pmat.radial_accel_max = -35.0
	pmat.scale_min = 0.15
	pmat.scale_max = 0.35
	pmat.color = COLOR_VOID_CORE
	_suction_particles.process_material = pmat

	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(0.25, 0.25)
	var smat: ShaderMaterial = ShaderMaterial.new()
	smat.shader = ENERGY_FLARE_SHADER
	smat.set_shader_parameter("core_color", COLOR_VOID_CORE)
	smat.set_shader_parameter("edge_color", COLOR_VOID_PRIMARY)
	qm.material = smat
	_suction_particles.draw_pass_1 = qm

	_knight.add_child(_suction_particles)
	_suction_particles.position = Vector3(0, 1.2, 0)
	_temp_vfx_nodes.append(_suction_particles)

## --- SCENE 07: ENEMY TERROR & TEMPORAL STASIS (24.5s - 27.5s) ---
## Emotional Purpose: "The enemies realize they are trapped."
## Camera: Tight Close-Up on enemy helmet/face experiencing temporal stasis.
func _enter_scene_07_enemy_terror() -> void:
	_current_scene = 7
	# Enemies are already locked in stasis from _start_sequence

## --- SCENE 08: 8-STAGE ENEMY VAPORIZATION (27.5s - 31.5s) ---
## Emotional Purpose: "They are being destroyed."
## Camera: Medium Dissolution framing physical material breakdown and inward vapor suction.
func _enter_scene_08_enemy_vaporization() -> void:
	_current_scene = 8

	var delay: float = 0.0
	for target in _targets:
		if is_instance_valid(target) and target is PlayerController:
			_execute_8_stage_enemy_vaporization(target, delay)
			delay += 0.85

func _execute_8_stage_enemy_vaporization(enemy: PlayerController, delay_sec: float) -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(delay_sec, true, false, true)
	timer.timeout.connect(func():
		if not is_instance_valid(enemy):
			return

		var meshes: Array[Node] = enemy.find_children("*", "MeshInstance3D", true, false)
		for mesh_node in meshes:
			var mi: MeshInstance3D = mesh_node as MeshInstance3D
			if mi:
				var d_mat: ShaderMaterial = ShaderMaterial.new()
				d_mat.shader = DISSOLUTION_SHADER
				d_mat.set_shader_parameter("internal_glow", 0.0)
				d_mat.set_shader_parameter("fracture_amount", 0.0)
				d_mat.set_shader_parameter("dissolve_amount", 0.0)
				d_mat.set_shader_parameter("burn_color", COLOR_VOID_PRIMARY)
				d_mat.set_shader_parameter("burn_core_color", COLOR_VOID_CORE)
				mi.material_override = d_mat
				_dissolving_materials.append(d_mat)

				# Stage 2: Internal Glow (0.0s -> 0.4s)
				var t2: Tween = create_tween()
				t2.tween_property(d_mat, "shader_parameter/internal_glow", 4.0, 0.4)

				# Stage 3: Surface Fracture Veins (0.4s -> 0.8s)
				var t3: Tween = create_tween()
				t3.tween_interval(0.4)
				t3.tween_property(d_mat, "shader_parameter/fracture_amount", 1.0, 0.4)

				# Stage 4-7: 3D Noise Dissolve & Vapor Disintegration (0.8s -> 2.2s)
				var t4: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				t4.tween_interval(0.8)
				t4.tween_property(d_mat, "shader_parameter/dissolve_amount", 1.0, 1.4)

		# Disintegration particles pulled toward Knight's aura
		var disintegrate_particles: GPUParticles3D = _create_flare_particles(
			80, 1.2, Vector2(0.18, 0.18), COLOR_VOID_CORE,
			Vector3(0, 1.2, 0), Vector3(0, 1.8, 0), 40.0, 1.0, 2.5, false
		)
		disintegrate_particles.one_shot = true
		disintegrate_particles.explosiveness = 0.85
		enemy.add_child(disintegrate_particles)
		disintegrate_particles.emitting = true
		_temp_vfx_nodes.append(disintegrate_particles)

		if _knight.combat_audio:
			_knight.combat_audio.play_ultimate_dissolution()

		var free_timer: SceneTreeTimer = get_tree().create_timer(2.4, true, false, true)
		free_timer.timeout.connect(func():
			if is_instance_valid(enemy):
				enemy.queue_free()
		)
	)

## --- SCENE 09: ZENITH COMPRESSION & BREATHLESS SILENCE (31.5s - 33.5s) ---
## Emotional Purpose: "Everything pauses before catastrophe."
## Camera: Camera stops moving! Close orbit on the glowing Knight in absolute silence.
func _enter_scene_09_zenith_compression() -> void:
	_current_scene = 9

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.10, 2.0, "ultimate_ascendance")

## --- SCENE 10: CATACLYSMIC RELEASE (33.5s - 37.0s) ---
## Emotional Purpose: "The release is overwhelming."
## Camera: Wide Impact shot framing 65m sky pillar and concentric shockwave.
func _enter_scene_10_cataclysmic_release() -> void:
	_current_scene = 10

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.45, 3.5, "ultimate_ascendance")

	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_climax()

	if _knight.camera_rig:
		_knight.camera_rig.apply_trauma(0.95)

	# Spawn Celestial Sky Pillar (65m tall)
	_spawn_celestial_sky_pillar()

	# Blender Custom VFX: Expanding Shockwave Ring Mesh
	if SHOCKWAVE_RING_SCENE:
		var shockwave_mesh: Node3D = SHOCKWAVE_RING_SCENE.instantiate() as Node3D
		if shockwave_mesh:
			_apply_shader_material_to_node(shockwave_mesh, ENERGY_RIBBON_SHADER, {
				"core_color": COLOR_VOID_CORE,
				"edge_color": COLOR_VOID_PRIMARY,
				"speed": 2.5,
				"fresnel_power": 1.5
			})
			var parent_node: Node = _knight.get_parent()
			if parent_node:
				parent_node.add_child(shockwave_mesh)
				shockwave_mesh.global_position = _knight.global_position
				shockwave_mesh.scale = Vector3(1.0, 1.0, 1.0)
				_temp_vfx_nodes.append(shockwave_mesh)
				
				var ring_tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				ring_tween.tween_property(shockwave_mesh, "scale", Vector3(40.0, 5.0, 40.0), 1.2)

	# Authoritative Lethal Damage applied directly to all targets
	for target in _targets:
		if is_instance_valid(target) and target is PlayerController:
			target.is_blocking = false
			target.block_active_duration = 999.0
			if target.health_component:
				target.health_component.is_invulnerable = false
				target.health_component.take_damage(99999.0, _knight)
			target.take_damage_complex(99999.0, _knight, PlayerController.AttackType.FINISHER, 1000.0)

## --- SCENE 11: ATMOSPHERIC AFTERMATH (37.0s - 40.0s) ---
## Emotional Purpose: "Witness the aftermath."
## Camera: Slow atmospheric drift across the quiet, scarred battlefield.
func _enter_scene_11_aftermath() -> void:
	_current_scene = 11

	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.80, 3.0, "ultimate_ascendance")

	_restore_environment_lighting(2.5)

	for node in _temp_vfx_nodes:
		if is_instance_valid(node) and node is GPUParticles3D:
			node.emitting = false

## --- SCENE 12: VICTORY & CONTROL RECOVERY (40.0s - 43.5s) ---
## Emotional Purpose: "The Knight dominates the scene."
## Camera: Heroic low-angle portrait shot. "PLAYER WINS" displayed.
func _enter_scene_12_victory() -> void:
	_current_scene = 12

	if _knight.combat_audio:
		_knight.combat_audio.play_ultimate_victory()

	var hud: CombatHUD = _find_combat_hud()
	if hud:
		hud.show_announcement("CATACLYSM OF THE SEVENTH OATH", 3.0)

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

	# Restore time scale unconditionally
	if is_inside_tree():
		var ctc: Node = get_node_or_null("/root/CombatTimeController")
		if ctc and ctc.has_method("force_restore_normal_time"):
			ctc.force_restore_normal_time()

	# Restore player state, controls, and invulnerability
	if is_instance_valid(_knight):
		if _knight.health_component:
			_knight.health_component.is_invulnerable = false
		_knight.force_restore_player_control()

	# Restore environment and lighting
	_restore_environment_lighting(0.4)

	# Restore camera
	if _camera and is_instance_valid(_camera):
		var tween: Tween = create_tween()
		tween.tween_property(_camera, "fov", _orig_cam_fov, 0.4)
		tween.parallel().tween_property(_camera, "transform", _base_cam_transform, 0.4)

	# Cleanup temporary VFX nodes
	for node in _temp_vfx_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_temp_vfx_nodes.clear()

	queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		if _is_active:
			force_cleanup_ultimate()

## --- CAMERA DIRECTOR (12 MOTIVATED SHOTS: CLOSE -> MED -> WIDE -> CLOSE -> WIDE -> CLOSE) ---
func _update_camera_director(real_delta: float) -> void:
	if not _camera or not is_instance_valid(_camera):
		return

	# Shot 01: Extreme Close-Up on Helmet & Grip (0.0s - 3.5s)
	if _sequence_time < 3.5:
		var factor: float = clampf(_sequence_time / 3.5, 0.0, 1.0)
		_camera.fov = lerpf(_orig_cam_fov, 48.0, factor)
		_camera.h_offset = lerpf(0.0, 0.12, factor)
		_camera.v_offset = lerpf(0.0, -0.08, factor)
	# Shot 02: Low-Angle Side Profile (3.5s - 6.8s)
	elif _sequence_time < 6.8:
		var p: float = (_sequence_time - 3.5) / 3.3
		_camera.fov = lerpf(48.0, 52.0, p)
		_camera.h_offset = lerpf(0.12, -0.30, p)
		_camera.v_offset = lerpf(-0.08, -0.22, p)
	# Shot 03: Medium Orbiting Hero Shot (6.8s - 11.0s)
	elif _sequence_time < 11.0:
		var p: float = (_sequence_time - 6.8) / 4.2
		var angle: float = p * 0.65
		_camera.fov = 60.0
		_camera.h_offset = sin(angle) * 0.45
		_camera.v_offset = cos(angle) * 0.15
	# Shot 04: Wide Low-Angle Sky Reveal (11.0s - 15.5s)
	elif _sequence_time < 15.5:
		var p: float = (_sequence_time - 11.0) / 4.5
		_camera.fov = lerpf(60.0, 75.0, p)
		_camera.h_offset = 0.0
		_camera.v_offset = lerpf(0.15, -0.38, p)
	# Shot 05: Medium Vertical Sword Ascension Track (15.5s - 20.0s)
	elif _sequence_time < 20.0:
		var p: float = (_sequence_time - 15.5) / 4.5
		_camera.fov = 55.0
		_camera.h_offset = lerpf(0.0, 0.18, p)
		_camera.v_offset = lerpf(-0.38, 0.32, p)
	# Shot 06: Extreme Wide 100m Fortress Panoramic (20.0s - 24.5s)
	elif _sequence_time < 24.5:
		var p: float = (_sequence_time - 20.0) / 4.5
		_camera.fov = lerpf(55.0, 85.0, p)
		_camera.h_offset = 0.0
		_camera.v_offset = lerpf(0.32, 0.60, p)
	# Shot 07: Tight Close-Up on Enemy Terror (24.5s - 27.5s)
	elif _sequence_time < 27.5:
		var p: float = (_sequence_time - 24.5) / 3.0
		_camera.fov = lerpf(85.0, 46.0, p)
		_camera.h_offset = lerpf(0.0, -0.42, p)
		_camera.v_offset = 0.0
	# Shot 08: Medium Staggered Dissolution (27.5s - 31.5s)
	elif _sequence_time < 31.5:
		_camera.fov = 56.0
		_camera.h_offset = -0.18
		_camera.v_offset = 0.05
	# Shot 09: Still Close Zenith Orbit (31.5s - 33.5s) -> Camera stops moving!
	elif _sequence_time < 33.5:
		_camera.fov = 50.0
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0
	# Shot 10: Wide Impact Cataclysm (33.5s - 37.0s)
	elif _sequence_time < 37.0:
		var p: float = (_sequence_time - 33.5) / 3.5
		_camera.fov = lerpf(80.0, 72.0, p)
		_camera.h_offset = 0.0
		_camera.v_offset = 0.10
	# Shot 11: Slow Drifting Aftermath (37.0s - 40.0s)
	elif _sequence_time < 40.0:
		var p: float = (_sequence_time - 37.0) / 3.0
		_camera.fov = lerpf(72.0, 65.0, p)
		_camera.h_offset = lerpf(0.0, 0.22, p)
		_camera.v_offset = 0.0
	# Shot 12: Hero Victory Portrait (40.0s - 43.5s)
	else:
		var p: float = clampf((_sequence_time - 40.0) / 3.5, 0.0, 1.0)
		_camera.fov = lerpf(65.0, 50.0, p)
		_camera.h_offset = lerpf(0.22, 0.0, p)
		_camera.v_offset = lerpf(0.0, -0.05, p)

## --- CELESTIAL SKY PILLAR ---
func _spawn_celestial_sky_pillar() -> void:
	_sky_pillar_instance = MeshInstance3D.new()
	_sky_pillar_instance.name = "CelestialSkyPillar"

	var cyl_mesh: CylinderMesh = CylinderMesh.new()
	cyl_mesh.top_radius = 3.5
	cyl_mesh.bottom_radius = 1.4
	cyl_mesh.height = 65.0

	var smat: ShaderMaterial = ShaderMaterial.new()
	smat.shader = ENERGY_RIBBON_SHADER
	smat.set_shader_parameter("core_color", COLOR_VOID_CORE)
	smat.set_shader_parameter("edge_color", COLOR_VOID_PRIMARY)
	smat.set_shader_parameter("speed", 3.0)
	cyl_mesh.material = smat
	_sky_pillar_instance.mesh = cyl_mesh

	var parent_node: Node = _knight.get_parent()
	if parent_node:
		parent_node.add_child(_sky_pillar_instance)
		_sky_pillar_instance.global_position = _knight.global_position + Vector3(0, 30.0, 0)
		_temp_vfx_nodes.append(_sky_pillar_instance)

		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_sky_pillar_instance, "scale:x", 3.5, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_sky_pillar_instance, "scale:z", 3.5, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(smat, "shader_parameter/edge_color:a", 0.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

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
	pmat.scale_min = 0.12
	pmat.scale_max = 0.32
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

func _find_combat_hud() -> CombatHUD:
	var root: Node = get_tree().root
	var hud = root.find_child("CombatHUD", true, false)
	return hud as CombatHUD

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
