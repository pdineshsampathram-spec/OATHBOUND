class_name AbilityState
extends State

## AbilityState — Channeling / casting state for supernatural character abilities (Phase 4 ready).

var _timer: float = 0.0
var _cast_duration: float = 0.8
var _ability_name: String = "VoidStrike"

func enter(msg: Dictionary = {}) -> void:
	_timer = 0.0
	_ability_name = msg.get("ability_name", "VoidStrike")
	_cast_duration = msg.get("duration", 0.8)

	if character:
		character.play_ability_cast_animation()
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
	character.apply_deceleration(delta, 10.0)
	character.move_and_slide()

	if _timer >= _cast_duration:
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
