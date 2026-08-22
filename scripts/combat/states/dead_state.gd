class_name DeadState
extends State

## DeadState — Terminal combat state when health reaches 0. Disables control.

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character.velocity = Vector3.ZERO
		character.set_sword_hitbox_active(false)
		if character.stamina_component:
			character.stamina_component.can_regenerate = false
		character.play_death_animation()

func physics_process_state(delta: float) -> void:
	if character:
		character.apply_gravity(delta)
		character.apply_deceleration(delta, 10.0)
		character.move_and_slide()
