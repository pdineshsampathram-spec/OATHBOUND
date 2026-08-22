class_name PlayerController
extends CharacterBody3D

## PlayerController — Server-authoritative multiplayer combat controller.
## Server owns damage, hits, stamina, health, poise, parries, abilities, and combat state transitions.
## Reuses identical controller logic across all 3 archetypes (Knight, Berserker, Shadow Warrior).

enum AttackType { LIGHT, HEAVY, CHARGED, CHARGED_KNOCKDOWN, FINISHER }

@export var character_data: CharacterData = null

@onready var visual_pivot: Node3D = $VisualPivot
@onready var character_mesh: MeshInstance3D = $VisualPivot/CharacterMesh
@onready var shield_mesh: MeshInstance3D = $VisualPivot/ShieldMesh
@onready var left_hand_pivot: Node3D = $VisualPivot/LeftHandPivot
@onready var sword_pivot: Node3D = $VisualPivot/SwordPivot
@onready var sword_mesh: MeshInstance3D = $VisualPivot/SwordPivot/SwordMesh
@onready var axe_mesh: MeshInstance3D = $VisualPivot/SwordPivot/AxeMesh
@onready var dagger_mesh: MeshInstance3D = $VisualPivot/SwordPivot/DaggerMesh
@onready var sword_hitbox: Area3D = $VisualPivot/SwordPivot/SwordHitbox
@onready var sword_collision: CollisionShape3D = $VisualPivot/SwordPivot/SwordHitbox/CollisionShape3D
@onready var shockwave_mesh: MeshInstance3D = $VisualPivot/ShockwaveMesh
@onready var camera_rig: CameraRig = $CameraRig
@onready var state_machine: StateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

# Network Synchronized Variables (Server -> Clients)
@export var sync_position: Vector3 = Vector3.ZERO
@export var sync_velocity: Vector3 = Vector3.ZERO
@export var sync_rotation_y: float = 0.0
@export var sync_health: float = 120.0
@export var sync_stamina: float = 100.0
@export var sync_poise: float = 65.0
@export var sync_is_blocking: bool = false
@export var sync_is_dead: bool = false
@export var sync_state_name: String = "IdleState"
@export var sync_character_class: String = "Knight"

var peer_id: int = 1
var is_local_player: bool = true
var is_server_authority: bool = true

var gravity: float = 24.0
var is_dead: bool = false
var is_blocking: bool = false
var is_finisher_vulnerable: bool = false
var is_parry_empowered: bool = false
var block_active_duration: float = 999.0

# Poise & Ability system
var current_poise: float = 65.0
var _poise_regen_timer: float = 0.0
var ability_cooldown_remaining: float = 0.0

# Combat strike data
var current_attack_type: AttackType = AttackType.LIGHT
var current_charge_ratio: float = 0.0

# Server-side input caches from client RPCs
var network_move_input: Vector2 = Vector2.ZERO
var network_is_sprinting: bool = false
var network_wants_attack: bool = false
var network_attack_held: bool = false
var network_wants_heavy: bool = false
var network_wants_charged: bool = false
var network_wants_block: bool = false
var network_wants_dodge: bool = false
var network_wants_finisher: bool = false
var network_wants_ability: bool = false
var network_dodge_dir: Vector3 = Vector3.ZERO

# Local input tracking for charge/heavy detection
var _local_attack_press_time: float = 0.0
var _local_attack_held: bool = false

var _attack_tween: Tween = null
var _dodge_tween: Tween = null
var _reaction_tween: Tween = null
var _charge_tween: Tween = null
var _hit_targets_this_swing: Array[Node] = []
var _last_synced_state: String = ""
var _last_synced_class: String = ""

func _enter_tree() -> void:
	if name.is_valid_int():
		peer_id = name.to_int()
		set_multiplayer_authority(peer_id)

