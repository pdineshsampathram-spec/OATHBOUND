class_name AbilityState
extends State

## AbilityState — Server-authoritative execution of all 12 supernatural ability behaviors.
## Handles cast timing, hitbox sweeps, projectile firing, pulse chains, teleports, and buffs.

var _slot: int = 0
var _ability: AbilityData = null
var _timer: float = 0.0
var _cast_duration: float = 0.5
var _hit_targets: Array[Node] = []
var _combo_hits_done: int = 0
var _combo_interval_timer: float = 0.0
var _pulse_count_done: int = 0
var _pulse_interval_timer: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	_slot = msg.get("slot", 2)
	_timer = 0.0
	_hit_targets.clear()
	_combo_hits_done = 0
	_combo_interval_timer = 0.0
	_pulse_count_done = 0
	_pulse_interval_timer = 0.0

	if not character or not character.ability_system:
		transition_to("IdleState")
		return

	_ability = character.ability_system.get_ability(_slot)
	if not _ability:
		transition_to("IdleState")
		return

	# Server consumes resources & sets cooldown
	character.ability_system.consume_and_trigger_cooldown(_slot)
	_cast_duration = _ability.cast_time

	# Initial Execution / Animation Trigger
	match _ability.execution_type:
		AbilityData.ExecutionType.BUFF_SELF:
			character.ability_system.apply_buff(_get_buff_name_for_ability(_ability.ability_name), _ability.duration)
			character.rpc("rpc_trigger_buff_vfx", _ability.vfx_color)
			character.play_ability_cast_animation()

		AbilityData.ExecutionType.DASH_STRIKE:
			var facing_dir: Vector3 = -character.visual_pivot.global_transform.basis.z.normalized()
			character.velocity = facing_dir * (_ability.range_distance / maxf(0.1, _cast_duration * 0.7))
			character.play_dash_strike_animation()

		AbilityData.ExecutionType.RADIAL_AOE:
			character.velocity = Vector3.ZERO
			character.play_ground_breaker_animation()

		AbilityData.ExecutionType.TELEPORT_STRIKE:
			character.play_shadow_step_animation()
			_perform_teleport(_ability.range_distance)
			_deal_aoe_damage(_ability.damage, _ability.poise_damage, _ability.aoe_radius, PlayerController.AttackType.HEAVY)

		AbilityData.ExecutionType.PROJECTILE:
			character.play_attack_animation()
			_fire_axe_projectile()

		AbilityData.ExecutionType.DIRECT_STRIKE:
			character.play_heavy_attack_animation()

		AbilityData.ExecutionType.MULTI_HIT_COMBO:
			character.play_attack_animation()

		AbilityData.ExecutionType.RADIAL_PULSE_CHAIN:
			character.play_ground_breaker_animation()

		AbilityData.ExecutionType.MULTI_TARGET_TELEPORT:
			character.play_shadow_step_animation()

func exit() -> void:
	if character:
		character.stop_ability_visuals()

func physics_process_state(delta: float) -> void:
	if not character or not _ability:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	_timer += delta

	match _ability.execution_type:
		AbilityData.ExecutionType.DASH_STRIKE:
			if _timer <= _cast_duration * 0.7:
				_check_dash_collisions()
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 8.0)
			character.move_and_slide()

		AbilityData.ExecutionType.DIRECT_STRIKE:
			if _timer >= (_cast_duration * 0.5) and _hit_targets.is_empty():
				var atk_type: PlayerController.AttackType = PlayerController.AttackType.CHARGED_KNOCKDOWN if _ability.category == AbilityData.Category.ULTIMATE else PlayerController.AttackType.HEAVY
				_deal_forward_cone_damage(_ability.damage, _ability.poise_damage, _ability.range_distance, atk_type)
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 12.0)
			character.move_and_slide()

		AbilityData.ExecutionType.RADIAL_AOE:
			if _timer >= (_cast_duration * 0.5) and _hit_targets.is_empty():
				_hit_targets.append(character)
				character.rpc("rpc_trigger_shockwave_vfx")
				_deal_aoe_damage(_ability.damage, _ability.poise_damage, _ability.aoe_radius, PlayerController.AttackType.CHARGED_KNOCKDOWN)
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 16.0)
			character.move_and_slide()

		AbilityData.ExecutionType.MULTI_HIT_COMBO: # Blade Storm
			_combo_interval_timer += delta
			if _combo_interval_timer >= 0.12 and _combo_hits_done < _ability.hit_count:
				_combo_interval_timer = 0.0
				_combo_hits_done += 1
				character.play_attack_animation()
				_deal_aoe_damage(_ability.damage, _ability.poise_damage, _ability.aoe_radius, PlayerController.AttackType.LIGHT)
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 6.0)
			character.move_and_slide()

		AbilityData.ExecutionType.RADIAL_PULSE_CHAIN: # Wrath
			_pulse_interval_timer += delta
			if _pulse_interval_timer >= 0.4 and _pulse_count_done < _ability.hit_count:
				_pulse_interval_timer = 0.0
				_pulse_count_done += 1
				character.rpc("rpc_trigger_shockwave_vfx")
				_deal_aoe_damage(_ability.damage, _ability.poise_damage, _ability.aoe_radius, PlayerController.AttackType.CHARGED_KNOCKDOWN)
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 16.0)
			character.move_and_slide()

		AbilityData.ExecutionType.MULTI_TARGET_TELEPORT: # Death From Shadow
			_combo_interval_timer += delta
			if _combo_interval_timer >= 0.25 and _combo_hits_done < _ability.hit_count:
				_combo_interval_timer = 0.0
				_combo_hits_done += 1
				_teleport_to_random_nearby_enemy_or_step()
				character.play_attack_animation()
				_deal_aoe_damage(_ability.damage, _ability.poise_damage, _ability.aoe_radius, PlayerController.AttackType.HEAVY)
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 16.0)
			character.move_and_slide()

		_:
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 12.0)
			character.move_and_slide()

	if _timer >= _cast_duration:
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")

