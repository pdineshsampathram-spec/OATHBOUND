class_name PlayerController
extends CharacterBody3D

## PlayerController — Primary player body handling inputs, physics, combat interactions, and visual animations.

@export var character_data: CharacterData = null

@onready var visual_pivot: Node3D = $VisualPivot
@onready var character_mesh: MeshInstance3D = $VisualPivot/CharacterMesh
@onready var sword_pivot: Node3D = $VisualPivot/SwordPivot
@onready var sword_hitbox: Area3D = $VisualPivot/SwordPivot/SwordHitbox
@onready var sword_collision: CollisionShape3D = $VisualPivot/SwordPivot/SwordHitbox/CollisionShape3D
@onready var shield_mesh: MeshInstance3D = $VisualPivot/ShieldMesh
@onready var camera_rig: CameraRig = $CameraRig
@onready var state_machine: StateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent

var gravity: float = 24.0
var is_dead: bool = false
var is_blocking: bool = false
var _attack_tween: Tween = null
var _dodge_tween: Tween = null
var _hit_targets_this_swing: Array[Node] = []

func _ready() -> void:
	if not character_data:
		character_data = preload("res://resources/characters/default_fighter.tres")

	if health_component and character_data:
		health_component.initialize(character_data.max_health)
		health_component.died.connect(_on_death)

	if stamina_component and character_data:
		stamina_component.initialize(
			character_data.max_stamina,
			character_data.stamina_regen_rate,
			character_data.stamina_regen_delay
		)

	if sword_hitbox:
		sword_hitbox.monitoring = false
		sword_hitbox.area_entered.connect(_on_sword_hitbox_area_entered)
		sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)

func _on_death() -> void:
	is_dead = true
	if state_machine:
		state_machine.transition_to("DeadState")

func take_damage(amount: float, attacker: Node = null) -> float:
	if is_dead:
		return 0.0

	var final_damage: float = amount

	# Check Block defense
	if is_blocking and character_data:
		if stamina_component and stamina_component.has_enough(character_data.block_stamina_drain_per_hit):
			stamina_component.consume(character_data.block_stamina_drain_per_hit)
			final_damage = amount * (1.0 - character_data.block_damage_reduction)
			_flash_shield()
		else:
			# Guard break - full damage taken
			if stamina_component:
				stamina_component.consume(stamina_component.current_stamina)

	var damage_dealt: float = 0.0
	if health_component:
		damage_dealt = health_component.take_damage(final_damage, attacker)

	if damage_dealt > 0.0:
		_flash_hit()

	return damage_dealt

# --- Input Queries ---

func get_movement_input() -> Vector2:
	if is_dead:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")

func is_sprinting_held() -> bool:
	if is_dead:
		return false
	return Input.is_action_pressed("sprint")

func wants_attack() -> bool:
	if is_dead:
		return false
	return Input.is_action_just_pressed("attack")

func wants_block() -> bool:
	if is_dead:
		return false
	return Input.is_action_pressed("block")

func wants_dodge() -> bool:
	if is_dead:
		return false
	return Input.is_action_just_pressed("dodge")

# --- Stamina Checks ---

func has_stamina_for_attack() -> bool:
	return stamina_component and character_data and stamina_component.has_enough(character_data.attack_stamina_cost)

func has_stamina_for_dodge() -> bool:
	return stamina_component and character_data and stamina_component.has_enough(character_data.dodge_stamina_cost)

func has_stamina_for_sprint() -> bool:
	return stamina_component and stamina_component.current_stamina > 2.0

# --- Movement & Physics Helpers ---

func get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if not camera_rig:
		return Vector3(input_vector.x, 0.0, input_vector.y).normalized()

	var cam_forward: Vector3 = camera_rig.get_camera_forward()
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()

	var cam_right: Vector3 = camera_rig.get_camera_right()
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	return (cam_right * input_vector.x + cam_forward * -input_vector.y).normalized()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

func apply_movement(direction: Vector3, speed: float, delta: float) -> void:
	var target_vel_x: float = direction.x * speed
	var target_vel_z: float = direction.z * speed
	var accel: float = character_data.acceleration if character_data else 12.0

	velocity.x = move_toward(velocity.x, target_vel_x, accel * delta)
	velocity.z = move_toward(velocity.z, target_vel_z, accel * delta)

