class_name PowerVFXSystem
extends Node

## PowerVFXSystem — High-end supernatural visual effects system for OATHBOUND.
## Implements dark violet / astral energy language, particle trails, layered shockwaves,
## and the 8-phase cinematic ultimate sequence.

const COLOR_VOID_PRIMARY: Color = Color(0.45, 0.12, 0.95, 1.0)      # Vivid Void Violet
const COLOR_VOID_CORE: Color = Color(0.85, 0.70, 1.0, 1.0)         # Ethereal White-Violet Core
const COLOR_VOID_SMOKE: Color = Color(0.18, 0.04, 0.35, 0.6)       # Dark Shadow Haze
const COLOR_GOLD_DIVINE: Color = Color(1.0, 0.82, 0.35, 1.0)       # Sacred Gold
const COLOR_BLOOD_RAGE: Color = Color(0.9, 0.15, 0.15, 1.0)        # Crimson Blood Rage

## Spawn a multi-layered supernatural shockwave on ground
static func spawn_supernatural_shockwave(parent: Node, global_pos: Vector3, color: Color = COLOR_VOID_PRIMARY, radius: float = 5.0) -> void:
	if not parent or not parent.is_inside_tree():
		return

	var root: Node3D = Node3D.new()
	parent.add_child(root)
	root.global_position = global_pos

	# 1. Expanding energy ring particles
	var ring_particles: GPUParticles3D = GPUParticles3D.new()
	ring_particles.amount = 40
	ring_particles.lifetime = 0.45
	ring_particles.one_shot = true
	ring_particles.explosiveness = 0.92
	
	var r_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	r_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	r_mat.emission_ring_radius = 0.5
	r_mat.emission_ring_inner_radius = 0.2
	r_mat.emission_ring_axis = Vector3(0, 1, 0)
	r_mat.direction = Vector3(0, 0.1, 0)
	r_mat.spread = 20.0
	r_mat.initial_velocity_min = radius * 2.2
	r_mat.initial_velocity_max = radius * 3.0
	r_mat.damping_min = 6.0
	r_mat.damping_max = 10.0
	r_mat.gravity = Vector3(0, -1.0, 0)
	r_mat.scale_min = 0.12
	r_mat.scale_max = 0.28
	r_mat.color = color
	ring_particles.process_material = r_mat

	var r_mesh: QuadMesh = QuadMesh.new()
	r_mesh.size = Vector2(0.2, 0.2)
	var d_mat: StandardMaterial3D = StandardMaterial3D.new()
	d_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	d_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d_mat.albedo_color = color
	d_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	r_mesh.material = d_mat
	ring_particles.draw_pass_1 = r_mesh

	root.add_child(ring_particles)
	ring_particles.emitting = true

	# 2. Upward energy embers
	var ember_particles: GPUParticles3D = GPUParticles3D.new()
	ember_particles.amount = 25
	ember_particles.lifetime = 0.6
	ember_particles.one_shot = true
	ember_particles.explosiveness = 0.85

	var e_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	e_mat.direction = Vector3(0, 1, 0)
	e_mat.spread = 45.0
	e_mat.initial_velocity_min = 3.0
	e_mat.initial_velocity_max = 7.0
	e_mat.gravity = Vector3(0, -4.0, 0)
	e_mat.scale_min = 0.05
	e_mat.scale_max = 0.15
	e_mat.color = COLOR_VOID_CORE
	ember_particles.process_material = e_mat

	var e_mesh: QuadMesh = QuadMesh.new()
	e_mesh.size = Vector2(0.1, 0.1)
	e_mesh.material = d_mat
	ember_particles.draw_pass_1 = e_mesh

	root.add_child(ember_particles)
	ember_particles.emitting = true

	# Cleanup
	var timer: SceneTreeTimer = parent.get_tree().create_timer(0.8)
	timer.timeout.connect(root.queue_free)

## Spawn an ethereal dark aura around a character
static func spawn_character_aura(target_node: Node3D, color: Color = COLOR_VOID_PRIMARY, duration: float = 3.0) -> Node3D:
	if not target_node or not target_node.is_inside_tree():
		return null

	var aura_root: Node3D = Node3D.new()
	aura_root.name = "SupernaturalAura"
	target_node.add_child(aura_root)
	aura_root.position = Vector3(0, 0.9, 0)

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.amount = 30
	particles.lifetime = 0.8
	particles.explosiveness = 0.1

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_radius = 0.6
	pmat.emission_ring_height = 1.4
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 15.0
	pmat.initial_velocity_min = 0.8
	pmat.initial_velocity_max = 2.0
	pmat.gravity = Vector3(0, 1.5, 0)
	pmat.scale_min = 0.1
	pmat.scale_max = 0.25
	pmat.color = color
	particles.process_material = pmat

	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.2, 0.2)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mesh.material = mat
	particles.draw_pass_1 = mesh

	aura_root.add_child(particles)
	particles.emitting = true

	if duration > 0.0:
		var timer: SceneTreeTimer = target_node.get_tree().create_timer(duration)
		timer.timeout.connect(func():
			if is_instance_valid(particles):
				particles.emitting = false
			if is_instance_valid(aura_root):
				var cleanup_timer: SceneTreeTimer = target_node.get_tree().create_timer(1.0)
				cleanup_timer.timeout.connect(aura_root.queue_free)
		)

	return aura_root

