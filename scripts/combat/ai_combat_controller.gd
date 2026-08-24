class_name AICombatController
extends Node

## AICombatController — Intelligent AI input driver for combat.
## Replaces network/human input on a PlayerController with decision-making logic.
## Uses the full combat state machine for natural, believable enemy behavior.

## Behavior states — NOT the same as combat states. These drive decision-making.
enum AIState {
	ASSESS,        # Evaluate distance, health, stamina before committing
	APPROACH,      # Close distance to attack range
	ATTACK,        # Execute offensive action
	BLOCK,         # Defensive guard
	DODGE,         # Evasive maneuver
	RETREAT,       # Back away to recover
	PUNISH,        # Capitalize on opponent vulnerability
	RECOVER,       # Wait for stamina/resources to regenerate
	REPOSITION,    # Circle strafe for better angle
	STAGGER_REACT, # Recovering from being staggered
}

@export var aggression: float = 0.5       # 0.0 = passive, 1.0 = relentless
@export var reaction_speed: float = 0.6   # 0.0 = slow, 1.0 = frame-perfect
@export var skill_level: float = 0.5      # 0.0 = telegraphs everything, 1.0 = optimal play
@export var preferred_range: float = 2.2  # Ideal combat distance

var character: PlayerController = null
var target: PlayerController = null
var ai_state: AIState = AIState.ASSESS
var _decision_timer: float = 0.0
var _state_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _block_timer: float = 0.0
var _retreat_timer: float = 0.0
var _strafe_direction: float = 1.0  # +1 right, -1 left
var _coordination_manager: Node = null  # Reference to WaveManager for coordination
var is_active: bool = true

# Simulated input state — what the AI "presses"
var _ai_move_input: Vector2 = Vector2.ZERO
var _ai_wants_attack: bool = false
var _ai_wants_heavy: bool = false
var _ai_wants_block: bool = false
var _ai_wants_dodge: bool = false
var _ai_wants_sprint: bool = false
var _ai_wants_finisher: bool = false

func set_active(active: bool) -> void:
	is_active = active
	if not is_active:
		_clear_inputs()

func _ready() -> void:
	_strafe_direction = [-1.0, 1.0].pick_random()
	_decision_timer = randf_range(0.2, 0.8)  # Stagger initial decisions

func setup(p_character: PlayerController, p_target: PlayerController, coord_mgr: Node = null) -> void:
	character = p_character
	target = p_target
	_coordination_manager = coord_mgr
	
	# Assign AI controller to character
	character.ai_controller = self

func _physics_process(delta: float) -> void:
	if not is_active:
		_clear_inputs()
		return
	if not character or not is_instance_valid(character) or character.is_dead:
		return
	if not target or not is_instance_valid(target) or target.is_dead:
		_find_new_target()
		if not target:
			_clear_inputs()
			return
	
	_decision_timer -= delta
	_state_timer += delta
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	
	# Clear inputs each frame — AI must explicitly set them
	_clear_inputs()
	
	# Run AI logic at decision rate (not every frame)
	if _decision_timer <= 0.0:
		_make_decision()
		_decision_timer = _get_decision_interval()
	
	# Execute current behavior
	_execute_behavior(delta)

## --- Decision Making ---

func _make_decision() -> void:
	var dist: float = _get_distance_to_target()
	var my_hp_ratio: float = _get_health_ratio()
	var my_stam_ratio: float = _get_stamina_ratio()
	var target_hp_ratio: float = _get_target_health_ratio()
	var target_vulnerable: bool = _is_target_vulnerable()
	var should_coordinate: bool = _should_wait_for_ally()
	
	# Priority 1: React to being staggered/stunned (involuntary)
	if character.is_finisher_vulnerable:
		ai_state = AIState.STAGGER_REACT
		return
	
	# Priority 2: Punish vulnerable targets
	if target_vulnerable and dist < preferred_range * 1.3:
		if _attack_cooldown <= 0.0:
			ai_state = AIState.PUNISH
			return
	
	# Priority 3: Retreat when low resources
	if my_hp_ratio < 0.2 or (my_stam_ratio < 0.15 and my_hp_ratio < 0.5):
		ai_state = AIState.RETREAT
		_retreat_timer = randf_range(1.5, 3.0)
		return
	
	# Priority 4: Recover stamina when low
	if my_stam_ratio < 0.25:
		ai_state = AIState.RECOVER
		return
	
	# Priority 5: Coordination — don't all attack at once
	if should_coordinate:
		ai_state = AIState.REPOSITION
		return
	
	# Priority 6: Approach if too far
	if dist > preferred_range * 1.5:
		ai_state = AIState.APPROACH
		return
	
	# Priority 7: In range — choose action based on aggression/skill
	var action_roll: float = randf()
	var adjusted_aggression: float = aggression
	
	# Be more aggressive if target is low health
	if target_hp_ratio < 0.3:
		adjusted_aggression = minf(adjusted_aggression + 0.3, 1.0)
	
	# Be less aggressive if we're low
	if my_hp_ratio < 0.4:
		adjusted_aggression = maxf(adjusted_aggression - 0.2, 0.1)
	
	if action_roll < adjusted_aggression * 0.6:
		ai_state = AIState.ATTACK
	elif action_roll < adjusted_aggression * 0.6 + 0.2:
		ai_state = AIState.BLOCK
		_block_timer = randf_range(0.3, 1.0)
	elif action_roll < adjusted_aggression * 0.6 + 0.35:
		ai_state = AIState.REPOSITION
	else:
		ai_state = AIState.ASSESS