func _ready() -> void:
	if not character_data:
		_load_character_by_name(sync_character_class)

	var is_mp_active: bool = multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	if is_mp_active:
		is_local_player = (multiplayer.get_unique_id() == peer_id)
		is_server_authority = multiplayer.is_server()
	else:
		is_local_player = true
		is_server_authority = true

	if camera_rig:
		camera_rig.setup_authority(is_local_player)

	_apply_character_data()

	if sword_hitbox:
		sword_hitbox.monitoring = false
		if is_server_authority:
			sword_hitbox.area_entered.connect(_on_sword_hitbox_area_entered)
			sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)

	sync_position = global_position
	sync_rotation_y = visual_pivot.rotation.y

func set_character_data(data: CharacterData) -> void:
	character_data = data
	if character_data:
		sync_character_class = character_data.character_name
	_apply_character_data()

func _load_character_by_name(c_name: String) -> void:
	match c_name.to_lower():
		"berserker":
			character_data = preload("res://resources/characters/berserker.tres")
		"shadow warrior", "shadow_warrior", "phantom":
			character_data = preload("res://resources/characters/shadow_warrior.tres")
		_:
			character_data = preload("res://resources/characters/knight.tres")

func _apply_character_data() -> void:
	if not character_data:
		return

	sync_character_class = character_data.character_name

	if health_component:
		health_component.initialize(character_data.max_health)
		health_component.died.connect(_on_death)
		health_component.health_changed.connect(_on_health_changed)
		sync_health = character_data.max_health

	if stamina_component:
		stamina_component.initialize(
			character_data.max_stamina,
			character_data.stamina_regen_rate,
			character_data.stamina_regen_delay
		)
		stamina_component.stamina_changed.connect(_on_stamina_changed)
		sync_stamina = character_data.max_stamina

	current_poise = character_data.max_poise
	sync_poise = current_poise

	_configure_visual_archetype()

func _configure_visual_archetype() -> void:
	if not character_data or not visual_pivot:
		return

	# Material Colors
	if character_mesh:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = character_data.primary_color
		mat.metallic = 0.5
		mat.roughness = 0.4
		character_mesh.material_override = mat

	# Weapon Style Switching
	match character_data.weapon_style:
		CharacterData.WeaponStyle.SWORD_SHIELD: # Knight
			if shield_mesh: shield_mesh.visible = true
			if left_hand_pivot: left_hand_pivot.visible = false
			if sword_mesh: sword_mesh.visible = true
			if axe_mesh: axe_mesh.visible = false
			if dagger_mesh: dagger_mesh.visible = false

		CharacterData.WeaponStyle.GREAT_AXE: # Berserker
			if shield_mesh: shield_mesh.visible = false
			if left_hand_pivot: left_hand_pivot.visible = false
			if sword_mesh: sword_mesh.visible = false
			if axe_mesh: axe_mesh.visible = true
			if dagger_mesh: dagger_mesh.visible = false

		CharacterData.WeaponStyle.DUAL_BLADES: # Shadow Warrior
			if shield_mesh: shield_mesh.visible = false
			if left_hand_pivot: left_hand_pivot.visible = true
			if sword_mesh: sword_mesh.visible = false
			if axe_mesh: axe_mesh.visible = false
			if dagger_mesh: dagger_mesh.visible = true

func _physics_process(delta: float) -> void:
	if ability_cooldown_remaining > 0.0:
		ability_cooldown_remaining = maxf(0.0, ability_cooldown_remaining - delta)

	if is_server_authority:
		_process_poise_regen(delta)

		sync_position = global_position
		sync_velocity = velocity
		sync_rotation_y = visual_pivot.rotation.y
		sync_is_blocking = is_blocking
		sync_is_dead = is_dead
		sync_poise = current_poise
		if state_machine:
			sync_state_name = state_machine.get_current_state_name()
	else:
		if is_local_player:
			_send_client_inputs(delta)
		else:
			global_position = global_position.lerp(sync_position, 18.0 * delta)
			visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, sync_rotation_y, 18.0 * delta)

		if sync_character_class != _last_synced_class:
			_load_character_by_name(sync_character_class)
			_apply_character_data()
			_last_synced_class = sync_character_class

		if sync_state_name != _last_synced_state:
			_on_remote_state_changed(_last_synced_state, sync_state_name)
			_last_synced_state = sync_state_name

		if is_blocking != sync_is_blocking:
			is_blocking = sync_is_blocking
			set_guard_visual(is_blocking)

