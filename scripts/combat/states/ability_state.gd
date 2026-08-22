class_name AbilityState
extends State

## AbilityState — Server-authoritative execution of character supernatural abilities.
## Supports DASH_STRIKE (Knight), RADIAL_AOE (Berserker), and TELEPORT_STRIKE (Shadow Warrior).

var _timer: float = 0.0
var _cast_duration: float = 0.6
var _hit_dealt: bool = false
var _ability_style: int = 0
var _hit_targets: Array[Node] = []

func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0
	_hit_dealt = false
	_hit_targets.clear()

	if not character or not character.character_data:
		return

	var c_data: CharacterData = character.character_data
	_cast_duration = c_data.ability_cast_time
	_ability_style = c_data.ability_style

	# Consume stamina and trigger cooldown
	if character.stamina_component:
		character.stamina_component.consume(c_data.ability_stamina_cost)
		character.stamina_component.can_regenerate = false

	character.start_ability_cooldown(c_data.ability_cooldown)

	# Execute ability startup
	match _ability_style:
		CharacterData.AbilityStyle.DASH_STRIKE: # Knight - Shield Rush
			var facing_dir: Vector3 = -character.visual_pivot.global_transform.basis.z.normalized()
			character.velocity = facing_dir * (c_data.ability_range / maxf(0.1, _cast_duration * 0.7))
			character.play_dash_strike_animation()

		CharacterData.AbilityStyle.RADIAL_AOE: # Berserker - Ground Breaker
			character.velocity = Vector3.ZERO
			character.play_ground_breaker_animation()

		CharacterData.AbilityStyle.TELEPORT_STRIKE: # Shadow Warrior - Shadow Step
			character.play_shadow_step_animation()
			_perform_shadow_teleport()

func exit() -> void:
	if character:
		character.stop_ability_visuals()
		if character.stamina_component:
			character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character or not character.character_data:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	_timer += delta
	var c_data: CharacterData = character.character_data

	match _ability_style:
		CharacterData.AbilityStyle.DASH_STRIKE:
			# Active hitbox along the dash
			if _timer <= _cast_duration * 0.7:
				_check_dash_collisions()
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 8.0)
			character.move_and_slide()

		CharacterData.AbilityStyle.RADIAL_AOE:
			# Impact at 50% cast time
			if _timer >= (_cast_duration * 0.5) and not _hit_dealt:
				_hit_dealt = true
				_execute_radial_shockwave()
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 16.0)
			character.move_and_slide()

		CharacterData.AbilityStyle.TELEPORT_STRIKE:
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 16.0)
			character.move_and_slide()

	if _timer >= _cast_duration:
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")

func _check_dash_collisions() -> void:
	var arena_root: Node = character.get_parent()
	if not arena_root:
		return

	var c_data: CharacterData = character.character_data
	for target in arena_root.get_children():
		if target == character or _hit_targets.has(target):
			continue
		if target is Node3D:
			var dist: float = character.global_position.distance_to(target.global_position)
			if dist <= c_data.ability_aoe_radius:
				_hit_targets.append(target)
				if target.has_method("take_damage_complex"):
					target.take_damage_complex(c_data.ability_damage, character, PlayerController.AttackType.HEAVY, c_data.ability_poise_damage)
				elif target.has_method("take_damage"):
					target.take_damage(c_data.ability_damage, character)

func _execute_radial_shockwave() -> void:
	character.rpc("rpc_trigger_shockwave_vfx")
	var arena_root: Node = character.get_parent()
	if not arena_root:
		return

	var c_data: CharacterData = character.character_data
	for target in arena_root.get_children():
		if target == character:
			continue
		if target is Node3D:
			var dist: float = character.global_position.distance_to(target.global_position)
			if dist <= c_data.ability_aoe_radius:
				if target.has_method("take_damage_complex"):
					target.take_damage_complex(c_data.ability_damage, character, PlayerController.AttackType.CHARGED_KNOCKDOWN, c_data.ability_poise_damage)
				elif target.has_method("take_damage"):
					target.take_damage(c_data.ability_damage, character)

func _perform_shadow_teleport() -> void:
	var c_data: CharacterData = character.character_data
	var facing_dir: Vector3 = -character.visual_pivot.global_transform.basis.z.normalized()
	var dest: Vector3 = character.global_position + (facing_dir * c_data.ability_range)
	
	# Clamp inside arena boundary (-18 to 18)
	dest.x = clampf(dest.x, -18.0, 18.0)
	dest.z = clampf(dest.z, -18.0, 18.0)
	character.global_position = dest

	# Strike immediate surroundings at arrival point
	var arena_root: Node = character.get_parent()
	if arena_root:
		for target in arena_root.get_children():
			if target == character:
				continue
			if target is Node3D:
				var dist: float = character.global_position.distance_to(target.global_position)
				if dist <= c_data.ability_aoe_radius:
					if target.has_method("take_damage_complex"):
						target.take_damage_complex(c_data.ability_damage, character, PlayerController.AttackType.HEAVY, c_data.ability_poise_damage)
					elif target.has_method("take_damage"):
						target.take_damage(c_data.ability_damage, character)
