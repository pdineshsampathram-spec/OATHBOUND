class_name PlayerController
extends CharacterBody3D

const PowerVFXSystem = preload("res://scripts/vfx/power_vfx_system.gd")

## PlayerController — Server-authoritative multiplayer combat controller.
## Server owns damage, hits, stamina, health, poise, energy, abilities, and combat state transitions.
## Reuses identical controller logic across all 3 archetypes (Knight, Berserker, Shadow Warrior).

enum AttackType { LIGHT, HEAVY, CHARGED, CHARGED_KNOCKDOWN, FINISHER }

const CombatAudio = preload("res://scripts/audio/combat_audio.gd")
const ImpactVFX = preload("res://scripts/vfx/impact_vfx.gd")
const DamageNumber = preload("res://scripts/ui/damage_number.gd")

@export var character_data: CharacterData = null

@onready var visual_pivot: Node3D = $VisualPivot
@onready var character_mesh: MeshInstance3D = $VisualPivot.get_node_or_null("CharacterMesh")
@onready var knight_model: Node3D = $VisualPivot.get_node_or_null("KnightModel")
@onready var shield_mesh: Node3D = $VisualPivot.get_node_or_null("ShieldMesh")
@onready var left_hand_pivot: Node3D = $VisualPivot.get_node_or_null("LeftHandPivot")
@onready var sword_pivot: Node3D = $VisualPivot.get_node_or_null("SwordPivot")
@onready var sword_mesh: Node3D = $VisualPivot.get_node_or_null("SwordPivot/SwordMesh")
@onready var axe_mesh: Node3D = $VisualPivot.get_node_or_null("SwordPivot/AxeMesh")
@onready var dagger_mesh: Node3D = $VisualPivot.get_node_or_null("SwordPivot/DaggerMesh")
@onready var sword_hitbox: Area3D = $VisualPivot.get_node_or_null("SwordPivot/SwordHitbox")
@onready var sword_collision: CollisionShape3D = $VisualPivot.get_node_or_null("SwordPivot/SwordHitbox/CollisionShape3D")
@onready var shockwave_mesh: MeshInstance3D = $VisualPivot.get_node_or_null("ShockwaveMesh")
@onready var barrier_mesh: MeshInstance3D = $VisualPivot.get_node_or_null("BarrierMesh")
@onready var combat_audio: CombatAudio = $CombatAudio if has_node("CombatAudio") else null
@onready var camera_rig: CameraRig = $CameraRig
@onready var state_machine: StateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var ability_system: AbilitySystem = $AbilitySystem
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

var _anim_player: AnimationPlayer = null
var ai_controller: Node = null
@export var is_ai: bool = false

# Network Synchronized Variables (Server -> Clients)
@export var sync_position: Vector3 = Vector3.ZERO
@export var sync_velocity: Vector3 = Vector3.ZERO
@export var sync_rotation_y: float = 0.0
@export var sync_health: float = 120.0
@export var sync_stamina: float = 100.0
@export var sync_poise: float = 65.0
@export var sync_energy: float = 100.0
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

# Centralized Authoritative Player Control Locks
var player_input_locked: bool = false
var movement_locked: bool = false
var attack_locked: bool = false
var ability_locked: bool = false
var dodge_locked: bool = false

# Poise system
var current_poise: float = 65.0
var _poise_regen_timer: float = 0.0

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
var network_requested_ability_slot: int = -1
var network_dodge_dir: Vector3 = Vector3.ZERO

# Tunable Combat Parameters
@export var parry_window: float = 0.12
@export var dodge_iframes: float = 0.25
@export var combo_buffer_window: float = 0.30
@export var light_hitstop: float = 0.03
@export var heavy_hitstop: float = 0.07
@export var parry_hitstop: float = 0.08
@export var finisher_hitstop: float = 0.15

# Stance & Combo State
var is_combat_stance: bool = false
var _combat_stance_timer: float = 0.0
var combo_step: int = 1
var _combo_buffer_timer: float = 0.0

# Local input tracking for charge/heavy detection
var _local_attack_press_time: float = 0.0
var _local_attack_held: bool = false