func _process_poise_regen(delta: float) -> void:
	if character_data and current_poise < character_data.max_poise:
		_poise_regen_timer += delta
		if _poise_regen_timer >= character_data.poise_regen_delay:
			current_poise = minf(character_data.max_poise, current_poise + character_data.poise_regen_rate * delta)

func restore_full_poise() -> void:
	if character_data:
		current_poise = character_data.max_poise

func start_ability_cooldown(cooldown: float) -> void:
	ability_cooldown_remaining = cooldown

func can_use_ability() -> bool:
	return ability_cooldown_remaining <= 0.0 and stamina_component and character_data and stamina_component.has_enough(character_data.ability_stamina_cost)

func _on_health_changed(curr: float, _max_hp: float) -> void:
	sync_health = curr

func _on_stamina_changed(curr: float, _max_stm: float) -> void:
	sync_stamina = curr

func _on_death() -> void:
	is_dead = true
	sync_is_dead = true
	if state_machine:
		state_machine.transition_to("DeadState")

# --- Client Input Transmission ---

func _send_client_inputs(delta: float) -> void:
	if is_dead:
		return

	var move_in: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var is_sprint: bool = Input.is_action_pressed("sprint")
	
	var cam_dir: Vector3 = Vector3.ZERO
	if move_in.length_squared() > 0.01 and camera_rig:
		cam_dir = get_camera_relative_direction(move_in)

	rpc_id(1, "server_receive_movement", move_in, cam_dir, is_sprint)

	if Input.is_action_just_pressed("attack"):
		_local_attack_held = true
		_local_attack_press_time = 0.0
		rpc_id(1, "server_receive_attack_press", true)

	if _local_attack_held and character_data:
		_local_attack_press_time += delta
		if _local_attack_press_time >= character_data.charged_attack_min_charge:
			rpc_id(1, "server_receive_charged_attack")

	if Input.is_action_just_released("attack") and character_data:
		_local_attack_held = false
		rpc_id(1, "server_receive_attack_press", false)
		if _local_attack_press_time < 0.25:
			rpc_id(1, "server_receive_attack")
		elif _local_attack_press_time >= 0.25 and _local_attack_press_time < character_data.charged_attack_min_charge:
			rpc_id(1, "server_receive_heavy_attack")

	if Input.is_action_just_pressed("heavy_attack"):
		rpc_id(1, "server_receive_heavy_attack")

	var wants_blk: bool = Input.is_action_pressed("block")
	if wants_blk != is_blocking:
		rpc_id(1, "server_receive_block", wants_blk)

	if Input.is_action_just_pressed("dodge"):
		var d_dir: Vector3 = cam_dir if cam_dir.length_squared() > 0.01 else -visual_pivot.global_transform.basis.z.normalized()
		rpc_id(1, "server_receive_dodge", d_dir)

	if Input.is_action_just_pressed("finisher"):
		rpc_id(1, "server_receive_finisher")

	if Input.is_action_just_pressed("ability"):
		rpc_id(1, "server_receive_ability")

# --- Server RPC Receivers ---

@rpc("any_peer", "call_remote", "unreliable")
func server_receive_movement(move_input: Vector2, _cam_relative_dir: Vector3, is_sprint: bool) -> void:
	if not is_server_authority or is_dead:
		return
	network_move_input = move_input
	network_is_sprinting = is_sprint

@rpc("any_peer", "call_remote", "reliable")
func server_receive_attack() -> void:
	if not is_server_authority or is_dead:
		return
	network_wants_attack = true

@rpc("any_peer", "call_remote", "reliable")
func server_receive_attack_press(pressed: bool) -> void:
	if not is_server_authority or is_dead:
		return
	network_attack_held = pressed

