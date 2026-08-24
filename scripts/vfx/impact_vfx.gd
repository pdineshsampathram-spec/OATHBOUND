class_name ImpactVFX
extends Node3D

## ImpactVFX — High-performance procedural GPU particle effects for physical combat impacts,
## parry sparks, dodge dust, and blood feedback.

static func spawn_hit_sparks(parent: Node, global_pos: Vector3, is_heavy: bool = false) -> void:
	if not parent: return
	var particles: GPUParticles3D = GPUParticles3D.new()
	parent.add_child(particles)
	particles.top_level = true
	particles.global_position = global_pos
	particles.amount = 20 if is_heavy else 10
	particles.lifetime = 0.2
	particles.one_shot = true
	particles.explosiveness = 0.95

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 4.0
	pmat.initial_velocity_max = 8.0 if is_heavy else 6.0
	pmat.gravity = Vector3(0, -9.8, 0)
	pmat.scale_min = 0.04
	pmat.scale_max = 0.08
	pmat.color = Color(1.0, 0.75, 0.2, 1.0) # Bright orange/yellow spark
	particles.process_material = pmat

	var draw_mesh: SphereMesh = SphereMesh.new()
	draw_mesh.radius = 0.03
	draw_mesh.height = 0.06
	var dmat: StandardMaterial3D = StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(1.0, 0.8, 0.3, 1.0)
	draw_mesh.material = dmat
	particles.draw_pass_1 = draw_mesh

	particles.emitting = true

	# Auto free after emitting
	if parent.is_inside_tree():
		var timer: SceneTreeTimer = parent.get_tree().create_timer(0.35)
		timer.timeout.connect(particles.queue_free)

static func spawn_parry_flash(parent: Node, global_pos: Vector3) -> void:
	if not parent or not parent.is_inside_tree(): return

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.top_level = true
	particles.amount = 25
	particles.lifetime = 0.15
	particles.one_shot = true
	particles.explosiveness = 1.0

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 7.0
	pmat.initial_velocity_max = 12.0
	pmat.gravity = Vector3(0, -5.0, 0)
	pmat.scale_min = 0.05
	pmat.scale_max = 0.12
	pmat.color = Color(0.4, 0.8, 1.0, 1.0) # Electric blue/white deflection spark
	particles.process_material = pmat

	var draw_mesh: BoxMesh = BoxMesh.new()
	draw_mesh.size = Vector3(0.04, 0.04, 0.04)
	var dmat: StandardMaterial3D = StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(0.6, 0.9, 1.0, 1.0)
	draw_mesh.material = dmat
	particles.draw_pass_1 = draw_mesh

	parent.add_child(particles)
	particles.global_position = global_pos
	particles.emitting = true

	var timer: SceneTreeTimer = parent.get_tree().create_timer(0.25)
	timer.timeout.connect(particles.queue_free)

static func spawn_dodge_dust(parent: Node, global_pos: Vector3) -> void:
	if not parent or not parent.is_inside_tree(): return

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.top_level = true
	particles.amount = 8
	particles.lifetime = 0.35
	particles.one_shot = true
	particles.explosiveness = 0.8

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 120.0
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 2.5
	pmat.gravity = Vector3(0, -1.0, 0)
	pmat.scale_min = 0.08
	pmat.scale_max = 0.2
	pmat.color = Color(0.55, 0.48, 0.38, 0.6)
	particles.process_material = pmat

	var draw_mesh: BoxMesh = BoxMesh.new()
	draw_mesh.size = Vector3(0.06, 0.06, 0.06)
	var dmat: StandardMaterial3D = StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(0.6, 0.52, 0.42, 0.7)
	draw_mesh.material = dmat
	particles.draw_pass_1 = draw_mesh

	parent.add_child(particles)
	particles.global_position = global_pos
	particles.emitting = true

	var timer: SceneTreeTimer = parent.get_tree().create_timer(0.4)
	timer.timeout.connect(particles.queue_free)
