class_name KnockedDownState
extends State

## KnockedDownState — Flattened on the ground from charged attacks or seismic impacts.

var _timer: float = 0.0
var _recovering: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0
	_recovering = false
	if character:
		character.is_finisher_vulnerable = true
		character.play_knockdown_animation()
		if character.stamina_component:
			character.stamina_component.can_regenerate = false

func exit() -> void:
	if character:
		character.is_finisher_vulnerable = false
		character.restore_full_poise()
		character.reset_knockdown_visual()
		if character.stamina_component:
			character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	_timer += delta

	var down_dur: float = character.character_data.knockdown_duration
	var rec_dur: float = character.character_data.knockdown_recovery

	if _timer >= down_dur and not _recovering:
		_recovering = true
		character.play_get_up_animation()

	character.apply_gravity(delta)
	character.apply_deceleration(delta, 12.0)
	character.move_and_slide()

	if _timer >= (down_dur + rec_dur):
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