## --- Behavior Execution ---

func _execute_behavior(delta: float) -> void:
	match ai_state:
		AIState.ASSESS:
			_execute_assess(delta)
		AIState.APPROACH:
			_execute_approach(delta)
		AIState.ATTACK:
			_execute_attack(delta)
		AIState.BLOCK:
			_execute_block(delta)
		AIState.DODGE:
			_execute_dodge(delta)
		AIState.RETREAT:
			_execute_retreat(delta)
		AIState.PUNISH:
			_execute_punish(delta)
		AIState.RECOVER:
			_execute_recover(delta)
		AIState.REPOSITION:
			_execute_reposition(delta)
		AIState.STAGGER_REACT:
			_execute_stagger_react(delta)

func _execute_assess(_delta: float) -> void:
	# Stay still, face target
	_ai_move_input = Vector2.ZERO
	_face_target()

func _execute_approach(_delta: float) -> void:
	var dir: Vector2 = _get_direction_to_target()
	var dist: float = _get_distance_to_target()
	
	if dist > preferred_range * 2.0:
		_ai_wants_sprint = true
	
	_ai_move_input = dir * 0.9
	_face_target()
	
	if dist <= preferred_range:
		ai_state = AIState.ASSESS

func _execute_attack(_delta: float) -> void:
	if _attack_cooldown > 0.0:
		ai_state = AIState.REPOSITION
		return
	
	var dist: float = _get_distance_to_target()
	
	# Close distance if not in range
	if dist > preferred_range * 1.2:
		_ai_move_input = _get_direction_to_target() * 0.7
		_face_target()
		return
	
	_face_target()
	
	# Choose attack type based on skill
	var attack_roll: float = randf()
	if attack_roll < 0.6:
		_ai_wants_attack = true
	elif attack_roll < 0.85:
		_ai_wants_heavy = true
	else:
		# Finisher if target is vulnerable
		if target and target.is_finisher_vulnerable:
			_ai_wants_finisher = true
		else:
			_ai_wants_attack = true
	
	_attack_cooldown = randf_range(0.4, 1.2) / maxf(aggression, 0.1)
	
	# After attacking, decide next action
	if randf() < 0.4:
		ai_state = AIState.REPOSITION
	else:
		ai_state = AIState.ASSESS

func _execute_block(delta: float) -> void:
	_ai_wants_block = true
	_block_timer -= delta
	_face_target()
	
	# Attempt parry reaction based on skill
	if _block_timer <= 0.0:
		ai_state = AIState.ASSESS
	
	# Dodge out of sustained block sometimes
	if randf() < 0.02 * skill_level:
		_ai_wants_block = false
		_ai_wants_dodge = true
		ai_state = AIState.REPOSITION

func _execute_dodge(_delta: float) -> void:
	_ai_wants_dodge = true
	# Move away from target
	_ai_move_input = -_get_direction_to_target()
	ai_state = AIState.RECOVER

func _execute_retreat(delta: float) -> void:
	_ai_move_input = -_get_direction_to_target() * 0.8
	_face_target()
	_retreat_timer -= delta
	
	if _retreat_timer <= 0.0 or _get_distance_to_target() > preferred_range * 3.0:
		ai_state = AIState.ASSESS

func _execute_punish(_delta: float) -> void:
	var dist: float = _get_distance_to_target()
	_face_target()
	
	if dist > preferred_range:
		_ai_move_input = _get_direction_to_target() * 0.9
		return
	
	# Check finisher opportunity
	if target and target.is_finisher_vulnerable and dist < 2.5:
		_ai_wants_finisher = true
	else:
		# Heavy attack for maximum punishment
		_ai_wants_heavy = true
	
	_attack_cooldown = randf_range(0.3, 0.6)
	ai_state = AIState.ASSESS

func _execute_recover(_delta: float) -> void:
	# Circle-strafe at mid-range while recovering
	var dist: float = _get_distance_to_target()
	_face_target()
	
	if dist < preferred_range * 0.8:
		_ai_move_input = -_get_direction_to_target() * 0.5
	elif dist > preferred_range * 2.0:
		_ai_move_input = _get_direction_to_target() * 0.3
	else:
		_ai_move_input = _get_strafe_input() * 0.4
	
	if _get_stamina_ratio() > 0.5:
		ai_state = AIState.ASSESS