@rpc("any_peer", "call_remote", "reliable")
func server_receive_heavy_attack() -> void:
	if not is_server_authority or is_dead:
		return
	network_wants_heavy = true

@rpc("any_peer", "call_remote", "reliable")
func server_receive_charged_attack() -> void:
	if not is_server_authority or is_dead:
		return
	network_wants_charged = true

@rpc("any_peer", "call_remote", "reliable")
func server_receive_block(blocking_active: bool) -> void:
	if not is_server_authority or is_dead:
		return
	network_wants_block = blocking_active

@rpc("any_peer", "call_remote", "reliable")
func server_receive_dodge(direction: Vector3) -> void:
	if not is_server_authority or is_dead:
		return
	network_wants_dodge = true
	network_dodge_dir = direction

@rpc("any_peer", "call_remote", "reliable")
func server_receive_finisher() -> void:
	if not is_server_authority or is_dead:
		return
	network_wants_finisher = true

@rpc("any_peer", "call_remote", "reliable")
func server_receive_ability() -> void:
	if not is_server_authority or is_dead:
		return
	network_wants_ability = true

# --- State Machine Input Query Helpers (Server-side) ---

func get_movement_input() -> Vector2:
	if is_dead:
		return Vector2.ZERO
	if is_local_player and is_server_authority:
		return Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return network_move_input

func is_sprinting_held() -> bool:
	if is_dead:
		return false
	if is_local_player and is_server_authority:
		return Input.is_action_pressed("sprint")
	return network_is_sprinting

func wants_attack() -> bool:
	if is_dead:
		return false
	if is_local_player and is_server_authority:
		return Input.is_action_just_pressed("attack")
	var res: bool = network_wants_attack
	network_wants_attack = false
	return res

func is_attack_held() -> bool:
	if is_local_player and is_server_authority:
		return Input.is_action_pressed("attack")
	return network_attack_held

func wants_heavy_attack() -> bool:
	if is_dead:
		return false
	if is_local_player and is_server_authority:
		return Input.is_action_just_pressed("heavy_attack")
	var res: bool = network_wants_heavy
	network_wants_heavy = false
	return res

func wants_charged_attack() -> bool:
	if is_dead:
		return false
	var res: bool = network_wants_charged
	network_wants_charged = false
	return res

func wants_block() -> bool:
	if is_dead:
		return false
	if is_local_player and is_server_authority:
		return Input.is_action_pressed("block")
	return network_wants_block

func wants_dodge() -> bool:
	if is_dead:
		return false
	if is_local_player and is_server_authority:
		return Input.is_action_just_pressed("dodge")
	var res: bool = network_wants_dodge
	network_wants_dodge = false
	return res

func wants_finisher() -> bool:
	if is_dead:
		return false
	if is_local_player and is_server_authority:
		return Input.is_action_just_pressed("finisher")
	var res: bool = network_wants_finisher
	network_wants_finisher = false
	return res

func wants_ability() -> bool:
	if is_dead or not can_use_ability():
		return false
	if is_local_player and is_server_authority:
		return Input.is_action_just_pressed("ability")
	var res: bool = network_wants_ability
	network_wants_ability = false
	return res

# --- Stamina Checks ---

func has_stamina_for_attack() -> bool:
	return is_parry_empowered or (stamina_component and character_data and stamina_component.has_enough(character_data.attack_stamina_cost))

func has_stamina_for_heavy() -> bool:
	return stamina_component and character_data and stamina_component.has_enough(character_data.heavy_attack_stamina_cost)

func has_stamina_for_charged() -> bool:
	return stamina_component and character_data and stamina_component.has_enough(character_data.charged_attack_stamina_cost)

func has_stamina_for_dodge() -> bool:
	return stamina_component and character_data and stamina_component.has_enough(character_data.dodge_stamina_cost)

func has_stamina_for_sprint() -> bool:
	return stamina_component and stamina_component.current_stamina > 2.0

# --- Movement & Physics Helpers ---