## Execute the full 8-phase cinematic ultimate sequence
static func execute_cinematic_ultimate(attacker: PlayerController, target_pos: Vector3, on_complete: Callable = Callable()) -> void:
	if not attacker or not attacker.is_inside_tree():
		return

	var tree: SceneTree = attacker.get_tree()
	var ctc: Node = tree.root.get_node_or_null("CombatTimeController")

	# --- Phase 1: Activation & Focus ---
	if ctc and ctc.has_method("trigger_slowmo"):
		ctc.trigger_slowmo(0.3, 2.5, "ultimate_activation")

	if attacker.camera_rig:
		attacker.camera_rig.apply_trauma(0.4)

	# --- Phase 2: Aura Gathering ---
	var aura: Node3D = spawn_character_aura(attacker, COLOR_VOID_PRIMARY, 2.8)

	# --- Phase 3: Energy Accumulation Inward Particles ---
	var accum_particles: GPUParticles3D = GPUParticles3D.new()
	accum_particles.amount = 50
	accum_particles.lifetime = 0.7
	accum_particles.one_shot = false

	var acc_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	acc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	acc_mat.emission_sphere_radius = 3.5
	acc_mat.gravity = Vector3.ZERO
	acc_mat.radial_accel_min = -8.0
	acc_mat.radial_accel_max = -12.0
	acc_mat.scale_min = 0.08
	acc_mat.scale_max = 0.2
	acc_mat.color = COLOR_VOID_CORE
	accum_particles.process_material = acc_mat

	var acc_mesh: QuadMesh = QuadMesh.new()
	acc_mesh.size = Vector2(0.15, 0.15)
	var q_mat: StandardMaterial3D = StandardMaterial3D.new()
	q_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q_mat.albedo_color = COLOR_VOID_CORE
	q_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	acc_mesh.material = q_mat
	accum_particles.draw_pass_1 = acc_mesh

	attacker.add_child(accum_particles)
	accum_particles.position = Vector3(0, 1.2, 0)
	accum_particles.emitting = true

	# --- Phase 4: Skyward Sword Raise ---
	attacker._play_skeletal_animation("heavy_attack", 0.08)

	# --- Phase 5: Battlefield Envelopment (T+0.8s) ---
	var t5: SceneTreeTimer = tree.create_timer(0.8)
	t5.timeout.connect(func():
		if not is_instance_valid(attacker): return
		spawn_supernatural_shockwave(attacker.get_parent(), attacker.global_position, COLOR_VOID_PRIMARY, 8.0)
		if attacker.combat_audio:
			attacker.combat_audio.play_sword_swing()
	)

	# --- Phase 6: Energy Peak & Impact Plunge (T+1.4s) ---
	var t6: SceneTreeTimer = tree.create_timer(1.4)
	t6.timeout.connect(func():
		if not is_instance_valid(attacker): return
		attacker._play_skeletal_animation("charged_attack", 0.05)
		spawn_supernatural_shockwave(attacker.get_parent(), target_pos, COLOR_VOID_CORE, 10.0)
		if attacker.camera_rig:
			attacker.camera_rig.apply_trauma(0.8)
		if attacker.combat_audio:
			attacker.combat_audio.play_weapon_impact(true)
	)

	# --- Phase 7: Enemy Dissolution & Cleanup (T+2.0s) ---
	var t7: SceneTreeTimer = tree.create_timer(2.0)
	t7.timeout.connect(func():
		if is_instance_valid(accum_particles):
			accum_particles.emitting = false
			accum_particles.queue_free()
	)

	# --- Phase 8: Victory Moment & Time Restoration (T+2.6s) ---
	var t8: SceneTreeTimer = tree.create_timer(2.6)
	t8.timeout.connect(func():
		if ctc and ctc.has_method("force_restore_normal_time"):
			ctc.force_restore_normal_time()
		if on_complete.is_valid():
			on_complete.call()
	)