func _execute_reposition(_delta: float) -> void:
	_face_target()
	var dist: float = _get_distance_to_target()
	
	# Circle strafe
	var strafe: Vector2 = _get_strafe_input() * 0.5
	
	# Adjust distance
	if dist > preferred_range * 1.5:
		strafe += _get_direction_to_target() * 0.4
	elif dist < preferred_range * 0.7:
		strafe -= _get_direction_to_target() * 0.3
	
	_ai_move_input = strafe
	
	if _state_timer > randf_range(1.0, 2.5):
		_state_timer = 0.0
		_strafe_direction *= -1.0  # Switch direction
		ai_state = AIState.ASSESS

func _execute_stagger_react(_delta: float) -> void:
	# Can't do much while staggered — try to dodge when recovered
	if not character.is_finisher_vulnerable:
		if randf() < 0.6:
			_ai_wants_dodge = true
			_ai_move_input = -_get_direction_to_target()
		ai_state = AIState.RETREAT
		_retreat_timer = 2.0

## --- Coordination ---

func _should_wait_for_ally() -> bool:
	if not _coordination_manager:
		return false
	if not _coordination_manager.has_method("get_active_enemies"):
		return false
	
	var enemies: Array = _coordination_manager.get_active_enemies()
	if enemies.size() <= 1:
		return false
	
	# Only one enemy should be attacking at a time (with some overlap)
	var attacking_count: int = 0
	for enemy in enemies:
		if enemy == character:
			continue
		var ctrl: Node = enemy.ai_controller
		if ctrl and ctrl is AICombatController:
			if ctrl.ai_state == AIState.ATTACK or ctrl.ai_state == AIState.PUNISH:
				attacking_count += 1
	
	# Allow attack if no one else is attacking, or low chance of joining
	return attacking_count >= 1 and randf() > aggression * 0.3

## --- Helper Functions ---

func _get_distance_to_target() -> float:
	if not target or not character:
		return 999.0
	return character.global_position.distance_to(target.global_position)

func _get_direction_to_target() -> Vector2:
	if not target or not character:
		return Vector2.ZERO
	var dir3d: Vector3 = (target.global_position - character.global_position).normalized()
	return Vector2(dir3d.x, dir3d.z).normalized()

func _get_strafe_input() -> Vector2:
	var dir: Vector2 = _get_direction_to_target()
	# Perpendicular to target direction
	return Vector2(-dir.y, dir.x) * _strafe_direction

func _face_target() -> void:
	if not target or not character or not character.visual_pivot:
		return
	var dir: Vector3 = (target.global_position - character.global_position)
	dir.y = 0
	if dir.length_squared() > 0.01:
		character.visual_pivot.look_at(character.visual_pivot.global_position + dir.normalized(), Vector3.UP)

func _get_health_ratio() -> float:
	if character and character.health_component:
		return character.health_component.current_health / character.health_component.max_health
	return 1.0

func _get_stamina_ratio() -> float:
	if character and character.stamina_component:
		return character.stamina_component.current_stamina / character.stamina_component.max_stamina
	return 1.0

func _get_target_health_ratio() -> float:
	if target and target.health_component:
		return target.health_component.current_health / target.health_component.max_health
	return 1.0

func _is_target_vulnerable() -> bool:
	if not target:
		return false
	return target.is_finisher_vulnerable or (target.health_component and target.health_component.current_health / target.health_component.max_health < 0.25)

func _get_decision_interval() -> float:
	# Faster decisions at higher skill, with some randomness
	var base: float = lerpf(0.6, 0.15, reaction_speed)
	return base + randf_range(-0.05, 0.1)

func _clear_inputs() -> void:
	_ai_move_input = Vector2.ZERO
	_ai_wants_attack = false
	_ai_wants_heavy = false
	_ai_wants_block = false
	_ai_wants_dodge = false
	_ai_wants_sprint = false
	_ai_wants_finisher = false

func _find_new_target() -> void:
	# Find the nearest living player
	var players: Node = get_tree().get_first_node_in_group("players")
	if not players:
		var root_players: Node = get_node_or_null("/root/Main/Players")
		if root_players:
			for child in root_players.get_children():
				if child is PlayerController and not child.is_dead and child != character:
					target = child
					return
	target = null

## --- Public API for PlayerController input queries ---

func get_move_input() -> Vector2:
	return _ai_move_input

func wants_attack() -> bool:
	return _ai_wants_attack

func wants_heavy_attack() -> bool:
	return _ai_wants_heavy

func wants_block() -> bool:
	return _ai_wants_block

func wants_dodge() -> bool:
	return _ai_wants_dodge

func is_sprinting_held() -> bool:
	return _ai_wants_sprint

func wants_finisher() -> bool:
	return _ai_wants_finisher