func get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if is_local_player and camera_rig:
		var cam_forward: Vector3 = camera_rig.get_camera_forward()
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()

		var cam_right: Vector3 = camera_rig.get_camera_right()
		cam_right.y = 0.0
		cam_right = cam_right.normalized()

		return (cam_right * input_vector.x + cam_forward * -input_vector.y).normalized()
	return Vector3(input_vector.x, 0.0, input_vector.y).normalized()

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

# --- Finisher Target Evaluation ---

func find_nearby_finisher_target() -> Node:
	var arena_root: Node = get_parent()
	if not arena_root:
		return null

	var closest: Node = null
	var min_dist: float = character_data.finisher_range if character_data else 2.5

	for peer_node in arena_root.get_children():
		if peer_node == self:
			continue
		if peer_node is PlayerController:
			var p: PlayerController = peer_node as PlayerController
			if p.is_dead:
				continue
			var dist: float = global_position.distance_to(p.global_position)
			if dist <= min_dist:
				var is_crit_hp: bool = (p.health_component and p.health_component.current_health <= (p.character_data.max_health * character_data.finisher_health_threshold))
				if p.is_finisher_vulnerable or is_crit_hp:
					closest = p
					min_dist = dist
		elif peer_node.name.to_lower().contains("dummy"):
			var dist: float = global_position.distance_to(peer_node.global_position)
			if dist <= min_dist:
				closest = peer_node
				min_dist = dist

	return closest

# --- Hitbox & Server-Authoritative Damage ---

func set_sword_hitbox_active(active: bool) -> void:
	if sword_hitbox and is_server_authority:
		sword_hitbox.monitoring = active
	if active:
		_hit_targets_this_swing.clear()

func _on_sword_hitbox_area_entered(area: Area3D) -> void:
	if not is_server_authority:
		return
	var target: Node = area.get_parent()
	_try_deal_damage(target)

func _on_sword_hitbox_body_entered(body: Node) -> void:
	if not is_server_authority:
		return
	_try_deal_damage(body)

func _try_deal_damage(target: Node) -> void:
	if not target or target == self or _hit_targets_this_swing.has(target):
		return

	_hit_targets_this_swing.append(target)

	var base_dmg: float = character_data.attack_damage
	var poise_dmg: float = character_data.light_attack_poise_damage

	match current_attack_type:
		AttackType.LIGHT:
			if is_parry_empowered:
				base_dmg *= 1.5
				poise_dmg *= 1.5
		AttackType.HEAVY:
			base_dmg = character_data.heavy_attack_damage
			poise_dmg = character_data.heavy_attack_poise_damage
		AttackType.CHARGED, AttackType.CHARGED_KNOCKDOWN:
			base_dmg = lerpf(character_data.charged_attack_damage_min, character_data.charged_attack_damage_max, current_charge_ratio)
			poise_dmg = lerpf(character_data.light_attack_poise_damage, character_data.charged_attack_poise_damage_max, current_charge_ratio)

	if target.has_method("take_damage_complex"):
		target.take_damage_complex(base_dmg, self, current_attack_type, poise_dmg)
	elif target.has_method("take_damage"):
		target.take_damage(base_dmg, self)
	elif target.has_node("HealthComponent"):
		var hc: HealthComponent = target.get_node("HealthComponent") as HealthComponent
		if hc:
			hc.take_damage(base_dmg, self)

