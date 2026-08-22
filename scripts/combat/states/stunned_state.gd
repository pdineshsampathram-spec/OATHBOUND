class_name StunnedState
extends State

## StunnedState — Incapacitated state resulting from being parried or struck by disabling attacks.

var _timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0
	if character:
		character.play_stun_animation()
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

	_timer += delta

	character.apply_gravity(delta)
	character.apply_deceleration(delta)
	character.move_and_slide()

	if _timer >= character.character_data.stun_duration:
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
