class_name MovementState
extends State

## MovementState — Standard ground locomotion handling WASD inputs and combat transitions.

func enter(_msg: Dictionary = {}) -> void:
	if character and character.stamina_component:
		character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	# 1. Finisher
	if character.wants_finisher():
		var target: Node = character.find_nearby_finisher_target()
		if target:
			transition_to("FinisherState", {"target": target})
			return

	# 2. Abilities (Slots 0, 1, 2, 3)
	var ability_slot: int = character.get_requested_ability_slot()
	if ability_slot >= 0:
		transition_to("AbilityState", {"slot": ability_slot})
		return

	# 3. Charged Attack
	if character.wants_charged_attack():
		if character.has_stamina_for_charged():
			transition_to("ChargedAttackState")
			return

	# 4. Heavy Attack
	if character.wants_heavy_attack():
		if character.has_stamina_for_heavy():
			transition_to("HeavyAttackState")
			return

	# 5. Light Attack
	if character.wants_attack():
		if character.has_stamina_for_attack():
			transition_to("LightAttackState")
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

	# 8. Sprint transition
	if character.is_sprinting_held() and character.has_stamina_for_sprint():
		transition_to("SprintState")
		return

	# Movement physics
	var move_input: Vector2 = character.get_movement_input()
	if move_input.length_squared() < 0.01:
		transition_to("IdleState")
		return

	var move_dir: Vector3 = character.get_camera_relative_direction(move_input)
	character.apply_gravity(delta)
	character.apply_movement(move_dir, character.character_data.move_speed, delta)
	character.rotate_towards_direction(move_dir, delta)
	character.move_and_slide()