func take_damage_complex(amount: float, attacker: Node = null, atk_type: AttackType = AttackType.LIGHT, poise_dmg: float = 12.0) -> float:
	if is_dead:
		return 0.0

	if is_blocking and block_active_duration <= character_data.parry_window:
		rpc("rpc_flash_parry")
		if state_machine:
			state_machine.transition_to("ParryState")
		if attacker and attacker.has_method("trigger_stun"):
			attacker.trigger_stun()
		return 0.0

	var final_damage: float = amount
	_poise_regen_timer = 0.0

	if is_blocking and character_data:
		if stamina_component and stamina_component.has_enough(character_data.block_stamina_drain_per_hit):
			stamina_component.consume(character_data.block_stamina_drain_per_hit)
			final_damage = amount * (1.0 - character_data.block_damage_reduction)
			current_poise -= poise_dmg * 0.3
			rpc("rpc_flash_shield")
		else:
			if stamina_component:
				stamina_component.consume(stamina_component.current_stamina)
			current_poise = 0.0
	else:
		current_poise -= poise_dmg

	var damage_dealt: float = 0.0
	if health_component:
		damage_dealt = health_component.take_damage(final_damage, attacker)

	if damage_dealt > 0.0:
		rpc("rpc_flash_hit")

	if not is_dead and state_machine:
		if atk_type == AttackType.CHARGED_KNOCKDOWN:
			state_machine.transition_to("KnockedDownState")
		elif current_poise <= 0.0:
			state_machine.transition_to("StaggeredState")

	return damage_dealt

func take_damage(amount: float, attacker: Node = null) -> float:
	return take_damage_complex(amount, attacker, AttackType.LIGHT, 12.0)

func trigger_stun() -> void:
	if state_machine and not is_dead:
		state_machine.transition_to("StunnedState")

# --- Procedural Visual Animations & RPCs ---

func play_attack_animation() -> void:
	if not sword_pivot:
		return
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()

	_attack_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(sword_pivot, "rotation:y", deg_to_rad(65.0), 0.1)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:z", deg_to_rad(20.0), 0.1)
	_attack_tween.tween_property(sword_pivot, "rotation:y", deg_to_rad(-85.0), 0.15)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:z", deg_to_rad(-15.0), 0.15)
	_attack_tween.tween_property(sword_pivot, "rotation:y", 0.0, 0.2)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:z", 0.0, 0.2)

	# Left dagger swing for dual blades
	if left_hand_pivot and left_hand_pivot.visible:
		var l_tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		l_tween.tween_property(left_hand_pivot, "rotation:y", deg_to_rad(-65.0), 0.1)
		l_tween.tween_property(left_hand_pivot, "rotation:y", deg_to_rad(75.0), 0.15)
		l_tween.tween_property(left_hand_pivot, "rotation:y", 0.0, 0.2)

func play_heavy_attack_animation() -> void:
	if not sword_pivot:
		return
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()

	_attack_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(sword_pivot, "rotation:x", deg_to_rad(-90.0), 0.28)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:y", deg_to_rad(45.0), 0.28)
	_attack_tween.tween_property(sword_pivot, "rotation:x", deg_to_rad(45.0), 0.22)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:y", deg_to_rad(-60.0), 0.22)
	_attack_tween.tween_property(sword_pivot, "rotation:x", 0.0, 0.35)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:y", 0.0, 0.35)

func play_charge_buildup_animation() -> void:
	if not sword_pivot:
		return
	if _charge_tween and _charge_tween.is_valid():
		_charge_tween.kill()

	_charge_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_charge_tween.tween_property(sword_pivot, "rotation:y", deg_to_rad(110.0), 0.4)
	_charge_tween.parallel().tween_property(sword_pivot, "rotation:z", deg_to_rad(35.0), 0.4)
	_charge_tween.parallel().tween_property(visual_pivot, "scale", Vector3(1.08, 1.08, 1.08), 0.4)

func play_charged_attack_release_animation(_ratio: float) -> void:
	stop_charge_visual()
	if not sword_pivot:
		return
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()

	_attack_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(sword_pivot, "rotation:y", deg_to_rad(-120.0), 0.2)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:z", deg_to_rad(-30.0), 0.2)
	_attack_tween.tween_property(sword_pivot, "rotation:y", 0.0, 0.4)
	_attack_tween.parallel().tween_property(sword_pivot, "rotation:z", 0.0, 0.4)

func stop_charge_visual() -> void:
	if _charge_tween and _charge_tween.is_valid():
		_charge_tween.kill()
	if visual_pivot:
		visual_pivot.scale = Vector3.ONE

