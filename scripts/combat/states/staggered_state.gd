class_name StaggeredState
extends State

## StaggeredState — Guard broken / poise depleted state. Highly vulnerable to Finishers.

var _timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0
	if character:
		character.is_finisher_vulnerable = true
		character.play_stagger_animation()
		if character.stamina_component:
			character.stamina_component.can_regenerate = false

func exit() -> void:
	if character:
		character.is_finisher_vulnerable = false
		character.restore_full_poise()
		if character.stamina_component:
			character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	_timer += delta

	character.apply_gravity(delta)
	character.apply_deceleration(delta, 10.0)
	character.move_and_slide()

	if _timer >= character.character_data.stagger_duration:
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
