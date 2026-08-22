class_name TestDummy
extends StaticBody3D

## TestDummy — Combat target for testing weapon hitboxes, damage, and feedback.

@onready var health_component: HealthComponent = $HealthComponent
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D

var _respawn_timer: float = 0.0
var _is_dead: bool = false
var _orig_material: StandardMaterial3D = null

func _ready() -> void:
	if mesh_instance and mesh_instance.material_override:
		_orig_material = mesh_instance.material_override as StandardMaterial3D
	elif mesh_instance and mesh_instance.get_surface_override_material(0):
		_orig_material = mesh_instance.get_surface_override_material(0) as StandardMaterial3D

	if health_component:
		health_component.max_health = 150.0
		health_component.initialize(150.0)
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
		_update_label()

func take_damage(amount: float, attacker: Node = null) -> float:
	if _is_dead:
		return 0.0

	var dmg: float = health_component.take_damage(amount, attacker)
	_flash_white()
	_update_label()
	return dmg

func _on_health_changed(_curr: float, _max: float) -> void:
	_update_label()

func _update_label() -> void:
	if label_3d and health_component:
		label_3d.text = "TRAINING DUMMY\n%.0f / %.0f HP" % [health_component.current_health, health_component.max_health]

func _on_died() -> void:
	_is_dead = true
	if label_3d:
		label_3d.text = "DUMMY DESTROYED\nRespawning..."
	
	# Collapse visual
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance, "rotation:x", deg_to_rad(90.0), 0.3)
	tween.parallel().tween_property(mesh_instance, "position:y", 0.3, 0.3)

	await get_tree().create_timer(2.0).timeout
	_respawn()

func _respawn() -> void:
	_is_dead = false
	if health_component:
		health_component.initialize(150.0)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance, "rotation:x", 0.0, 0.4)
	tween.parallel().tween_property(mesh_instance, "position:y", 1.0, 0.4)
	_update_label()

func _flash_white() -> void:
	if mesh_instance:
		var flash_mat: StandardMaterial3D = StandardMaterial3D.new()
		flash_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_instance.material_override = flash_mat
		await get_tree().create_timer(0.08).timeout
		mesh_instance.material_override = _orig_material