func play_parry_success_animation() -> void:
	if shield_mesh and shield_mesh.visible:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(shield_mesh, "position:z", -0.6, 0.1)
		tween.tween_property(shield_mesh, "position:z", -0.2, 0.25)
	elif sword_pivot:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sword_pivot, "rotation:x", deg_to_rad(-45.0), 0.1)
		tween.tween_property(sword_pivot, "rotation:x", 0.0, 0.25)

func play_dodge_animation() -> void:
	if not visual_pivot:
		return
	if _dodge_tween and _dodge_tween.is_valid():
		_dodge_tween.kill()

	_dodge_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_dodge_tween.tween_property(visual_pivot, "rotation:x", deg_to_rad(-360.0), character_data.dodge_duration if character_data else 0.4)
	_dodge_tween.tween_callback(func(): visual_pivot.rotation.x = 0.0)

func set_guard_visual(active: bool) -> void:
	if shield_mesh and shield_mesh.visible:
		var target_z: float = -0.4 if active else -0.2
		var target_rot_y: float = deg_to_rad(-15.0) if active else 0.0
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shield_mesh, "position:z", target_z, 0.15)
		tween.parallel().tween_property(shield_mesh, "rotation:y", target_rot_y, 0.15)
	elif sword_pivot:
		var target_rot_z: float = deg_to_rad(-45.0) if active else 0.0
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sword_pivot, "rotation:z", target_rot_z, 0.15)

func play_stagger_animation() -> void:
	if not visual_pivot:
		return
	if _reaction_tween and _reaction_tween.is_valid():
		_reaction_tween.kill()

	_reaction_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_reaction_tween.tween_property(visual_pivot, "rotation:x", deg_to_rad(-25.0), 0.15)
	_reaction_tween.parallel().tween_property(visual_pivot, "rotation:y", deg_to_rad(20.0), 0.15)
	_reaction_tween.tween_property(visual_pivot, "rotation:x", 0.0, 0.4)
	_reaction_tween.parallel().tween_property(visual_pivot, "rotation:y", 0.0, 0.4)

func play_stun_animation() -> void:
	if not visual_pivot:
		return
	if _reaction_tween and _reaction_tween.is_valid():
		_reaction_tween.kill()

	_reaction_tween = create_tween().set_loops(3).set_trans(Tween.TRANS_SINE)
	_reaction_tween.tween_property(visual_pivot, "rotation:z", deg_to_rad(10.0), 0.1)
	_reaction_tween.tween_property(visual_pivot, "rotation:z", deg_to_rad(-10.0), 0.1)
	_reaction_tween.chain().tween_property(visual_pivot, "rotation:z", 0.0, 0.1)

func play_knockdown_animation() -> void:
	if visual_pivot:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_pivot, "rotation:x", deg_to_rad(-90.0), 0.3)
		tween.parallel().tween_property(visual_pivot, "position:y", -0.7, 0.3)

func play_get_up_animation() -> void:
	if visual_pivot:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_pivot, "rotation:x", 0.0, 0.5)
		tween.parallel().tween_property(visual_pivot, "position:y", 0.0, 0.5)

func reset_knockdown_visual() -> void:
	if visual_pivot:
		visual_pivot.rotation.x = 0.0
		visual_pivot.position.y = 0.0

func play_finisher_animation() -> void:
	if not sword_pivot:
		return
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_pivot, "position:y", 0.8, 0.3)
	tween.parallel().tween_property(sword_pivot, "rotation:x", deg_to_rad(-110.0), 0.3)
	tween.tween_property(visual_pivot, "position:y", 0.0, 0.25)
	tween.parallel().tween_property(sword_pivot, "rotation:x", deg_to_rad(60.0), 0.25)
	tween.tween_property(sword_pivot, "rotation:x", 0.0, 0.5)

# --- Ability Animations ---

