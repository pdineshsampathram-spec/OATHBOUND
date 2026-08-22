class_name IdleState
extends State

## IdleState — Grounded, stationary state where stamina freely regenerates.

func enter(_msg: Dictionary = {}) -> void:
	if character and character.stamina_component:
		character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	# Apply gravity & ground deceleration
	character.apply_gravity(delta)
	character.apply_deceleration(delta)
	character.move_and_slide()

	# Check state transitions
	if character.is_dead:
		transition_to("DeadState")
		return

	if character.wants_attack():
		if character.has_stamina_for_attack():
			transition_to("LightAttackState")
			return

	if character.wants_block():
		transition_to("BlockState")
		return

	if character.wants_dodge():
		if character.has_stamina_for_dodge():
			transition_to("DodgeState")
			return

	var move_input: Vector2 = character.get_movement_input()
	if move_input.length_squared() > 0.01:
		if character.is_sprinting_held() and character.has_stamina_for_sprint():
			transition_to("SprintState")
		else:
			transition_to("MovementState")