# Swept Blade Trajectory Tracking
var _prev_blade_tip: Vector3 = Vector3.ZERO
var _prev_blade_base: Vector3 = Vector3.ZERO
var _is_sweeping_blade: bool = false

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
		is_local_player = (multiplayer.get_unique_id() == peer_id) and not is_ai and not name.begins_with("Enemy")
		is_server_authority = multiplayer.is_server()
	else:
		is_local_player = not is_ai and not name.begins_with("Enemy") and (name == "1" or name == "Player" or (get_parent() and get_parent().name == "Players"))
		is_server_authority = true

	if camera_rig:
		camera_rig.setup_authority(is_local_player)

	_apply_character_data()
	_attach_weapons_to_skeleton()

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

	if ability_system:
		ability_system.initialize(self, character_data)
		ability_system.energy_changed.connect(_on_energy_changed)
		sync_energy = character_data.max_energy

	current_poise = character_data.max_poise
	sync_poise = current_poise

	_configure_visual_archetype()
	_apply_hero_materials()

func _apply_hero_materials() -> void:
	if not knight_model:
		return
	var steel_mat: Material = preload("res://assets/materials/mat_knight_steel.tres")
	var leather_mat: Material = preload("res://assets/materials/mat_knight_leather.tres")
	var tabard_mat: Material = preload("res://assets/materials/mat_knight_tabard.tres")

	for child in knight_model.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = child as MeshInstance3D
		if mi and mi.mesh:
			for s in range(mi.mesh.get_surface_count()):
				var orig_mat: Material = mi.mesh.surface_get_material(s)
				var m_name: String = orig_mat.resource_name if orig_mat else ""
				if "Leather" in m_name:
					mi.set_surface_override_material(s, leather_mat)
				else:
					mi.set_surface_override_material(s, steel_mat)

func _attach_weapons_to_skeleton() -> void:
	if not knight_model:
		return
	var skel: Skeleton3D = knight_model.find_child("Skeleton3D", true, false) as Skeleton3D
	if not skel:
		for child in knight_model.get_children():
			if child is Skeleton3D:
				skel = child
				break
			elif child.get_node_or_null("Skeleton3D"):
				skel = child.get_node("Skeleton3D")
				break

	if not skel:
		return

	# Physically bind sword pivot to right hand bone
	var hand_idx: int = skel.find_bone("Hand.R")
	if hand_idx >= 0 and sword_pivot and sword_pivot.get_parent() != skel:
		var bone_attach: BoneAttachment3D = BoneAttachment3D.new()
		bone_attach.name = "BoneAttach_HandR"
		bone_attach.bone_name = "Hand.R"
		skel.add_child(bone_attach)
		sword_pivot.reparent(bone_attach)
		sword_pivot.position = Vector3(0, 0, 0)
		sword_pivot.rotation = Vector3.ZERO

	# Physically bind shield mesh to left forearm bone
	var forearm_idx: int = skel.find_bone("Forearm.L")
	if forearm_idx >= 0 and shield_mesh and shield_mesh.get_parent() != skel:
		var shield_attach: BoneAttachment3D = BoneAttachment3D.new()
		shield_attach.name = "BoneAttach_ForearmL"
		shield_attach.bone_name = "Forearm.L"
		skel.add_child(shield_attach)
		shield_mesh.reparent(shield_attach)
		shield_mesh.position = Vector3(0, 0, 0)
		shield_mesh.rotation = Vector3.ZERO

func _configure_visual_archetype() -> void:
	if not character_data or not visual_pivot:
		return

	if character_mesh:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = character_data.primary_color
		mat.metallic = 0.5
		mat.roughness = 0.4
		character_mesh.material_override = mat

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
	if _combat_stance_timer > 0.0:
		_combat_stance_timer -= delta
		if _combat_stance_timer <= 0.0:
			is_combat_stance = false

	if is_server_authority:
		_process_poise_regen(delta)
		_process_swept_blade_hits()

		sync_position = global_position
		sync_velocity = velocity
		sync_rotation_y = visual_pivot.rotation.y
		sync_is_blocking = is_blocking
		sync_is_dead = is_dead
		sync_poise = current_poise
		if ability_system:
			sync_energy = ability_system.current_energy
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

func _on_health_changed(curr: float, _max_hp: float) -> void:
	sync_health = curr