func play_dash_strike_animation() -> void:
	if visual_pivot:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_pivot, "rotation:x", deg_to_rad(25.0), 0.15)
		tween.tween_property(visual_pivot, "rotation:x", 0.0, 0.3)
	if shield_mesh and shield_mesh.visible:
		var s_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		s_tween.tween_property(shield_mesh, "position:z", -0.7, 0.15)
		s_tween.tween_property(shield_mesh, "position:z", -0.2, 0.3)

func play_ground_breaker_animation() -> void:
	if sword_pivot:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(sword_pivot, "rotation:x", deg_to_rad(-120.0), 0.3)
		tween.tween_property(sword_pivot, "rotation:x", deg_to_rad(60.0), 0.15)
		tween.tween_property(sword_pivot, "rotation:x", 0.0, 0.3)

func play_shadow_step_animation() -> void:
	if character_mesh:
		var mat: StandardMaterial3D = character_mesh.material_override as StandardMaterial3D
		if mat:
			var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
			tween.tween_property(mat, "albedo_color:a", 0.15, 0.15)
			tween.tween_property(mat, "albedo_color:a", 1.0, 0.2)

func stop_ability_visuals() -> void:
	if shockwave_mesh:
		shockwave_mesh.visible = false

@rpc("call_local", "unreliable")
func rpc_trigger_shockwave_vfx() -> void:
	if shockwave_mesh:
		shockwave_mesh.visible = true
		shockwave_mesh.scale = Vector3(0.1, 1.0, 0.1)
		var tween: Tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(shockwave_mesh, "scale", Vector3(1.2, 1.0, 1.2), 0.4)
		tween.tween_callback(func(): shockwave_mesh.visible = false)

func play_death_animation() -> void:
	if visual_pivot:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_pivot, "rotation:x", deg_to_rad(90.0), 0.4)
		tween.parallel().tween_property(visual_pivot, "position:y", -0.7, 0.4)

func _on_remote_state_changed(_prev: String, current: String) -> void:
	match current:
		"LightAttackState":
			play_attack_animation()
		"HeavyAttackState":
			play_heavy_attack_animation()
		"ChargedAttackState":
			play_charge_buildup_animation()
		"ParryState":
			play_parry_success_animation()
		"DodgeState":
			play_dodge_animation()
		"StaggeredState":
			play_stagger_animation()
		"StunnedState":
			play_stun_animation()
		"KnockedDownState":
			play_knockdown_animation()
		"FinisherState":
			play_finisher_animation()
		"AbilityState":
			if character_data:
				match character_data.ability_style:
					CharacterData.AbilityStyle.DASH_STRIKE: play_dash_strike_animation()
					CharacterData.AbilityStyle.RADIAL_AOE: play_ground_breaker_animation()
					CharacterData.AbilityStyle.TELEPORT_STRIKE: play_shadow_step_animation()
		"DeadState":
			play_death_animation()

@rpc("call_local", "unreliable")
func rpc_flash_hit() -> void:
	if character_mesh and character_mesh.material_override:
		var mat: StandardMaterial3D = character_mesh.material_override as StandardMaterial3D
		if mat:
			var orig_color: Color = mat.albedo_color
			mat.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
			await get_tree().create_timer(0.08).timeout
			if mat:
				mat.albedo_color = orig_color

@rpc("call_local", "unreliable")
func rpc_flash_shield() -> void:
	if shield_mesh and shield_mesh.material_override:
		var mat: StandardMaterial3D = shield_mesh.material_override as StandardMaterial3D
		if mat:
			var orig_color: Color = mat.albedo_color
			mat.albedo_color = Color(0.3, 0.7, 1.0, 1.0)
			await get_tree().create_timer(0.08).timeout
			if mat:
				mat.albedo_color = orig_color

@rpc("call_local", "unreliable")
func rpc_flash_parry() -> void:
	if character_mesh and character_mesh.material_override:
		var mat: StandardMaterial3D = character_mesh.material_override as StandardMaterial3D
		if mat:
			var orig_color: Color = mat.albedo_color
			mat.albedo_color = Color(1.0, 0.9, 0.2, 1.0)
			await get_tree().create_timer(0.15).timeout
			if mat:
				mat.albedo_color = orig_color
