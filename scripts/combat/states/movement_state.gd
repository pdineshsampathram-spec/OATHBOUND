class_name MovementState
extends State

## MovementState — Standard directional movement (walk/run) with stamina regen enabled.

func enter(_msg: Dictionary = {}) -> void:
	if character and character.stamina_component:
		character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	# Transitions
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
	if move_input.length_squared() < 0.01:
		transition_to("IdleState")
		return

	if character.is_sprinting_held() and character.has_stamina_for_sprint():
		transition_to("SprintState")
		return

	# Apply directional movement
	var move_dir: Vector3 = character.get_camera_relative_direction(move_input)
	character.apply_gravity(delta)
	character.apply_movement(move_dir, character.character_data.move_speed, delta)
	character.rotate_towards_direction(move_dir, delta)
	character.move_and_slide()