func _on_stamina_changed(curr: float, _max_stm: float) -> void:
	sync_stamina = curr

func _on_energy_changed(curr: float, _max_energy: float) -> void:
	sync_energy = curr

func _on_death() -> void:
	is_dead = true
	sync_is_dead = true
	if state_machine:
		state_machine.transition_to("DeadState")

# --- Authoritative Player Control Management ---

func force_restore_player_control() -> void:
	player_input_locked = false
	movement_locked = false
	attack_locked = false
	ability_locked = false
	dodge_locked = false
	
	network_move_input = Vector2.ZERO
	network_is_sprinting = false
	network_wants_attack = false
	network_attack_held = false
	network_wants_heavy = false
	network_wants_charged = false
	network_wants_block = false
	network_wants_dodge = false
	network_wants_finisher = false
	network_requested_ability_slot = -1
	_local_attack_held = false
	_local_attack_press_time = 0.0
	is_blocking = false
	block_active_duration = 999.0

	var ap: AnimationPlayer = _get_anim_player()
	if ap:
		ap.speed_scale = 1.0

	if not is_dead and state_machine:
		var curr_name: String = state_machine.get_current_state_name()
		if curr_name == "AbilityState" or curr_name == "UltimateCapturedState" or curr_name == "FinisherState":
			state_machine.transition_to("IdleState")

# --- Client Input Transmission ---

func _send_client_inputs(delta: float) -> void:
	if is_dead or player_input_locked:
		return

	var move_in: Vector2 = Vector2.ZERO
	if not movement_locked:
		move_in = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var is_sprint: bool = Input.is_action_pressed("sprint") if not movement_locked else false
	
	var cam_dir: Vector3 = Vector3.ZERO
	if move_in.length_squared() > 0.01 and camera_rig:
		cam_dir = get_camera_relative_direction(move_in)

	rpc_id(1, "server_receive_movement", move_in, cam_dir, is_sprint)

	if not attack_locked:
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

	var wants_blk: bool = Input.is_action_pressed("block") if not attack_locked else false
	if wants_blk != is_blocking:
		rpc_id(1, "server_receive_block", wants_blk)

	if not dodge_locked and Input.is_action_just_pressed("dodge"):
		var d_dir: Vector3 = cam_dir if cam_dir.length_squared() > 0.01 else -visual_pivot.global_transform.basis.z.normalized()
		rpc_id(1, "server_receive_dodge", d_dir)

	if Input.is_action_just_pressed("finisher"):
		rpc_id(1, "server_receive_finisher")

	# 4 Ability Slots
	if Input.is_action_just_pressed("ability_1"):
		rpc_id(1, "server_receive_ability_slot", 0)
	elif Input.is_action_just_pressed("ability_2"):
		rpc_id(1, "server_receive_ability_slot", 1)
	elif Input.is_action_just_pressed("ability_3") or Input.is_action_just_pressed("ability"):
		rpc_id(1, "server_receive_ability_slot", 2)
	elif Input.is_action_just_pressed("ultimate"):
		rpc_id(1, "server_receive_ability_slot", 3)

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
func server_receive_ability_slot(slot: int) -> void:
	if not is_server_authority or is_dead:
		return
	if ability_system and ability_system.can_cast(slot):
		network_requested_ability_slot = slot

# --- State Machine Input Query Helpers (Server-side) ---

func get_movement_input() -> Vector2:
	if is_dead or player_input_locked or movement_locked:
		return Vector2.ZERO
	if is_ai or ai_controller:
		if ai_controller and ai_controller.has_method("get_move_input"):
			return ai_controller.get_move_input()
		return Vector2.ZERO
	if is_local_player:
		return Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return network_move_input

func is_sprinting_held() -> bool:
	if is_dead or player_input_locked or movement_locked:
		return false
	if is_ai or ai_controller:
		if ai_controller and ai_controller.has_method("is_sprinting_held"):
			return ai_controller.is_sprinting_held()
		return false
	if is_local_player:
		return Input.is_action_pressed("sprint")
	return network_is_sprinting

func wants_attack() -> bool:
	if is_dead or player_input_locked or attack_locked:
		return false
	if is_ai or ai_controller:
		if ai_controller and ai_controller.has_method("wants_attack"):
			return ai_controller.wants_attack()
		return false
	if is_local_player:
		return Input.is_action_just_pressed("attack")
	var res: bool = network_wants_attack
	network_wants_attack = false
	return res

