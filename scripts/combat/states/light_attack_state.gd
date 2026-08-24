class_name LightAttackState
extends State

## LightAttackState — 3-hit combo chain system with swept blade hit detection, forward momentum, and combo buffering.

var _timer: float = 0.0
var _hitbox_activated: bool = false
var _wants_combo_followup: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0
	_hitbox_activated = false
	_wants_combo_followup = false

	if character:
		# Free stamina if riposting from parry
		if character.is_parry_empowered:
			character.is_parry_empowered = false
		elif character.stamina_component:
			character.stamina_component.consume(character.character_data.attack_stamina_cost)
			character.stamina_component.can_regenerate = false

		# Biomechanical forward step impulse
		var facing_dir: Vector3 = -character.visual_pivot.global_transform.basis.z.normalized()
		var impulse_mult: float = 1.0
		if character.combo_step == 2:
			impulse_mult = 1.25 # Stepping forward cut
		elif character.combo_step == 3:
			impulse_mult = 1.6 # Deep forward lunge
		character.velocity.x = facing_dir.x * character.character_data.attack_forward_impulse * impulse_mult
		character.velocity.z = facing_dir.z * character.character_data.attack_forward_impulse * impulse_mult

		character.current_attack_type = PlayerController.AttackType.LIGHT
		character.play_attack_animation()

func exit() -> void:
	if character:
		character.set_sword_hitbox_active(false)
		if character.stamina_component:
			character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	_timer += delta

	# Check for combo input buffering
	if _timer >= (character.character_data.attack_duration * 0.45):
		if character.wants_attack() and character.has_stamina_for_attack():
			_wants_combo_followup = true

	# Hitbox active window
	var start_t: float = character.character_data.attack_hitbox_start
	var end_t: float = character.character_data.attack_hitbox_end

	if _timer >= start_t and _timer <= end_t:
		if not _hitbox_activated:
			character.set_sword_hitbox_active(true)
			_hitbox_activated = true
	else:
		if _hitbox_activated and _timer > end_t:
			character.set_sword_hitbox_active(false)

	# Movement physics during attack
	character.apply_gravity(delta)
	character.apply_deceleration(delta, 5.0)
	character.move_and_slide()

	# Chained combo transition
	if _wants_combo_followup and _timer >= (character.character_data.attack_duration * 0.80):
		transition_to("LightAttackState")
		return

	# Attack completion
	if _timer >= character.character_data.attack_duration:
		character.combo_step = 1 # Reset combo chain
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
