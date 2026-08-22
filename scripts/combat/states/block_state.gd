class_name BlockState
extends State

## BlockState — Defensive guard reducing damage. If struck within parry_window, reflects into ParryState.

var block_time: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	block_time = 0.0
	if character:
		character.is_blocking = true
		character.block_active_duration = 0.0
		character.set_guard_visual(true)
		if character.stamina_component:
			character.stamina_component.can_regenerate = false

func exit() -> void:
	if character:
		character.is_blocking = false
		character.set_guard_visual(false)
		if character.stamina_component:
			character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	block_time += delta
	character.block_active_duration = block_time

	if character.wants_dodge() and character.has_stamina_for_dodge():
		transition_to("DodgeState")
		return

	if not character.wants_block():
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
		return

	# Slower guarded movement
	var move_input: Vector2 = character.get_movement_input()
	character.apply_gravity(delta)

	if move_input.length_squared() > 0.01:
		var move_dir: Vector3 = character.get_camera_relative_direction(move_input)
		var guarded_speed: float = character.character_data.move_speed * character.character_data.block_move_speed_multiplier
		character.apply_movement(move_dir, guarded_speed, delta)
		character.rotate_towards_direction(move_dir, delta)
	else:
		character.apply_deceleration(delta)

	character.move_and_slide()