func is_attack_held() -> bool:
	if is_dead or player_input_locked or attack_locked:
		return false
	if is_ai or ai_controller:
		if ai_controller and ai_controller.has_method("wants_attack"):
			return ai_controller.wants_attack()
		return false
	if is_local_player:
		return Input.is_action_pressed("attack")
	return network_attack_held

func wants_heavy_attack() -> bool:
	if is_dead or player_input_locked or attack_locked:
		return false
	if is_ai or ai_controller:
		if ai_controller and ai_controller.has_method("wants_heavy_attack"):
			return ai_controller.wants_heavy_attack()
		return false
	if is_local_player:
		return Input.is_action_just_pressed("heavy_attack")
	var res: bool = network_wants_heavy
	network_wants_heavy = false
	return res

func wants_charged_attack() -> bool:
	if is_dead or player_input_locked or attack_locked:
		return false
	var res: bool = network_wants_charged
	network_wants_charged = false
	return res

func wants_block() -> bool:
	if is_dead or player_input_locked or attack_locked:
		return false
	if is_ai or ai_controller:
		if ai_controller and ai_controller.has_method("wants_block"):
			return ai_controller.wants_block()
		return false
	if is_local_player:
		return Input.is_action_pressed("block")
	return network_wants_block

func wants_dodge() -> bool:
	if is_dead or player_input_locked or dodge_locked:
		return false
	if is_ai or ai_controller:
		if ai_controller and ai_controller.has_method("wants_dodge"):
			return ai_controller.wants_dodge()
		return false
	if is_local_player:
		return Input.is_action_just_pressed("dodge")
	var res: bool = network_wants_dodge
	network_wants_dodge = false
	return res

func wants_finisher() -> bool:
	if is_dead or player_input_locked or attack_locked:
		return false
	if is_ai or ai_controller:
		if ai_controller and ai_controller.has_method("wants_finisher"):
			return ai_controller.wants_finisher()
		return false
	if is_local_player:
		return Input.is_action_just_pressed("finisher")
	var res: bool = network_wants_finisher
	network_wants_finisher = false
	return res

func get_requested_ability_slot() -> int:
	if is_dead or player_input_locked or ability_locked or not ability_system:
		return -1

	if is_local_player:
		if Input.is_action_just_pressed("ability_1") and ability_system.can_cast(0):
			return 0
		elif Input.is_action_just_pressed("ability_2") and ability_system.can_cast(1):
			return 1
		elif (Input.is_action_just_pressed("ability_3") or Input.is_action_just_pressed("ability")) and ability_system.can_cast(2):
			return 2
		elif Input.is_action_just_pressed("ultimate") and ability_system.can_cast(3):
			return 3
		return -1
	var res: int = network_requested_ability_slot
	network_requested_ability_slot = -1
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

	# State-dependent turning clamping
	if current_attack_type == AttackType.HEAVY and (_is_sweeping_blade or (sword_hitbox and sword_hitbox.monitoring)):
		rot_speed = 0.0 # Strictly committed / locked during heavy smash
	elif current_attack_type == AttackType.CHARGED and (_is_sweeping_blade or (sword_hitbox and sword_hitbox.monitoring)):
		rot_speed = 0.0 # Locked during charged lunge
	elif _is_sweeping_blade:
		rot_speed = minf(rot_speed, 2.5) # Restricted during light attack active frames
	elif is_combat_stance:
		rot_speed = minf(rot_speed, 7.5) # Controlled in combat stance

	if rot_speed > 0.0:
		visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_angle, rot_speed * delta)

func enter_combat_stance(duration: float = 4.0) -> void:
	is_combat_stance = true
	_combat_stance_timer = duration

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
		elif peer_node.name.to_lower().contains("dummy") or peer_node.name.to_lower().contains("pell"):
			var dist: float = global_position.distance_to(peer_node.global_position)
			if dist <= min_dist:
				closest = peer_node
				min_dist = dist

	return closest

# --- Swept Blade Trajectory & Server-Authoritative Damage ---

