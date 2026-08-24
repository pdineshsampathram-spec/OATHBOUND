class_name SprintState
extends State

## SprintState — High-speed locomotion that drains stamina per second.

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character._play_skeletal_animation("sprint", 0.12)
		if character.stamina_component:
			character.stamina_component.can_regenerate = false

func exit() -> void:
	if character and character.stamina_component:
		character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	if character.wants_attack():
		if character.has_stamina_for_attack():
			transition_to("LightAttackState")
			return

	if character.wants_dodge():
		if character.has_stamina_for_dodge():
			transition_to("DodgeState")
			return

	if character.wants_block():
		transition_to("BlockState")
		return

	var move_input: Vector2 = character.get_movement_input()
	if move_input.length_squared() < 0.01:
		transition_to("IdleState")
		return

	if not character.is_sprinting_held() or not character.has_stamina_for_sprint():
		transition_to("MovementState")
		return

	# Drain stamina over time
	var has_stamina: bool = character.stamina_component.drain(character.character_data.sprint_stamina_drain, delta)
	if not has_stamina:
		transition_to("MovementState")
		return

	# Apply sprint movement
	var move_dir: Vector3 = character.get_camera_relative_direction(move_input)
	character.apply_gravity(delta)
	character.apply_movement(move_dir, character.character_data.sprint_speed, delta)
	character.rotate_towards_direction(move_dir, delta)
	character.move_and_slide()
