class_name DodgeState
extends State

## DodgeState — Evasive roll with high initial speed and an invulnerability window (i-frames).

var _timer: float = 0.0
var _dodge_direction: Vector3 = Vector3.ZERO

func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0

	if not character:
		return

	if character.stamina_component:
		character.stamina_component.consume(character.character_data.dodge_stamina_cost)
		character.stamina_component.can_regenerate = false

	# Determine dodge direction based on movement input or facing direction
	var move_input: Vector2 = character.get_movement_input()
	if move_input.length_squared() > 0.01:
		_dodge_direction = character.get_camera_relative_direction(move_input).normalized()
	else:
		# Default to backward dodge or facing direction
		_dodge_direction = -character.visual_pivot.global_transform.basis.z.normalized()

	# Snap facing to dodge direction
	character.visual_pivot.look_at(character.visual_pivot.global_position + _dodge_direction, Vector3.UP)

	# Set initial high-speed impulse
	character.velocity.x = _dodge_direction.x * character.character_data.dodge_speed
	character.velocity.z = _dodge_direction.z * character.character_data.dodge_speed

	character.play_dodge_animation()

func exit() -> void:
	if character:
		if character.health_component:
			character.health_component.is_invulnerable = false
		if character.stamina_component:
			character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	_timer += delta

	# Manage invulnerability frames (i-frames)
	var iframe_start: float = character.character_data.dodge_iframe_start
	var iframe_end: float = character.character_data.dodge_iframe_end
	if character.health_component:
		character.health_component.is_invulnerable = (_timer >= iframe_start and _timer <= iframe_end)

	# Physics
	character.apply_gravity(delta)
	character.apply_deceleration(delta, 4.0) # Gradual roll decay
	character.move_and_slide()

	# Complete dodge
	if _timer >= character.character_data.dodge_duration:
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