func set_sword_hitbox_active(active: bool) -> void:
	if sword_hitbox and is_server_authority:
		sword_hitbox.set_deferred("monitoring", active)
	_is_sweeping_blade = active
	if active:
		_hit_targets_this_swing.clear()
		_prev_blade_tip = _get_blade_tip_pos()
		_prev_blade_base = _get_blade_base_pos()

func _get_blade_tip_pos() -> Vector3:
	if sword_pivot:
		return sword_pivot.global_transform * Vector3(0, 0.9, -0.6)
	return global_position + Vector3(0, 1.2, -1.0)

func _get_blade_base_pos() -> Vector3:
	if sword_pivot:
		return sword_pivot.global_transform.origin
	return global_position + Vector3(0, 1.0, 0)

func _process_swept_blade_hits() -> void:
	if not _is_sweeping_blade or not is_server_authority:
		return
	var curr_tip: Vector3 = _get_blade_tip_pos()
	var curr_base: Vector3 = _get_blade_base_pos()

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space_state:
		var query_tip = PhysicsRayQueryParameters3D.create(_prev_blade_tip, curr_tip, 7, [self.get_rid()])
		var res_tip = space_state.intersect_ray(query_tip)
		if res_tip and res_tip.collider:
			_try_deal_damage(res_tip.collider)

		var query_diag = PhysicsRayQueryParameters3D.create(_prev_blade_base, curr_tip, 7, [self.get_rid()])
		var res_diag = space_state.intersect_ray(query_diag)
		if res_diag and res_diag.collider:
			_try_deal_damage(res_diag.collider)

	_prev_blade_tip = curr_tip
	_prev_blade_base = curr_base

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
			trigger_presentation_hitstop(light_hitstop)
		AttackType.HEAVY:
			base_dmg = character_data.heavy_attack_damage
			poise_dmg = character_data.heavy_attack_poise_damage
			trigger_presentation_hitstop(heavy_hitstop)
		AttackType.CHARGED, AttackType.CHARGED_KNOCKDOWN:
			base_dmg = lerpf(character_data.charged_attack_damage_min, character_data.charged_attack_damage_max, current_charge_ratio)
			poise_dmg = lerpf(character_data.light_attack_poise_damage, character_data.charged_attack_poise_damage_max, current_charge_ratio)
			trigger_presentation_hitstop(heavy_hitstop)
		AttackType.FINISHER:
			base_dmg = 999.0
			trigger_presentation_hitstop(finisher_hitstop)

	if ability_system:
		base_dmg *= ability_system.get_outgoing_damage_multiplier()

	if target.has_method("take_damage_complex"):
		target.take_damage_complex(base_dmg, self, current_attack_type, poise_dmg)
	elif target.has_method("take_damage"):
		target.take_damage(base_dmg, self)
	elif target.has_node("HealthComponent"):
		var hc: HealthComponent = target.get_node("HealthComponent") as HealthComponent
		if hc:
			hc.take_damage(base_dmg, self)

func trigger_presentation_hitstop(duration: float) -> void:
	if duration <= 0.001:
		return
	# Delegate to centralized CombatTimeController — no direct Engine.time_scale mutation
	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("trigger_hitstop"):
		ctc.trigger_hitstop(duration)
	# If CombatTimeController is not available (e.g. testing), do nothing rather than risk a leak

