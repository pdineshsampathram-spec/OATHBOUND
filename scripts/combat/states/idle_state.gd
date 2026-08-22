class_name IdleState
extends State

## IdleState — Grounded, stationary state where stamina and poise freely regenerate.

func enter(_msg: Dictionary = {}) -> void:
	if character and character.stamina_component:
		character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	character.apply_gravity(delta)
	character.apply_deceleration(delta)
	character.move_and_slide()

	if character.is_dead:
		transition_to("DeadState")
		return

	# 1. Finisher priority
	if character.wants_finisher():
		var target: Node = character.find_nearby_finisher_target()
		if target:
			transition_to("FinisherState", {"target": target})
			return

	# 2. Charged Attack
	if character.wants_charged_attack():
		if character.has_stamina_for_charged():
			transition_to("ChargedAttackState")
			return

	# 3. Heavy Attack
	if character.wants_heavy_attack():
		if character.has_stamina_for_heavy():
			transition_to("HeavyAttackState")
			return

	# 4. Light Attack
	if character.wants_attack():
		if character.has_stamina_for_attack():
			transition_to("LightAttackState")
			return

	# 5. Ability
	if character.wants_ability():
		transition_to("AbilityState")
		return

	# 6. Block
	if character.wants_block():
		transition_to("BlockState")
		return

	# 7. Dodge
	if character.wants_dodge():
		if character.has_stamina_for_dodge():
			transition_to("DodgeState")
			return

	# 8. Movement
	var move_input: Vector2 = character.get_movement_input()
	if move_input.length_squared() > 0.01:
		if character.is_sprinting_held() and character.has_stamina_for_sprint():
			transition_to("SprintState")
		else:
			transition_to("MovementState")
