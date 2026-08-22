class_name ParryState
extends State

## ParryState — Successful deflection state creating an empowered riposte / counterattack opportunity.

var _timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0

	if character:
		character.play_parry_success_animation()
		character.is_parry_empowered = true
		if character.stamina_component:
			# Free/reduced stamina
			character.stamina_component.can_regenerate = true

func exit() -> void:
	pass

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	_timer += delta

	# Check for counterattack input during riposte window
	if _timer <= character.character_data.parry_counter_window:
		if character.wants_attack():
			transition_to("LightAttackState")
			return
		if character.wants_heavy_attack():
			transition_to("HeavyAttackState")
			return

	character.apply_gravity(delta)
	character.apply_deceleration(delta)
	character.move_and_slide()

	if _timer >= character.character_data.parry_counter_window:
		character.is_parry_empowered = false
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