func take_damage_complex(amount: float, attacker: Node = null, atk_type: AttackType = AttackType.LIGHT, poise_dmg: float = 12.0) -> float:
	if is_dead:
		return 0.0

	if is_blocking and block_active_duration <= character_data.parry_window:
		rpc("rpc_flash_parry")
		rpc("rpc_spawn_combat_text", global_position + Vector3(0, 1.5, 0), "PARRIED!", Color(0.2, 0.85, 1.0))
		if state_machine:
			state_machine.transition_to("ParryState")
		if attacker and attacker.has_method("trigger_stun"):
			attacker.trigger_stun()
		var mm = get_tree().root.find_child("MatchManager", true, false)
		if mm and mm.has_method("record_parry"):
			mm.record_parry(peer_id)
		return 0.0

	var final_damage: float = amount
	_poise_regen_timer = 0.0

	# Holy guard buff reduction
	if ability_system:
		final_damage *= ability_system.get_incoming_damage_multiplier()

	if is_blocking and character_data:
		if stamina_component and stamina_component.has_enough(character_data.block_stamina_drain_per_hit):
			stamina_component.consume(character_data.block_stamina_drain_per_hit)
			final_damage = final_damage * (1.0 - character_data.block_damage_reduction)
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
		var is_heavy: bool = (atk_type == AttackType.HEAVY or atk_type == AttackType.CHARGED or atk_type == AttackType.CHARGED_KNOCKDOWN or atk_type == AttackType.FINISHER)
		var is_parry_ctr: bool = (attacker is PlayerController and attacker.is_parry_empowered)
		var is_fin: bool = (atk_type == AttackType.FINISHER)
		rpc("rpc_spawn_damage_number", global_position + Vector3(0, 1.3, 0), damage_dealt, is_heavy, is_parry_ctr, is_fin)
		var mm = get_tree().root.find_child("MatchManager", true, false)
		if mm and attacker is PlayerController and mm.has_method("record_damage"):
			mm.record_damage(attacker.peer_id, damage_dealt)

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

# --- Realistic Skeletal Animations & Audio/VFX Hooks ---

func _get_anim_player() -> AnimationPlayer:
	if _anim_player and is_instance_valid(_anim_player):
		return _anim_player
	if knight_model:
		_anim_player = knight_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	return _anim_player

func _play_skeletal_animation(anim_name: String, custom_blend: float = 0.15) -> void:
	var ap: AnimationPlayer = _get_anim_player()
	if ap and ap.has_animation(anim_name):
		ap.play(anim_name, custom_blend)

func play_attack_animation() -> void:
	enter_combat_stance()
	var anim_name: String = "light_attack_%d" % combo_step
	var ap: AnimationPlayer = _get_anim_player()
	if ap and ap.has_animation(anim_name):
		_play_skeletal_animation(anim_name, 0.08)
	else:
		_play_skeletal_animation("light_attack_1", 0.08)

	combo_step = (combo_step % 3) + 1

	if combat_audio: combat_audio.play_sword_swing()
	# Skeletal animation drives all body + weapon motion — no tween overrides

func play_heavy_attack_animation() -> void:
	enter_combat_stance()
	_play_skeletal_animation("heavy_attack", 0.10)
	if combat_audio: combat_audio.play_sword_swing()
	# Skeletal animation drives the full-body heavy attack — no tween overrides

func play_charge_buildup_animation() -> void:
	enter_combat_stance()
	# Play charged attack start — the skeletal animation handles the sword raise/coil
	var ap: AnimationPlayer = _get_anim_player()
	if ap and ap.has_animation("charged_attack"):
		ap.play("charged_attack", 0.1)
		ap.speed_scale = 0.3  # Slow the first half for charge buildup
	else:
		_play_skeletal_animation("combat_idle", 0.1)

func play_charged_attack_release_animation(_ratio: float) -> void:
	enter_combat_stance()
	_play_skeletal_animation("charged_attack", 0.08)
	if combat_audio: combat_audio.play_sword_swing()
	stop_charge_visual()
	# Restore animation speed for explosive release
	var ap: AnimationPlayer = _get_anim_player()
	if ap:
		ap.speed_scale = 1.0 + (_ratio * 0.3)  # Faster release at higher charge

func stop_charge_visual() -> void:
	# Restore animation speed if it was slowed for charge buildup
	var ap: AnimationPlayer = _get_anim_player()
	if ap:
		ap.speed_scale = 1.0

func play_block_animation() -> void:
	enter_combat_stance()
	_play_skeletal_animation("block", 0.1)

func play_block_impact_animation() -> void:
	_play_skeletal_animation("block_hit", 0.05)
	if combat_audio: combat_audio.play_shield_block()

func play_parry_success_animation() -> void:
	enter_combat_stance()
	_play_skeletal_animation("parry", 0.05)
	trigger_presentation_hitstop(parry_hitstop)
	ImpactVFX.spawn_parry_flash(self, global_position + Vector3(0, 1.2, 0.4))
	if combat_audio: combat_audio.play_parry()

	if shield_mesh and shield_mesh.visible:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(shield_mesh, "position:z", -0.45, 0.08)
		tween.tween_property(shield_mesh, "position:z", -0.15, 0.2)

