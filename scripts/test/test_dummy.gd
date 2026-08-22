class_name TestDummy
extends StaticBody3D

## TestDummy — Combat target for testing light/heavy/charged attacks, poise stagger, knockdowns, and finishers.

@onready var health_component: HealthComponent = $HealthComponent
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D

var _respawn_timer: float = 0.0
var _is_dead: bool = false
var _orig_material: StandardMaterial3D = null
var is_finisher_vulnerable: bool = false
var poise: float = 40.0
var max_poise: float = 40.0

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

func take_damage_complex(amount: float, attacker: Node = null, atk_type: int = 0, poise_dmg: float = 12.0) -> float:
	if _is_dead:
		return 0.0

	poise -= poise_dmg
	var dmg: float = health_component.take_damage(amount, attacker)
	_flash_white()

	if not _is_dead:
		if atk_type == 3: # CHARGED_KNOCKDOWN
			_trigger_knockdown()
		elif poise <= 0.0:
			_trigger_stagger()

	_update_label()
	return dmg

func take_damage(amount: float, attacker: Node = null) -> float:
	return take_damage_complex(amount, attacker, 0, 12.0)

func _trigger_stagger() -> void:
	is_finisher_vulnerable = true
	var tween: Tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance, "rotation:x", deg_to_rad(-20.0), 0.15)
	tween.tween_property(mesh_instance, "rotation:x", 0.0, 0.4)
	await get_tree().create_timer(1.2).timeout
	poise = max_poise
	is_finisher_vulnerable = false
	_update_label()

func _trigger_knockdown() -> void:
	is_finisher_vulnerable = true
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance, "rotation:x", deg_to_rad(-90.0), 0.25)
	tween.parallel().tween_property(mesh_instance, "position:y", 0.4, 0.25)
	await get_tree().create_timer(1.5).timeout
	var getup: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	getup.tween_property(mesh_instance, "rotation:x", 0.0, 0.4)
	getup.parallel().tween_property(mesh_instance, "position:y", 1.0, 0.4)
	poise = max_poise
	is_finisher_vulnerable = false
	_update_label()

func _on_health_changed(_curr: float, _max: float) -> void:
	_update_label()

func _update_label() -> void:
	if label_3d and health_component:
		var status_str: String = ""
		if is_finisher_vulnerable:
			status_str = " [VULNERABLE (Press F)]"
		label_3d.text = "TRAINING DUMMY\n%.0f / %.0f HP | Poise: %.0f%s" % [health_component.current_health, health_component.max_health, maxf(0.0, poise), status_str]

func _on_died() -> void:
	_is_dead = true
	is_finisher_vulnerable = false
	if label_3d:
		label_3d.text = "DUMMY DESTROYED\nRespawning..."
	
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance, "rotation:x", deg_to_rad(90.0), 0.3)
	tween.parallel().tween_property(mesh_instance, "position:y", 0.3, 0.3)

	await get_tree().create_timer(2.0).timeout
	_respawn()

func _respawn() -> void:
	_is_dead = false
	poise = max_poise
	is_finisher_vulnerable = false
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