func apply_deceleration(delta: float, custom_rate: float = -1.0) -> void:
	var decel: float = custom_rate if custom_rate > 0.0 else (character_data.deceleration if character_data else 14.0)
	velocity.x = move_toward(velocity.x, 0.0, decel * delta)
	velocity.z = move_toward(velocity.z, 0.0, decel * delta)

func rotate_towards_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001 or not visual_pivot:
		return

	var target_angle: float = atan2(-direction.x, -direction.z)
	var rot_speed: float = character_data.rotation_speed if character_data else 12.0
	visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_angle, rot_speed * delta)

# --- Hitbox & Combat Actions ---

func set_sword_hitbox_active(active: bool) -> void:
	if sword_hitbox:
		sword_hitbox.monitoring = active
	if active:
		_hit_targets_this_swing.clear()

func _on_sword_hitbox_area_entered(area: Area3D) -> void:
	var target: Node = area.get_parent()
	_try_deal_damage(target)

func _on_sword_hitbox_body_entered(body: Node) -> void:
	_try_deal_damage(body)

func _try_deal_damage(target: Node) -> void:
	if not target or target == self or _hit_targets_this_swing.has(target):
		return

	_hit_targets_this_swing.append(target)
	var dmg: float = character_data.attack_damage if character_data else 15.0

	if target.has_method("take_damage"):
		target.take_damage(dmg, self)
	elif target.has_node("HealthComponent"):
		var hc: HealthComponent = target.get_node("HealthComponent") as HealthComponent
		if hc:
			hc.take_damage(dmg, self)

# --- Visual Procedural Feedback / Animations ---

func play_attack_animation() -> void:
	if not sword_pivot:
		return

	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()

	_attack_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Windup -> Slash -> Recovery
	_attack_tween.tween_property(sword_pivot, "rotation:y", deg_to_rad(65.0), 0.12)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:z", deg_to_rad(20.0), 0.12)
	_attack_tween.tween_property(sword_pivot, "rotation:y", deg_to_rad(-85.0), 0.18)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:z", deg_to_rad(-15.0), 0.18)
	_attack_tween.tween_property(sword_pivot, "rotation:y", 0.0, 0.25)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:z", 0.0, 0.25)

func play_dodge_animation() -> void:
	if not visual_pivot:
		return

	if _dodge_tween and _dodge_tween.is_valid():
		_dodge_tween.kill()

	_dodge_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_dodge_tween.tween_property(visual_pivot, "rotation:x", deg_to_rad(-360.0), character_data.dodge_duration)
	_dodge_tween.tween_callback(func(): visual_pivot.rotation.x = 0.0)

func set_guard_visual(active: bool) -> void:
	if shield_mesh:
		var target_z: float = -0.4 if active else -0.2
		var target_rot_y: float = deg_to_rad(-15.0) if active else 0.0
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shield_mesh, "position:z", target_z, 0.15)
		tween.parallel().tween_property(shield_mesh, "rotation:y", target_rot_y, 0.15)

func play_death_animation() -> void:
	if visual_pivot:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_pivot, "rotation:x", deg_to_rad(90.0), 0.4)
		tween.parallel().tween_property(visual_pivot, "position:y", -0.7, 0.4)

func _flash_hit() -> void:
	if character_mesh and character_mesh.material_override:
		var mat: StandardMaterial3D = character_mesh.material_override as StandardMaterial3D
		if mat:
			var orig_color: Color = mat.albedo_color
			mat.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
			await get_tree().create_timer(0.08).timeout
			if mat:
				mat.albedo_color = orig_color

func _flash_shield() -> void:
	if shield_mesh and shield_mesh.material_override:
		var mat: StandardMaterial3D = shield_mesh.material_override as StandardMaterial3D
		if mat:
			var orig_color: Color = mat.albedo_color
			mat.albedo_color = Color(0.3, 0.7, 1.0, 1.0)
			await get_tree().create_timer(0.08).timeout
			if mat:
				mat.albedo_color = orig_color