func play_dodge_animation(dir: Vector3 = Vector3.ZERO) -> void:
	enter_combat_stance()
	# Use directional skeletal dodge animations — no barrel-roll tween
	var local_dir: Vector3 = visual_pivot.global_transform.basis.inverse() * dir
	if abs(local_dir.x) > abs(local_dir.z):
		if local_dir.x > 0: _play_skeletal_animation("dodge_r", 0.08)
		else: _play_skeletal_animation("dodge_l", 0.08)
	else:
		if local_dir.z > 0: _play_skeletal_animation("dodge_bwd", 0.08)
		else: _play_skeletal_animation("dodge_fwd", 0.08)

	ImpactVFX.spawn_dodge_dust(self, global_position)
	if combat_audio: combat_audio.play_dodge()

func play_hit_reaction_animation(incoming_dir: Vector3 = Vector3.ZERO) -> void:
	enter_combat_stance()
	# Directional skeletal hit reactions — no positional slide tween
	var local_dir: Vector3 = visual_pivot.global_transform.basis.inverse() * incoming_dir
	if abs(local_dir.x) > abs(local_dir.z):
		if local_dir.x > 0: _play_skeletal_animation("hit_react_right", 0.05)
		else: _play_skeletal_animation("hit_react_left", 0.05)
	else:
		if local_dir.z > 0: _play_skeletal_animation("hit_react_back", 0.05)
		else: _play_skeletal_animation("hit_react_front", 0.05)

	if combat_audio: combat_audio.play_flesh_hit()

func play_stagger_animation() -> void:
	enter_combat_stance()
	_play_skeletal_animation("stagger", 0.08)
	if combat_audio: combat_audio.play_armor_hit()

func play_knockdown_animation() -> void:
	enter_combat_stance()
	_play_skeletal_animation("knockdown", 0.1)
	if combat_audio: combat_audio.play_armor_hit()

func play_finisher_animation() -> void:
	enter_combat_stance()
	_play_skeletal_animation("finisher", 0.05)
	trigger_presentation_hitstop(finisher_hitstop)
	if combat_audio: combat_audio.play_sword_swing()

func set_guard_visual(active: bool) -> void:
	if active:
		_play_skeletal_animation("block")
	else:
		_play_skeletal_animation("idle")

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

func play_stun_animation() -> void:
	# Use stagger animation for stun — skeleton drives the dazed look
	_play_skeletal_animation("stagger", 0.08)

func play_get_up_animation() -> void:
	# Play combat_idle to smoothly get up from knockdown
	_play_skeletal_animation("combat_idle", 0.25)

func reset_knockdown_visual() -> void:
	pass  # Skeleton handles all visual reset — no manual pivot manipulation needed

# --- Ability Animations ---

func play_ability_cast_animation() -> void:
	# Use combat_idle with a subtle speed variation for casting feel
	_play_skeletal_animation("combat_idle", 0.1)

func play_dash_strike_animation() -> void:
	# Use heavy_attack animation for charged forward strikes
	_play_skeletal_animation("heavy_attack", 0.08)
	if combat_audio: combat_audio.play_sword_swing()

func play_ground_breaker_animation() -> void:
	# Use charged_attack animation for overhead ground slams
	_play_skeletal_animation("charged_attack", 0.08)
	if combat_audio: combat_audio.play_sword_swing()

func play_shadow_step_animation() -> void:
	if character_mesh and character_mesh.material_override:
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
	PowerVFXSystem.spawn_supernatural_shockwave(get_parent(), global_position, PowerVFXSystem.COLOR_VOID_PRIMARY, 6.0)

@rpc("call_local", "unreliable")
func rpc_trigger_buff_vfx(color: Color) -> void:
	PowerVFXSystem.spawn_character_aura(self, color, 3.0)

@rpc("call_local", "unreliable")
func rpc_spawn_axe_projectile(spawn_pos: Vector3, dir: Vector3) -> void:
	# Procedural spinning axe mesh projectile
	var proj: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.1, 0.6, 0.3)
	proj.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.2, 0.1, 1.0)
	proj.material_override = mat
	get_parent().add_child(proj)
	proj.global_position = spawn_pos
	
	var tween: Tween = create_tween()
	var target_pos: Vector3 = spawn_pos + dir * 14.0
	tween.tween_property(proj, "global_position", target_pos, 0.6)
	tween.parallel().tween_property(proj, "rotation:z", deg_to_rad(1080.0), 0.6)
	tween.tween_callback(proj.queue_free)