# --- Damage & Collision Helpers ---

func _check_dash_collisions() -> void:
	var arena_root: Node = character.get_parent()
	if not arena_root:
		return

	for target in arena_root.get_children():
		if target == character or _hit_targets.has(target):
			continue
		if target is Node3D:
			var dist: float = character.global_position.distance_to(target.global_position)
			if dist <= _ability.aoe_radius:
				_hit_targets.append(target)
				_apply_hit(target, _ability.damage, _ability.poise_damage, PlayerController.AttackType.HEAVY)

func _deal_aoe_damage(dmg: float, poise_dmg: float, radius: float, atk_type: PlayerController.AttackType) -> void:
	var arena_root: Node = character.get_parent()
	if not arena_root:
		return

	for target in arena_root.get_children():
		if target == character:
			continue
		if target is Node3D:
			var dist: float = character.global_position.distance_to(target.global_position)
			if dist <= radius:
				_apply_hit(target, dmg, poise_dmg, atk_type)

func _deal_forward_cone_damage(dmg: float, poise_dmg: float, max_dist: float, atk_type: PlayerController.AttackType) -> void:
	var arena_root: Node = character.get_parent()
	if not arena_root:
		return

	var facing_dir: Vector3 = -character.visual_pivot.global_transform.basis.z.normalized()

	for target in arena_root.get_children():
		if target == character or _hit_targets.has(target):
			continue
		if target is Node3D:
			var to_target: Vector3 = target.global_position - character.global_position
			var dist: float = to_target.length()
			if dist <= max_dist:
				to_target = to_target.normalized()
				var dot: float = facing_dir.dot(to_target)
				if dot > 0.3: # ~70 degree cone in front
					_hit_targets.append(target)
					_apply_hit(target, dmg, poise_dmg, atk_type)

func _apply_hit(target: Node, dmg: float, poise_dmg: float, atk_type: PlayerController.AttackType) -> void:
	var mult: float = character.ability_system.get_outgoing_damage_multiplier() if character.ability_system else 1.0
	var final_dmg: float = dmg * mult
	if target.has_method("take_damage_complex"):
		target.take_damage_complex(final_dmg, character, atk_type, poise_dmg)
	elif target.has_method("take_damage"):
		target.take_damage(final_dmg, character)

func _perform_teleport(distance: float) -> void:
	var facing_dir: Vector3 = -character.visual_pivot.global_transform.basis.z.normalized()
	var dest: Vector3 = character.global_position + (facing_dir * distance)
	dest.x = clampf(dest.x, -18.0, 18.0)
	dest.z = clampf(dest.z, -18.0, 18.0)
	character.global_position = dest

func _teleport_to_random_nearby_enemy_or_step() -> void:
	var arena_root: Node = character.get_parent()
	var potential_targets: Array[Node3D] = []
	if arena_root:
		for child in arena_root.get_children():
			if child != character and child is Node3D:
				var d: float = character.global_position.distance_to(child.global_position)
				if d <= _ability.range_distance:
					potential_targets.append(child)

	if not potential_targets.is_empty():
		var chosen: Node3D = potential_targets.pick_random()
		var offset: Vector3 = Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
		character.global_position = chosen.global_position + offset
		character.global_position.x = clampf(character.global_position.x, -18.0, 18.0)
		character.global_position.z = clampf(character.global_position.z, -18.0, 18.0)
	else:
		_perform_teleport(4.0)

func _fire_axe_projectile() -> void:
	var facing_dir: Vector3 = -character.visual_pivot.global_transform.basis.z.normalized()
	character.rpc("rpc_spawn_axe_projectile", character.global_position + Vector3(0, 1.0, 0), facing_dir)

func _get_buff_name_for_ability(a_name: String) -> String:
	match a_name:
		"Holy Guard": return "HolyGuard"
		"Blood Rage": return "BloodRage"
		"Smoke Veil": return "SmokeVeil"
		_: return "GenericBuff"