func play_death_animation() -> void:
	# Use knockdown animation for death — skeleton drives the fall
	_play_skeletal_animation("knockdown", 0.1)
	# Ensure time_scale is restored in case we were in hitstop/slowmo when dying
	var ctc: Node = get_node_or_null("/root/CombatTimeController")
	if ctc and ctc.has_method("force_restore_normal_time"):
		ctc.force_restore_normal_time()

func _on_remote_state_changed(_prev: String, current: String) -> void:
	match current:
		"LightAttackState": play_attack_animation()
		"HeavyAttackState": play_heavy_attack_animation()
		"ChargedAttackState": play_charge_buildup_animation()
		"ParryState": play_parry_success_animation()
		"DodgeState": play_dodge_animation()
		"StaggeredState": play_stagger_animation()
		"StunnedState": play_stun_animation()
		"KnockedDownState": play_knockdown_animation()
		"FinisherState": play_finisher_animation()
		"AbilityState": play_ability_cast_animation()
		"DeadState": play_death_animation()

@rpc("call_local", "unreliable")
func rpc_flash_hit() -> void:
	ImpactVFX.spawn_hit_sparks(self, global_position + Vector3(0, 1.1, 0), false)
	if combat_audio: combat_audio.play_weapon_impact(false)
	# Use directional hit reaction from skeletal animation
	_play_skeletal_animation("hit_react_front", 0.05)

	# Camera response for local player
	if is_local_player and camera_rig:
		camera_rig.apply_trauma(0.15)

@rpc("call_local", "unreliable")
func rpc_flash_shield() -> void:
	if combat_audio: combat_audio.play_block()
	if shield_mesh and shield_mesh.get_child_count() > 0:
		var s_mesh: Node = shield_mesh.get_child(0)
		if s_mesh is MeshInstance3D and s_mesh.material_override:
			var mat: StandardMaterial3D = s_mesh.material_override as StandardMaterial3D
			if mat:
				var orig_color: Color = mat.albedo_color
				mat.albedo_color = Color(0.3, 0.7, 1.0, 1.0)
				await get_tree().create_timer(0.08).timeout
				if mat:
					mat.albedo_color = orig_color

@rpc("call_local", "unreliable")
func rpc_flash_parry() -> void:
	ImpactVFX.spawn_parry_flash(self, global_position + Vector3(0, 1.2, 0.3))
	if combat_audio: combat_audio.play_parry()
	_play_skeletal_animation("parry")
	if is_local_player and camera_rig and camera_rig.has_node("SpringArm3D/Camera3D"):
		var cam: Camera3D = camera_rig.get_node("SpringArm3D/Camera3D")
		if cam.has_method("trigger_parry_jolt"):
			cam.trigger_parry_jolt()
	if character_mesh and character_mesh.material_override:
		var mat: StandardMaterial3D = character_mesh.material_override as StandardMaterial3D
		if mat:
			var orig_color: Color = mat.albedo_color
			mat.albedo_color = Color(1.0, 0.9, 0.2, 1.0)
			await get_tree().create_timer(0.15).timeout
			if mat:
				mat.albedo_color = orig_color

@rpc("call_local", "unreliable")
func rpc_spawn_damage_number(spawn_pos: Vector3, dmg_amount: float, is_heavy: bool, is_parry_ctr: bool, is_fin: bool) -> void:
	var color: Color = Color(1.0, 0.95, 0.8)
	if is_fin:
		color = Color(1.0, 0.15, 0.15)
	elif is_parry_ctr:
		color = Color(0.2, 0.85, 1.0)
	elif is_heavy:
		color = Color(1.0, 0.55, 0.1)
	DamageNumber.spawn(self, spawn_pos, "%.0f" % dmg_amount, color, is_heavy or is_fin)

@rpc("call_local", "unreliable")
func rpc_spawn_combat_text(spawn_pos: Vector3, txt: String, color: Color) -> void:
	DamageNumber.spawn(self, spawn_pos, txt, color, true)


